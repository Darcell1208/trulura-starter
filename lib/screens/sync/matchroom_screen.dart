import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/models/sync_candidate/sync_candidate.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/openai/openai_config.dart';
import 'package:trulura/services/chat_service.dart';
import 'package:trulura/services/sync_service/sync_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_primary_button.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';

class MatchroomScreen extends StatefulWidget {
  final String matchId;

  const MatchroomScreen({super.key, required this.matchId});

  @override
  State<MatchroomScreen> createState() => _MatchroomScreenState();
}

class _MatchroomScreenState extends State<MatchroomScreen> {
  final SyncService _sync = SyncService();
  final ChatService _chat = ChatService();
  final UserService _users = UserService();

  bool _loading = true;
  bool _error = false;
  User? _me;
  User? _target;
  TruActiveMatch? _match;
  TruMatchroom? _room;
  int _messageCount = 0;

  List<String>? _conciergeTips;
  bool _conciergeLoading = false;
  String? _conciergeError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final me = await _users.getCurrentUser();
      if (me == null) {
        setState(() {
          _loading = false;
          _error = true;
        });
        return;
      }

      final matches = await _sync.getActiveMatches(userId: me.id);
      final match = matches.where((m) => m.id == widget.matchId).toList(growable: false).firstOrNull;
      if (match == null) {
        setState(() {
          _loading = false;
          _error = true;
        });
        return;
      }

      final target = await _users.getUserById(match.targetUserId);
      final messages = await _chat.getMessagesByChatId(match.chatId);
      final messageCount = messages.length;
      final room = await _sync.ensureMatchroomUnlocked(userId: me.id, match: match, messageCount: messageCount);
      if (room != null && match.matchroomId != room.id) {
        await _sync.setMatchStage(userId: me.id, matchId: match.id, stage: TruConnectionStage.matchroom, matchroomId: room.id);
      }

      setState(() {
        _me = me;
        _match = match;
        _target = target;
        _messageCount = messageCount;
        _room = room;
        _loading = false;
      });
    } catch (e) {
      truLogStateError('Matchroom._load', e);
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _loadConcierge() async {
    if (_conciergeLoading) return;
    final me = _me;
    final target = _target;
    final match = _match;
    if (me == null || target == null || match == null) return;

    setState(() {
      _conciergeLoading = true;
      _conciergeError = null;
    });

    try {
      final state = await _sync.getState(userId: me.id);
      final tips = TruOpenAI.isConfigured
          ? await TruOpenAI().suggestMatchConciergeTips(
              viewerName: me.name,
              targetName: target.name,
              purpose: state.preferences.purpose.label,
              stage: match.stage.name,
              compatibilityReasons: const <String>[],
              lowEnergyMode: state.preferences.lowEnergyMode,
            )
          : <String>[
              'Ask one specific question, then give space for a real answer.',
              'Confirm consent before deeper topics: “Want to go personal or keep it light?”',
              'Set a pacing boundary: “Slow replies are okay — no pressure.”',
              'Try a micro-plan: daylight coffee, fixed end time, independent transit.',
              'Name one value you share and one curiosity you want to explore.',
            ];

      if (!mounted) return;
      setState(() {
        _conciergeTips = tips;
        _conciergeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _conciergeError = 'Concierge couldn’t load right now.';
        _conciergeLoading = false;
      });
      debugPrint('Matchroom concierge error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error || _match == null) {
      return Scaffold(
        body: TruStatePanel(
          tone: TruLuraModeTone.sync,
          glyph: TruLuraGlyph.info,
          title: 'Matchroom unavailable',
          message: 'We couldn’t open this matchroom right now.',
          actions: [TruStateAction(label: 'Back', glyph: TruLuraGlyph.back, onTap: () => context.pop(), primary: true)],
        ),
      );
    }

    final targetName = _target?.name ?? 'Connection';
    final room = _room;
    final unlocked = room != null;
    final subtitle = unlocked ? 'Unlocked • $_messageCount messages' : 'Locked • Send a few messages first';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TruLuraGlassAppBar(
        mode: TruLuraMode.sync,
        title: 'Matchroom',
        showBack: true,
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const TruLuraIcon(glyph: TruLuraGlyph.close, size: 20),
          ),
        ],
      ),
      body: TruLuraLayeredBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            children: [
              TruLuraGlassCard(
                mode: TruLuraMode.sync,
                radius: 22,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TruLuraIcon(glyph: TruLuraGlyph.heart, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(targetName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                          ),
                          child: Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A private connection space with gentle structure — not a replacement for organic conversation.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45, color: cs.onSurface.withValues(alpha: 0.74)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TruLuraGlassCard(
                mode: TruLuraMode.sync,
                radius: 22,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TruLuraIcon(glyph: TruLuraGlyph.insights, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text('AI concierge', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transparent suggestions. You’re always in control.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35, color: cs.onSurface.withValues(alpha: 0.72)),
                    ),
                    const SizedBox(height: 12),
                    if (_conciergeTips == null && _conciergeError == null)
                      TruLuraPrimaryButton(
                        onPressed: _conciergeLoading ? null : _loadConcierge,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_conciergeLoading ? Icons.hourglass_bottom_rounded : Icons.auto_awesome_rounded, size: 18),
                            const SizedBox(width: 10),
                            Text(_conciergeLoading ? 'Loading…' : 'Get guidance'),
                          ],
                        ),
                      )
                    else if (_conciergeError != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TruInlineBanner(glyph: TruLuraGlyph.info, text: _conciergeError!),
                          const SizedBox(height: 10),
                          Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: _loadConcierge, child: const Text('Retry'))),
                        ],
                      )
                    else
                      ...?_conciergeTips?.map((t) => Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                              ),
                              child: Text(t, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.35)),
                            ),
                          )),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TruLuraGlassCard(
                mode: TruLuraMode.sync,
                radius: 22,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TruLuraIcon(glyph: TruLuraGlyph.spark, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Guided prompts', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unlocked ? 'Choose one prompt. Keep it real, specific, and respectful.' : 'Unlock by exchanging a few messages first.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35, color: cs.onSurface.withValues(alpha: 0.72)),
                    ),
                    const SizedBox(height: 12),
                    if (!unlocked)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TruInlineBanner(glyph: TruLuraGlyph.lock, text: 'Matchroom locked — send a few messages to unlock.'),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(onPressed: () => context.go('/messages/thread/${_match!.chatId}'), child: const Text('Open chat')),
                          ),
                        ],
                      )
                    else
                      ...room.prompts.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(p, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.35))),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    onPressed: () => context.go('/messages/thread/${_match!.chatId}'),
                                    icon: Icon(Icons.chat_bubble_rounded, color: cs.onSurface.withValues(alpha: 0.82)),
                                    style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                                  ),
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TruLuraGlassCard(
                mode: TruLuraMode.sync,
                radius: 22,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TruLuraIcon(glyph: TruLuraGlyph.shield, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Safety defaults', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Matchrooms encourage calm pacing. Use public meetups, set end-times, and keep autonomy.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35, color: cs.onSurface.withValues(alpha: 0.72)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNullX<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
