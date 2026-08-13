import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/models/message.dart';
import 'package:trulura/models/sync_candidate/sync_candidate.dart';
import 'package:trulura/services/chat_service.dart';
import 'package:trulura/services/communication_safety_service.dart';
import 'package:trulura/services/reporting_service.dart';
import 'package:trulura/services/aura_shield_service.dart';
import 'package:trulura/services/chat_thread_prefs_service.dart';
import 'package:trulura/services/safety_meter_service.dart';
import 'package:trulura/services/safety_center_service.dart';
import 'package:trulura/services/safety_monitoring_service.dart';
import 'package:trulura/services/sync_service/sync_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_halo_avatar.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';
import 'package:trulura/widgets/trulura_message_bubble.dart';
import 'package:trulura/widgets/trulura_safety_meter_pill.dart';

class ChatThreadScreen extends StatefulWidget {
  final String chatId;

  const ChatThreadScreen({super.key, required this.chatId});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final ChatService _chatService = ChatService();
  final SyncService _syncService = SyncService();
  final SafetyMonitoringService _safety = SafetyMonitoringService();
  final CommunicationSafetyService _commsSafety = CommunicationSafetyService();
  final SafetyCenterService _safetyCenter = SafetyCenterService();
  final AuraShieldService _auraShield = AuraShieldService();
  final ChatThreadPrefsService _threadPrefs = ChatThreadPrefsService();
  final SafetyMeterService _meter = const SafetyMeterService();
  final ReportingService _reporting = ReportingService();
  final _messageController = TextEditingController();
  List<Message> _messages = [];
  String? _currentUserId;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSending = false;
  String? _chatStatus;
  String? _otherUserId;

  TruActiveMatch? _syncMatch;
  TruMatchroom? _matchroom;
  SafetyAssessment _safetyAssessment = const SafetyAssessment(level: SafetyRiskLevel.none, reasons: []);
  AuraShieldAssessment _auraAssessment = const AuraShieldAssessment(level: AuraShieldLevel.low, score: 0, tags: []);
  TruChatThreadPrefs _prefs = const TruChatThreadPrefs();

  String _activeReaction = 'glow';

  final List<_PendingMessage> _pending = <_PendingMessage>[];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final user = await UserService().getCurrentUser();
      final uid = user?.id;
      final messages = await _chatService.getMessagesByChatId(widget.chatId);
      final chat = uid == null ? null : await _chatService.getChatById(widget.chatId, currentUserId: uid);
      final otherId = (uid == null || chat == null)
          ? null
          : chat.participantIds.where((id) => id != uid).toList().cast<String?>().first;

      TruActiveMatch? match;
      TruMatchroom? matchroom;
      if (uid != null) {
        match = await _syncService.findMatchByChatId(userId: uid, chatId: widget.chatId);
        if (match != null) {
          matchroom = await _syncService.ensureMatchroomUnlocked(userId: uid, match: match, messageCount: messages.length);
          if (matchroom != null && match.matchroomId != matchroom.id) {
            await _syncService.setMatchStage(userId: uid, matchId: match.id, stage: TruConnectionStage.matchroom, matchroomId: matchroom.id);
            match = (await _syncService.findMatchByChatId(userId: uid, chatId: widget.chatId)) ?? match;
          }
        }
      }

      final assessment = _safety.assess(messages: messages);
      final prefs = await _threadPrefs.getPrefs(widget.chatId);
      final safetyPrefs = await _safetyCenter.getPrefs();
      final aura = (safetyPrefs.auraShieldEnabled && uid != null)
          ? _auraShield.assessThread(viewerUserId: uid, messages: messages)
          : const AuraShieldAssessment(level: AuraShieldLevel.low, score: 0, tags: []);

      setState(() {
        _currentUserId = uid;
        _messages = messages;
        _chatStatus = chat?.status;
        _otherUserId = otherId;
        _syncMatch = match;
        _matchroom = matchroom;
        _safetyAssessment = assessment;
        _auraAssessment = aura;
        _prefs = prefs;
        _hasError = false;
        _isLoading = false;
      });
    } catch (e) {
      truLogStateError('ChatThread._loadMessages', e);
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null || _isSending) return;

    // If chat is paused (manual or moderation), block sending.
    if (((_chatStatus ?? '').toLowerCase() == 'paused')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This chat is paused.')));
      return;
    }

    // Lightweight communication protections.
    final prefs = await _safetyCenter.getPrefs();
    if (prefs.messageFilteringEnabled) {
      final check = _commsSafety.checkOutgoing(chatId: widget.chatId, text: text);

      // AuraShield (local): store soft signals for filtering + eligibility.
      if (_otherUserId != null) {
        await _auraShield.recordMessageCheck(targetUserId: _otherUserId!, check: check);
      }

      // Crisis support: show optional resources without blocking the message.
      if (prefs.crisisSupportEnabled && check.flags.contains(TruMessageFlag.crisis)) {
        await _maybeShowCrisisSupport();
      }

      // Anti-doxxing: if disabled, ignore the doxxing flag.
      final effectiveFlags = prefs.antiDoxxingEnabled
          ? check.flags
          : check.flags.where((f) => f != TruMessageFlag.possibleDoxxing).toList(growable: false);
      final effective = !check.allowed
          ? check
          : (effectiveFlags.isEmpty ? const CommunicationCheckResult.ok() : CommunicationCheckResult.needsConfirm(effectiveFlags));

      if (!effective.allowed) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(effective.blockReason ?? 'Message blocked.')));
        return;
      }
      if (effective.needsUserConfirm) {
        final ok = await _confirmSend(effective.prompt);
        if (ok != true) return;
      }
    }

    final tempId = 'p_${DateTime.now().microsecondsSinceEpoch}';
    final pending = _PendingMessage(tempId: tempId, content: text);

    setState(() {
      _pending.add(pending);
      _isSending = true;
      _messageController.clear();
    });

    try {
      // Local enforcement: if the other user is blocked, prevent send.
      // We infer the other user from Sync match when available.
      final match = _syncMatch;
      final otherId = match == null
          ? _otherUserId
          : (match.viewerUserId == _currentUserId ? match.targetUserId : match.viewerUserId);
      if (otherId != null && await _reporting.isBlocked(otherId)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You blocked this user. Unblock to message.')));
        setState(() => _pending.removeWhere((p) => p.tempId == tempId));
        return;
      }

      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: widget.chatId,
        senderId: _currentUserId!,
        content: text,
        timestamp: DateTime.now(),
        expiresAt: _prefs.ephemeralTtl.duration == null ? null : DateTime.now().add(_prefs.ephemeralTtl.duration!),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _chatService.saveMessage(message);
      if (!mounted) return;
      setState(() => _pending.removeWhere((p) => p.tempId == tempId));
      await _loadMessages();
    } catch (e) {
      truLogStateError('ChatThread._sendMessage', e);
      if (!mounted) return;
      setState(() {
        final i = _pending.indexWhere((p) => p.tempId == tempId);
        if (i >= 0) _pending[i] = _pending[i].copyWith(state: _PendingState.failed);
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<bool?> _confirmSend(String prompt) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outline.withValues(alpha: 0.16), width: TruLuraSurfaces.hairline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety check', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(prompt, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(onPressed: () => context.pop(true), child: const Text('Send')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _retryPending(String tempId) async {
    final idx = _pending.indexWhere((p) => p.tempId == tempId);
    if (idx < 0 || _currentUserId == null) return;
    final p = _pending[idx];
    setState(() {
      _pending[idx] = p.copyWith(state: _PendingState.sending);
      _isSending = true;
    });
    try {
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: widget.chatId,
        senderId: _currentUserId!,
        content: p.content,
        timestamp: DateTime.now(),
        expiresAt: _prefs.ephemeralTtl.duration == null ? null : DateTime.now().add(_prefs.ephemeralTtl.duration!),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _chatService.saveMessage(message);
      if (!mounted) return;
      setState(() => _pending.removeWhere((x) => x.tempId == tempId));
      await _loadMessages();
    } catch (e) {
      truLogStateError('ChatThread._retryPending', e);
      if (!mounted) return;
      setState(() {
        final i = _pending.indexWhere((x) => x.tempId == tempId);
        if (i >= 0) _pending[i] = _pending[i].copyWith(state: _PendingState.failed);
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paused = (_chatStatus ?? '').toLowerCase() == 'paused';
    final assessment = _safetyAssessment;
    final aura = _auraAssessment;
    final meter = _meter.meterForThread(aura);
    final match = _syncMatch;
    final room = _matchroom;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TruLuraGlassAppBar(
        mode: TruLuraMode.aura,
        showBack: true,
        titleWidget: Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/p?title=${Uri.encodeComponent('Profile')}&subtitle=${Uri.encodeComponent('Open profile from chat (stub)')}'),
              child: const TruLuraHaloAvatar(radius: 16, image: null, fallback: TruLuraIcon(glyph: TruLuraGlyph.person, size: 16)),
            ),
            const SizedBox(width: 12),
            Text('Glow Messages', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          if (room != null && match != null)
            IconButton(
              onPressed: () => context.push('/matchroom/${match.id}'),
              icon: const TruLuraIcon(glyph: TruLuraGlyph.groups, size: 22),
              tooltip: 'Matchroom',
            ),
          IconButton(
            onPressed: _openThreadActions,
            icon: const TruLuraIcon(glyph: TruLuraGlyph.more, size: 22),
            tooltip: 'Actions',
          ),
        ],
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const _ChatThreadSkeleton()
                  : _hasError
                      ? TruStatePanel(
                          glyph: TruLuraGlyph.info,
                          title: 'This thread couldn’t load',
                          message: 'Try again in a moment.',
                          actions: [TruStateAction(label: 'Retry', glyph: TruLuraGlyph.spark, onTap: _loadMessages, primary: true)],
                        )
                      : (_messages.isEmpty && _pending.isEmpty)
                          ? _EmptyThread(onPrompt: (t) {
                              _messageController.text = t;
                              setState(() {});
                            })
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                              children: [
                                if (aura.level != AuraShieldLevel.low) ...[
                                  Row(
                                    children: [
                                      TruLuraSafetyMeterPill(meter: meter, onTap: () => _openAuraShieldDetails(aura)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'AuraShield is noticing a pattern — slow the pace and keep boundaries clear.',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (assessment.level != SafetyRiskLevel.none) ...[
                                  TruInlineBanner(
                                    glyph: TruLuraGlyph.shield,
                                    text: assessment.level == SafetyRiskLevel.elevated
                                        ? 'Safety check: elevated risk signals detected.'
                                        : 'Safety check: some caution signals detected.',
                                  ),
                                  if (assessment.reasons.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    TruLuraGlassCard(
                                      mode: TruLuraMode.aura,
                                      radius: 18,
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Why this appeared', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                                          const SizedBox(height: 8),
                                          ...assessment.reasons.map((r) => Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: Text('• $r', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.78))),
                                              )),
                                          const SizedBox(height: 6),
                                          Text('Tip: keep meetups public, don’t send money, and use report/block if needed.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                ],
                                if (paused) ...[
                                  const TruInlineBanner(glyph: TruLuraGlyph.moon, text: 'This conversation is paused.'),
                                  const SizedBox(height: 12),
                                ],
                                if (match != null && room == null) ...[
                                  TruInlineBanner(
                                    glyph: TruLuraGlyph.lock,
                                    text: 'Matchroom unlocks after a few messages (guided prompts + shared tools).',
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (match != null && room != null) ...[
                                  TruInlineBanner(
                                    glyph: TruLuraGlyph.groups,
                                    text: 'Matchroom unlocked. Use it for prompts + calmer pacing.',
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                ..._messages.map((m) {
                                  final isMe = m.senderId == _currentUserId;
                                  final meta = (m.expiresAt == null) ? null : 'Ephemeral • deletes ${_relativeTime(m.expiresAt!)}';
                                  return TruluraMessageBubble(content: m.content, isMe: isMe, failed: false, onRetry: null, onLongPress: () => _openBubbleReactions(m.content), meta: meta);
                                }),
                                ..._pending.map((p) {
                                  return TruluraMessageBubble(
                                    content: p.content,
                                    isMe: true,
                                    failed: p.state == _PendingState.failed,
                                    onRetry: p.state == _PendingState.failed ? () => _retryPending(p.tempId) : null,
                                    onLongPress: () => _openBubbleReactions(p.content),
                                    meta: _prefs.ephemeralTtl == TruEphemeralTtl.off ? null : 'Ephemeral • ${_prefs.ephemeralTtl.label}',
                                  );
                                }),
                              ],
                            ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: TruLuraGlassCard(
                mode: TruLuraMode.aura,
                radius: 20,
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: TruLuraIcon(glyph: TruLuraGlyph.postPlus, size: 22, active: true, color: cs.onSurface.withValues(alpha: 0.92)),
                        onPressed: paused ? null : _openAttachments,
                        tooltip: 'Attach',
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Type a message…',
                            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.60)),
                            filled: false,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: TruLuraIcon(glyph: TruLuraGlyph.send, size: 22, active: true, color: cs.onSurface.withValues(alpha: 0.92)),
                        onPressed: (_isSending || paused) ? null : _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openThreadActions() async {
    final cs = Theme.of(context).colorScheme;
    final uid = _currentUserId;
    final match = _syncMatch;
    final otherId = match == null ? _otherUserId : (uid == null ? null : (match.viewerUserId == uid ? match.targetUserId : match.viewerUserId));
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (match != null) ...[
                  _SheetAction(
                    icon: Icons.groups_rounded,
                    label: (_matchroom != null) ? 'Open matchroom' : 'Matchroom (locked)',
                    onTap: () {
                      if (_matchroom == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matchroom is locked until you’ve exchanged a few messages.')));
                        context.pop();
                        return;
                      }
                      context.pop();
                      context.push('/matchroom/${match.id}');
                    },
                  ),
                  const SizedBox(height: 10),
                  _SheetAction(
                    icon: match.status == TruActiveMatchStatus.paused ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                    label: match.status == TruActiveMatchStatus.paused ? 'Resume connection' : 'Pause connection',
                    onTap: () async {
                      if (uid == null) return;
                      final next = match.status == TruActiveMatchStatus.paused ? TruActiveMatchStatus.active : TruActiveMatchStatus.paused;
                      await _syncService.setMatchStatus(userId: uid, matchId: match.id, status: next, pauseNote: next == TruActiveMatchStatus.paused ? 'Paused from chat thread' : null);
                      if (!mounted) return;
                      context.pop();
                      await _loadMessages();
                    },
                  ),
                  const SizedBox(height: 10),
                  _SheetAction(
                    icon: Icons.close_rounded,
                    label: 'End connection (respectful exit)',
                    danger: true,
                    onTap: () async {
                      if (uid == null) return;
                      await _syncService.setMatchStatus(userId: uid, matchId: match.id, status: TruActiveMatchStatus.closed, pauseNote: 'Closed from chat thread');
                      await _syncService.setMatchStage(userId: uid, matchId: match.id, stage: TruConnectionStage.closed);
                      if (!mounted) return;
                      context.pop();
                      await _loadMessages();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection closed.')));
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                _SheetAction(
                  icon: Icons.pause_circle_outline_rounded,
                  label: 'Pause conversation',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paused (stub)')));
                    context.pop();
                  },
                ),
                const SizedBox(height: 10),
                _SheetAction(
                  icon: Icons.timer_outlined,
                  label: 'Ephemeral messages: ${_prefs.ephemeralTtl.label}',
                  onTap: () async {
                    context.pop();
                    await _openEphemeralSettings();
                  },
                ),
                const SizedBox(height: 10),
                _SheetAction(
                  icon: Icons.block_rounded,
                  label: 'Block',
                  danger: true,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    if (otherId == null) {
                      messenger.showSnackBar(const SnackBar(content: Text('Could not resolve user to block.')));
                      navigator.pop();
                      return;
                    }
                    await _reporting.blockUser(otherId);
                    await _auraShield.recordUserSignal(TruAuraShieldUserSignal(targetUserId: otherId, type: TruAuraShieldSignalType.blocked, createdAt: DateTime.now()));
                    if (!mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('User blocked.')));
                    navigator.pop();
                  },
                ),
                const SizedBox(height: 10),
                _SheetAction(
                  icon: Icons.flag_outlined,
                  label: 'Report',
                  danger: true,
                  onTap: () {
                    context.pop();
                    context.push('${AppRoutes.report}?type=chat&id=${Uri.encodeComponent(widget.chatId)}');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAttachments() async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attach', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _PillAction(icon: Icons.photo_outlined, label: 'Photo', onTap: () => _stub('Photo picker')),
                    _PillAction(icon: Icons.photo_camera_outlined, label: 'Camera', onTap: () => _stub('Camera')),
                    _PillAction(icon: Icons.mic_none_rounded, label: 'Voice', onTap: () => _stub('Voice note')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openBubbleReactions(String message) async {
    final messenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('React', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ReactionPill(label: 'Glow', selected: _activeReaction == 'glow', onTap: () => context.pop('glow')),
                    _ReactionPill(label: 'Heart', selected: _activeReaction == 'heart', onTap: () => context.pop('heart')),
                    _ReactionPill(label: 'Laugh', selected: _activeReaction == 'laugh', onTap: () => context.pop('laugh')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || result == null) return;
    setState(() => _activeReaction = result);
    messenger.showSnackBar(SnackBar(content: Text('Reacted with ${result.toUpperCase()} (stub)')));
  }

  String _relativeTime(DateTime at) {
    final now = DateTime.now();
    final diff = at.difference(now);
    if (diff.isNegative) return 'soon';
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    return 'in ${diff.inDays}d';
  }

  Future<void> _openEphemeralSettings() async {
    final prefs = await _safetyCenter.getPrefs();
    if (!mounted) return;
    if (!prefs.ephemeralMessagingEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enable Ephemeral Messaging in Safety Center first.')));
      return;
    }

    final cs = Theme.of(context).colorScheme;
    final picked = await showModalBottomSheet<TruEphemeralTtl>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ephemeral messages', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('New messages will self-delete after the chosen time. This does not prevent screenshots.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35)),
                const SizedBox(height: 12),
                ...TruEphemeralTtl.values.map((ttl) {
                  final selected = ttl == _prefs.ephemeralTtl;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => context.pop(ttl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: selected ? 0.62 : 0.48),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: cs.outline.withValues(alpha: selected ? 0.22 : 0.14), width: TruLuraSurfaces.hairline),
                        ),
                        child: Row(
                          children: [
                            Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: cs.onSurface.withValues(alpha: 0.88)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(ttl.label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || picked == null) return;
    final next = _prefs.copyWith(ephemeralTtl: picked);
    await _threadPrefs.setPrefs(widget.chatId, next);
    if (!mounted) return;
    setState(() => _prefs = next);
  }

  Future<void> _openAuraShieldDetails(AuraShieldAssessment aura) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String tagText(AuraShieldTag t) {
          switch (t) {
            case AuraShieldTag.coercion:
              return 'Coercion / money pressure signals';
            case AuraShieldTag.boundaryPressure:
              return 'Boundary pressure or invalidation language';
            case AuraShieldTag.loveBombing:
              return 'Fast-intensity “love bombing” patterns';
            case AuraShieldTag.escalation:
              return 'Rapid escalation / high message pressure';
            case AuraShieldTag.personalInfo:
              return 'Personal info / doxxing-adjacent content';
          }
        }

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TruLuraSafetyMeterPill(meter: _meter.meterForThread(aura)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('AuraShield context', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
                  ],
                ),
                const SizedBox(height: 10),
                Text('This is on-device pattern detection designed to protect without stigmatizing. It’s not a label or a verdict.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35)),
                if (aura.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...aura.tags.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• ${tagText(t)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.78))),
                      )),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => context.pop(), child: const Text('Close'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          context.pop();
                          context.push(AppRoutes.safetyCenter);
                        },
                        child: const Text('Safety Center'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _maybeShowCrisisSupport() async {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support check-in', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'If you’re in immediate danger or thinking about self-harm, consider contacting local emergency services or a trusted person right now.\n\nTrulura can also help you slow the conversation pace and add boundaries.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.74), height: 1.35),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => context.pop(), child: const Text('Dismiss'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resources (stub)')));
                        },
                        child: const Text('Resources'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _stub(String what) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$what (stub)')));
    context.pop();
  }
}

class _ChatThreadSkeleton extends StatelessWidget {
  const _ChatThreadSkeleton();

  @override
  Widget build(BuildContext context) {
    return TruShimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
        children: const [
          _BubbleSkeleton(isMe: false),
          _BubbleSkeleton(isMe: true),
          _BubbleSkeleton(isMe: false),
          _BubbleSkeleton(isMe: true),
          _BubbleSkeleton(isMe: false),
        ],
      ),
    );
  }
}

class _BubbleSkeleton extends StatelessWidget {
  final bool isMe;
  const _BubbleSkeleton({required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
          child: const TruSkeletonBox(width: double.infinity, height: 46, radius: 18),
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  final ValueChanged<String> onPrompt;
  const _EmptyThread({required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    return TruStatePanel(
      glyph: TruLuraGlyph.messages,
      title: 'Start the conversation',
      message: 'Break the silence with something light — your vibe matters more than the perfect line.',
      actions: [
        TruStateAction(label: 'What caught your eye?', glyph: TruLuraGlyph.spark, onTap: () => onPrompt('What caught your eye?'), primary: true),
        TruStateAction(label: 'Ask about their vibe', glyph: TruLuraGlyph.insights, onTap: () => onPrompt('What’s your vibe been like lately?')),
        TruStateAction(label: 'Comment on profile', glyph: TruLuraGlyph.person, onTap: () => onPrompt('I loved your profile — what are you into right now?')),
      ],
    );
  }
}

enum _PendingState { sending, failed }

class _PendingMessage {
  final String tempId;
  final String content;
  final _PendingState state;
  const _PendingMessage({required this.tempId, required this.content, this.state = _PendingState.sending});

  _PendingMessage copyWith({String? tempId, String? content, _PendingState? state}) =>
      _PendingMessage(tempId: tempId ?? this.tempId, content: content ?? this.content, state: state ?? this.state);
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _SheetAction({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = danger ? cs.error : cs.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline.withValues(alpha: 0.16), width: TruLuraSurfaces.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: fg))),
            Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outline.withValues(alpha: 0.16), width: TruLuraSurfaces.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: cs.onSurface),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _ReactionPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReactionPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: selected ? 0.75 : 0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: (selected ? cs.primary : cs.outline).withValues(alpha: 0.22), width: TruLuraSurfaces.hairline),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
