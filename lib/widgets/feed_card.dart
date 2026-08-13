import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/providers/trulura_mode_controller.dart';
import 'package:trulura/theme/mood_colors.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_halo_avatar.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_orb_chip.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/breathing_glow.dart';
import 'package:trulura/widgets/trulura_profile_preview_sheet.dart';
import 'package:trulura/widgets/trulura_ai_suggestions_sheet.dart';
import 'package:trulura/services/database_service/database_service.dart';
import 'package:trulura/services/post_service.dart';
import 'package:trulura/services/user_service.dart';
import 'package:trulura/services/feed_behavior_service.dart';

class FeedCard extends StatefulWidget {
  final Post post;
  final int initialGlowCount;
  final bool initiallyGlowed;
  final String? whyAmISeeingThis;

  const FeedCard(
      {super.key,
      required this.post,
      this.initialGlowCount = 0,
      this.initiallyGlowed = false,
      this.whyAmISeeingThis});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard>
    with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final UserService _userService = UserService();

  bool _reacted = false;
  int _reactCount = 0;
  bool _isReactLoading = false;
  bool _hasGlowed = false;
  int _glowCount = 0;
  bool _isGlowLoading = false;
  int _glowPulseTick = 0;
  bool _connectSent = false;
  bool _sharing = false;
  late final AnimationController _atmosphere;

  String? _resolvedName;
  String? _resolvedProfileImage;

  @override
  void initState() {
    super.initState();
    _atmosphere = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _hasGlowed = widget.initiallyGlowed;
    _glowCount = widget.initialGlowCount;
    _loadGlowState();
    _loadIdentity();
  }

  @override
  void dispose() {
    _atmosphere.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _hasGlowed = widget.initiallyGlowed;
      _glowCount = widget.initialGlowCount;
      _reacted = false;
      _reactCount = 0;
      _resolvedName = null;
      _resolvedProfileImage = null;
      _loadGlowState();
      _loadIdentity();
    } else {
      final oldInlineName = oldWidget.post.user?.name;
      final newInlineName = widget.post.user?.name;
      if (oldInlineName != newInlineName) {
        _loadIdentity();
      }

      // Keep local optimistic UI state, but accept new server count if it changes.
      if (oldWidget.initialGlowCount != widget.initialGlowCount) {
        _glowCount = widget.initialGlowCount;
      }
      if (oldWidget.initiallyGlowed != widget.initiallyGlowed) {
        _hasGlowed = widget.initiallyGlowed;
      }
    }
  }

  bool _isUnknownName(String? name) {
    final n = name?.trim();
    if (n == null || n.isEmpty) return true;
    final lower = n.toLowerCase();
    return lower == 'unknown' || lower == 'unknown user' || lower == 'n/a';
  }

  String _fallbackIdentityLabel(Post post) {
    if (post.isAnonymous) return 'Anonymous';
    return 'New member';
  }

  Future<void> _loadIdentity() async {
    final post = widget.post;
    if (post.isAnonymous) {
      if (!mounted) return;
      setState(() {
        _resolvedName = 'Anonymous';
        _resolvedProfileImage = null;
      });
      return;
    }

    final postUser = post.user;
    if (postUser != null && !_isUnknownName(postUser.name)) {
      if (!mounted) return;
      setState(() {
        _resolvedName = postUser.name;
        _resolvedProfileImage = postUser.profileImage;
      });
      return;
    }

    try {
      // Best-effort: we only have robust data for the current user (auth-only setup).
      // But we can still upgrade the UI if we have a cached user.
      final currentUserId = _currentSupabaseUserId();
      final u = (currentUserId != null && post.userId == currentUserId)
          ? await _userService.getCurrentUser()
          : await _userService.getUserById(post.userId);

      if (!mounted) return;
      if (u != null && !_isUnknownName(u.name)) {
        setState(() {
          _resolvedName = u.name;
          _resolvedProfileImage = u.profileImage;
        });
      } else {
        setState(() {
          _resolvedName = _fallbackIdentityLabel(post);
          _resolvedProfileImage = null;
        });
      }
    } catch (e) {
      debugPrint('FeedCard: load identity failed: $e');
      if (!mounted) return;
      setState(() {
        _resolvedName = _fallbackIdentityLabel(post);
        _resolvedProfileImage = null;
      });
    }
  }

  ImageProvider<Object>? _imageProviderFor(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    final isNetwork = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    return isNetwork ? NetworkImage(v) : AssetImage(v);
  }

  String _vibeLabelFor(Post post, String displayName) {
    // Energy-based identity, deterministic but soft.
    // Prefer moodTag if available so it feels intentional.
    const labels = <String>[
      'Old Soul',
      'Healing',
      'Reflective',
      'Grounded',
      'Gentle Fire',
      'Radiant',
      'Soft Power',
      'Seeking',
    ];
    final seed =
        '${post.moodTag ?? ''}|${post.userId}|$displayName|${post.content.length}';
    final hash =
        seed.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return labels[hash % labels.length];
  }

  Future<void> _loadGlowState() async {
    final postId = widget.post.id;
    if (postId.isEmpty) return;
    if (!DatabaseService.instance.isInitialized) return;

    try {
      final hasGlowed = await _postService.hasGlowed(postId);
      final glowCount = await _postService.getGlowCount(postId);

      final hasHeart = await _postService.hasReactedWith(
          postId: postId, reactionType: 'heart');
      final hasLaugh = await _postService.hasReactedWith(
          postId: postId, reactionType: 'laugh');

      final heartCount = await _postService.getReactionCount(
          postId: postId, reactionType: 'heart');
      final laughCount = await _postService.getReactionCount(
          postId: postId, reactionType: 'laugh');

      if (!mounted) return;
      setState(() {
        _hasGlowed = hasGlowed;
        _glowCount = glowCount;

        _reacted = hasHeart || hasLaugh;
        _reactCount = heartCount + laughCount;
      });
    } catch (e) {
      debugPrint('FeedCard: load glow state failed: $e');
    }
  }

  Future<void> _toggleGlow() async {
    final messenger = ScaffoldMessenger.of(context);
    final userId = context.read<AppProvider>().currentUser?.id;
    if (_isGlowLoading) return;

    final postId = widget.post.id;
    if (postId.isEmpty) return;

    if (!DatabaseService.instance.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Reactions are unavailable until Supabase is configured.')),
      );
      return;
    }

    final previousHasGlowed = _hasGlowed;
    final previousGlowCount = _glowCount;

    final nextHasGlowed = !_hasGlowed;
    setState(() {
      _isGlowLoading = true;
      _hasGlowed = nextHasGlowed;
      _glowCount = nextHasGlowed
          ? _glowCount + 1
          : (_glowCount > 0 ? _glowCount - 1 : 0);
      if (nextHasGlowed) _glowPulseTick++;
    });

    try {
      await _postService.toggleGlow(postId);
      await _loadGlowState();

      await FeedBehaviorService.instance.logSignal(
        signal: TruFeedSignal.glow,
        postId: widget.post.id,
        authorId: widget.post.userId,
        moodTag: widget.post.moodTag,
        category: widget.post.category,
        userId: userId,
      );
    } catch (e) {
      debugPrint('FeedCard: toggle glow failed: $e');
      if (!mounted) return;
      setState(() {
        _hasGlowed = previousHasGlowed;
        _glowCount = previousGlowCount;
      });
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not update glow. Please try again.')));
    } finally {
      if (mounted) setState(() => _isGlowLoading = false);
    }
  }

  Future<void> _handleReactionSelection(String reactionType) async {
    final messenger = ScaffoldMessenger.of(context);
    final userId = context.read<AppProvider>().currentUser?.id;
    if (_isReactLoading) return;

    final postId = widget.post.id;
    if (postId.isEmpty) return;

    if (!DatabaseService.instance.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Reactions are unavailable until Supabase is configured.')),
      );
      return;
    }

    setState(() => _isReactLoading = true);

    try {
      await _postService.toggleReaction(
          postId: postId, reactionType: reactionType);
      await _loadGlowState();

      await FeedBehaviorService.instance.logSignal(
        signal: TruFeedSignal.react,
        postId: widget.post.id,
        authorId: widget.post.userId,
        moodTag: widget.post.moodTag,
        category: widget.post.category,
        userId: userId,
      );
    } catch (e) {
      debugPrint('FeedCard: toggle reaction failed: $e');
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not update reaction. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isReactLoading = false);
    }
  }

  String? _currentSupabaseUserId() {
    if (!DatabaseService.instance.isInitialized) return null;
    return DatabaseService.instance.client.auth.currentUser?.id;
  }

  void _openUserProfile(BuildContext context) {
    final post = widget.post;
    if (post.isAnonymous) return;
    final name = _resolvedName ?? (post.user?.name ?? 'Profile');
    TruluraProfilePreviewSheet.show(
      context: context,
      userId: post.userId,
      user: post.user,
      isAnonymous: post.isAnonymous,
      displayName: name,
      profileImage: _resolvedProfileImage ?? post.user?.profileImage,
    );
  }

  Future<void> _openMoreSheet(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final why = widget.whyAmISeeingThis;
    final post = widget.post;

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
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Post options',
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: TruLuraIcon(
                          glyph: TruLuraGlyph.close,
                          size: 18,
                          active: false,
                          color: cs.onSurface.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (why != null && why.trim().isNotEmpty) ...[
                  Text('Why am I seeing this?',
                      style:
                          t.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: TruLuraSurfaces.hairline),
                    ),
                    child: Text(why,
                        style: t.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.78),
                            height: 1.35)),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ReactionChip(
                        label: 'AI assist',
                        glyph: TruLuraGlyph.spark,
                        onTap: () {
                          context.pop();
                          TruluraAiSuggestionsSheet.show(
                              context: context,
                              postText: post.content,
                              feedTabLabel: 'Feed');
                        }),
                    _ReactionChip(
                        label: 'Hide',
                        glyph: TruLuraGlyph.close,
                        onTap: () {
                          context.pop();
                          final userId =
                              context.read<AppProvider>().currentUser?.id;
                          FeedBehaviorService.instance
                              .hidePost(postId: post.id, userId: userId);
                          FeedBehaviorService.instance.logSignal(
                              signal: TruFeedSignal.dismiss,
                              postId: post.id,
                              authorId: post.userId,
                              moodTag: post.moodTag,
                              category: post.category,
                              userId: userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Hidden from your feed.')));
                        }),
                    _ReactionChip(
                        label: 'Report',
                        glyph: TruLuraGlyph.shield,
                        onTap: () {
                          context.pop();
                          final userId =
                              context.read<AppProvider>().currentUser?.id;
                          FeedBehaviorService.instance
                              .reportPost(postId: post.id, userId: userId);
                          FeedBehaviorService.instance.logSignal(
                              signal: TruFeedSignal.report,
                              postId: post.id,
                              authorId: post.userId,
                              moodTag: post.moodTag,
                              category: post.category,
                              userId: userId);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Reported. Thanks for protecting the space.')));
                        }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _openReactionsSheet(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    return await showModalBottomSheet<String>(
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
                Text('React',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ReactionChip(
                        label: 'Glow',
                        glyph: TruLuraGlyph.spark,
                        onTap: () => context.pop('glow')),
                    _ReactionChip(
                        label: 'Heart',
                        glyph: TruLuraGlyph.heartOutline,
                        onTap: () => context.pop('heart')),
                    _ReactionChip(
                        label: 'Laugh',
                        glyph: TruLuraGlyph.messages,
                        onTap: () => context.pop('laugh')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openComments(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    final userId = context.read<AppProvider>().currentUser?.id;
    FeedBehaviorService.instance.logSignal(
      signal: TruFeedSignal.commentOpen,
      postId: widget.post.id,
      authorId: widget.post.userId,
      moodTag: widget.post.moodTag,
      category: widget.post.category,
      userId: userId,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                Row(
                  children: [
                    Expanded(
                        child: Text('Comments',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900))),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: TruLuraIcon(
                          glyph: TruLuraGlyph.close,
                          size: 20,
                          active: true,
                          color: cs.onSurface),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Comment threads are scaffolded for MVP. Next we’ll wire real replies + counts via backend.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.74),
                      height: 1.45),
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Write a supportive comment…',
                    filled: true,
                    fillColor:
                        cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment sent (stub)')));
                      context.pop();
                    },
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleShare(TruParticipationContext participation) async {
    if (_sharing || participation.effectivePermissions.suppressVirality) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final userId = context.read<AppProvider>().currentUser?.id;
    setState(() => _sharing = true);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    FeedBehaviorService.instance.logSignal(
      signal: TruFeedSignal.share,
      postId: widget.post.id,
      authorId: widget.post.userId,
      moodTag: widget.post.moodTag,
      category: widget.post.category,
      userId: userId,
    );
    setState(() => _sharing = false);
    messenger.showSnackBar(const SnackBar(content: Text('Share sheet (stub)')));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final mode = context.watch<TruLuraModeController>().mode;
    final participation =
        context.watch<ExperienceModeController>().participationContext;

    final post = widget.post;
    final currentUserId = _currentSupabaseUserId();
    // Only show CONNECT when we can positively confirm the viewer is signed in
    // and the post belongs to someone else.
    final canMessage = participation.effectivePermissions.messaging !=
        TruPermissionLevel.blocked;
    final shouldShowConnect = currentUserId != null &&
        !post.isAnonymous &&
        post.userId != currentUserId &&
        canMessage &&
        !participation.isProtectedEmotionalSpace &&
        !participation.isYouthContext;

    final moodGlow =
        MoodColors.glow(post.moodTag ?? '').withValues(alpha: 0.35);
    final visualSpec = _FeedCardVisualSpec.fromPost(post, mode);

    final rawName = _resolvedName ?? post.user?.name;
    final displayName = post.isAnonymous
        ? 'Anonymous'
        : User.publicDisplayNameFrom(
            rawName,
            email: post.user?.email,
            fallback: 'New member',
          );
    final isFallbackIdentity =
        !post.isAnonymous && (displayName == 'New member');
    final profileImage = post.isAnonymous
        ? null
        : (_resolvedProfileImage ?? post.user?.profileImage);
    final vibeLabel =
        post.isAnonymous ? 'Anonymous' : _vibeLabelFor(post, displayName);

    final auraBackground = _PostAuraBackground(
      mode: mode,
      moodTag: post.moodTag,
      imageAssetOrUrl: post.imageUrl,
      brightness: brightness,
      spec: visualSpec,
    );
    final normalizedType = post.type.trim().toLowerCase();
    final isStyledText = normalizedType == 'quote' ||
        normalizedType == 'styled' ||
        normalizedType == 'text';
    final hasMediaPanel = normalizedType == 'image' ||
        normalizedType == 'video' ||
        (post.imageUrl != null && post.imageUrl!.trim().isNotEmpty);

    final suspendedOffset = Offset(
      ((visualSpec.seed % 7) - 3) * 0.65,
      ((visualSpec.seed % 5) - 2) * 0.45,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: visualSpec.topLift,
        bottom: visualSpec.bottomBreath + visualSpec.gravity * 8,
      ),
      child: Transform.translate(
        offset: suspendedOffset,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(visualSpec.radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(visualSpec.radius),
              boxShadow: [
                ...TruLuraEffects.premiumCardDepth(moodGlow,
                    intensity: brightness == Brightness.dark ? 1.34 : 0.68),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: brightness == Brightness.dark ? 0.52 : 0.18,
                  ),
                  blurRadius: 48,
                  spreadRadius: -20,
                  offset: const Offset(0, 30),
                ),
                BoxShadow(
                  color: visualSpec.accentB.withValues(
                    alpha: brightness == Brightness.dark
                        ? 0.24 + visualSpec.gravity * 0.16
                        : 0.10 + visualSpec.gravity * 0.06,
                  ),
                  blurRadius: 58 + visualSpec.gravity * 22,
                  spreadRadius: -22,
                  offset: const Offset(0, 26),
                ),
                BoxShadow(
                  color: visualSpec.accentA.withValues(
                    alpha: brightness == Brightness.dark ? 0.18 : 0.08,
                  ),
                  blurRadius: 44,
                  spreadRadius: -28,
                  offset: const Offset(-10, -6),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _atmosphere,
              builder: (context, _) {
                final progress = _atmosphere.value;
                final lift = math.sin(
                      progress *
                          math.pi *
                          2 *
                          visualSpec.motionTempo *
                          (1 - visualSpec.gravity * 0.34),
                    ) *
                    visualSpec.floatRange *
                    (1 - visualSpec.gravity * 0.42);
                return Transform.translate(
                  offset: Offset(0, -lift),
                  child: Stack(
                    children: [
                      // Full-bleed visual aura (image OR gradient) — the post is the atmosphere.
                      Positioned.fill(child: auraBackground),

                      // Cinematic readability scrim.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(
                                    alpha: brightness == Brightness.dark
                                        ? 0.56
                                        : 0.24),
                                Colors.black.withValues(alpha: 0.08),
                                Colors.black.withValues(
                                    alpha: brightness == Brightness.dark
                                        ? 0.78
                                        : 0.46),
                              ],
                              stops: const [0.0, 0.40, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _AmbientCardLightPainter(
                              accentA: visualSpec.accentA,
                              accentB: visualSpec.accentB,
                              seed: visualSpec.seed,
                              progress: progress,
                              emotionalWeight: visualSpec.emotionalWeight,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PostEnergyFlowPainter(
                              progress: progress,
                              accentA: visualSpec.accentA,
                              accentB: visualSpec.accentB,
                              seed: visualSpec.seed,
                              emotionalWeight: visualSpec.emotionalWeight,
                              compression: visualSpec.compression,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _EmotionalGravityPainter(
                              progress: progress,
                              gravity: visualSpec.gravity,
                              accentA: visualSpec.accentA,
                              accentB: visualSpec.accentB,
                              seed: visualSpec.seed,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _EmotionalWeatherOverlayPainter(
                              accentA: visualSpec.accentA,
                              accentB: visualSpec.accentB,
                              seed: visualSpec.seed,
                              progress: progress,
                              compression: visualSpec.compression,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(visualSpec.radius),
                              border: Border.all(
                                color: visualSpec.accentB.withValues(
                                  alpha: brightness == Brightness.dark
                                      ? 0.18
                                      : 0.10,
                                ),
                                width: TruLuraSurfaces.hairline,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Layered content.
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          14 + visualSpec.leftInset,
                          13,
                          14,
                          13,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FeedHeaderRow(
                              mode: mode,
                              name: displayName,
                              vibeLabel: vibeLabel,
                              moodTag: post.moodTag,
                              isAnonymous: post.isAnonymous,
                              isFallbackIdentity: isFallbackIdentity,
                              isBoosted: post.isBoosted,
                              isMonetized: post.isMonetized,
                              visualSpec: visualSpec,
                              showTransparency: context
                                  .watch<AppProvider>()
                                  .transparencyExplainersEnabled,
                              profileImage: profileImage,
                              onTapProfile: post.isAnonymous
                                  ? null
                                  : () => _openUserProfile(context),
                              onTapMore: () => _openMoreSheet(context),
                              imageProvider: _imageProviderFor(profileImage),
                            ),
                            const SizedBox(height: 10),
                            _PostContentBlock(
                              text: post.content,
                              caption: post.caption,
                              type: normalizedType,
                              textStyle: post.textStyle,
                              backgroundColorHex: post.backgroundColorHex,
                              isStyledText: isStyledText,
                              visualSpec: visualSpec,
                            ),
                            if (hasMediaPanel) ...[
                              const SizedBox(height: 9),
                              _PostMediaPanel(
                                type: normalizedType,
                                imageUrl: post.imageUrl,
                                caption: post.caption,
                              ),
                            ],
                            const SizedBox(height: 10),
                            _PostPresenceStrip(
                              mode: mode,
                              glowCount: _glowCount,
                              reactCount: _reactCount,
                              shareCount: post.shareCount,
                              moodTag: post.moodTag,
                              isCreator: post.isCreatorContent ||
                                  post.inferredExperienceMode() ==
                                      TruExperienceMode.creator,
                            ),
                            const SizedBox(height: 9),
                            _EmotionalActionRow(
                              mode: mode,
                              ctx: participation,
                              hasGlowed: _hasGlowed,
                              glowCount: _glowCount,
                              reacted: _reacted,
                              reactCount: _reactCount,
                              glowPulseTick: _glowPulseTick,
                              shareCount: post.shareCount,
                              sharing: _sharing,
                              shareSuppressed: participation
                                  .effectivePermissions.suppressVirality,
                              onTapGlow: _toggleGlow,
                              onTapSpark: () async {
                                final selected =
                                    await _openReactionsSheet(context);
                                if (!context.mounted || selected == null) {
                                  return;
                                }
                                if (selected == 'glow') {
                                  await _toggleGlow();
                                  return;
                                }
                                await _handleReactionSelection(selected);
                              },
                              onTapEcho: () => _openComments(context),
                              onTapShare: () => _handleShare(participation),
                            ),
                            const SizedBox(height: 10),
                            if (shouldShowConnect)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: 0.66,
                                  child: _ActionPill(
                                    mode: mode,
                                    glyph: TruLuraGlyph.spark,
                                    label: _connectSent ? 'SENT' : 'CONNECT',
                                    emphasized: !post.isAnonymous,
                                    onTap: (post.isAnonymous || _connectSent)
                                        ? null
                                        : () {
                                            setState(() => _connectSent = true);
                                            final userId = context
                                                .read<AppProvider>()
                                                .currentUser
                                                ?.id;
                                            FeedBehaviorService.instance
                                                .logSignal(
                                              signal: TruFeedSignal.connect,
                                              postId: post.id,
                                              authorId: post.userId,
                                              moodTag: post.moodTag,
                                              category: post.category,
                                              userId: userId,
                                            );
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Connect request sent')));
                                          },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _FeedCardVisualSpec {
  final String label;
  final TruLuraGlyph glyph;
  final Color accentA;
  final Color accentB;
  final double radius;
  final double leftInset;
  final double topLift;
  final double bottomBreath;
  final int seed;
  final double emotionalWeight;
  final double motionTempo;
  final double floatRange;
  final double compression;
  final double gravity;

  const _FeedCardVisualSpec({
    required this.label,
    required this.glyph,
    required this.accentA,
    required this.accentB,
    required this.radius,
    required this.leftInset,
    required this.topLift,
    required this.bottomBreath,
    required this.seed,
    required this.emotionalWeight,
    required this.motionTempo,
    required this.floatRange,
    required this.compression,
    this.gravity = 0.34,
  });

  bool get hasTypeLabel => label.isNotEmpty;

  static _FeedCardVisualSpec fromPost(Post post, TruLuraMode mode) {
    final p = kTruLuraPalettes[mode]!;
    final category = post.category.toLowerCase();
    final type = post.type.toLowerCase();
    final mood = (post.moodTag ?? '').toLowerCase();
    final seed = '${post.id}|${post.userId}|${post.content}'.hashCode.abs();
    final gravity = _gravityFor(post);

    if (mood.contains('flirt') ||
        mood.contains('romance') ||
        mood.contains('spark') ||
        mood.contains('crush')) {
      return _FeedCardVisualSpec(
        label: 'Warm signal',
        glyph: TruLuraGlyph.heartOutline,
        accentA: TruLuraTokens.auraPink,
        accentB: TruLuraBrandColors.syncRose,
        radius: 30,
        leftInset: seed.isEven ? 2 : 5,
        topLift: 1,
        bottomBreath: 9,
        seed: seed,
        emotionalWeight: 0.68,
        motionTempo: 1.12,
        floatRange: 1.2,
        compression: 0.84,
        gravity: gravity,
      );
    }
    if (mood.contains('reflect') ||
        mood.contains('ground') ||
        mood.contains('old soul') ||
        mood.contains('quiet')) {
      return _FeedCardVisualSpec(
        label: 'Reflective note',
        glyph: TruLuraGlyph.moon,
        accentA: TruLuraTokens.auraViolet,
        accentB: TruLuraBrandColors.neonBlue,
        radius: 29,
        leftInset: seed.isEven ? 0 : 4,
        topLift: 5,
        bottomBreath: 10,
        seed: seed,
        emotionalWeight: 0.82,
        motionTempo: 0.62,
        floatRange: 0.7,
        compression: 1.06,
        gravity: gravity,
      );
    }
    if (mood.contains('social') ||
        mood.contains('radiant') ||
        mood.contains('party') ||
        mood.contains('community')) {
      return _FeedCardVisualSpec(
        label: 'Social wave',
        glyph: TruLuraGlyph.groups,
        accentA: TruLuraTokens.auraCyan,
        accentB: TruLuraTokens.auraPink,
        radius: 28,
        leftInset: seed.isEven ? 6 : 1,
        topLift: 0,
        bottomBreath: 8,
        seed: seed,
        emotionalWeight: 0.58,
        motionTempo: 1.18,
        floatRange: 1.5,
        compression: 0.76,
        gravity: gravity,
      );
    }
    if (post.contentType == TruPostContentType.support ||
        post.isAnonymous ||
        mood.contains('heal') ||
        mood.contains('calm') ||
        category.contains('support') ||
        category.contains('vent')) {
      return _FeedCardVisualSpec(
        label: post.isAnonymous ? 'Soft check-in' : 'Support note',
        glyph: TruLuraGlyph.moon,
        accentA: TruLuraTokens.auraCyan,
        accentB: TruLuraBrandColors.neonPurple,
        radius: 30,
        leftInset: 2,
        topLift: 6,
        bottomBreath: 10,
        seed: seed,
        emotionalWeight: 0.92,
        motionTempo: 0.48,
        floatRange: 0.5,
        compression: category.contains('vent') ? 1.34 : 1.10,
        gravity: gravity,
      );
    }
    if (post.contentType == TruPostContentType.creator ||
        post.isCreatorContent ||
        category.contains('creator') ||
        category.contains('luxe') ||
        type == 'image' ||
        type == 'video') {
      return _FeedCardVisualSpec(
        label: category.contains('luxe')
            ? 'Luxe signal'
            : type == 'video'
                ? 'Creator drop'
                : 'Visual aura',
        glyph: type == 'video' ? TruLuraGlyph.video : TruLuraGlyph.image,
        accentA: category.contains('luxe')
            ? TruLuraBrandColors.glowGold
            : TruLuraTokens.auraPink,
        accentB: TruLuraTokens.auraCyan,
        radius: 30,
        leftInset: seed.isEven ? 0 : 3,
        topLift: 0,
        bottomBreath: 8,
        seed: seed,
        emotionalWeight: category.contains('luxe') ? 0.72 : 0.60,
        motionTempo: category.contains('luxe') ? 0.58 : 1.05,
        floatRange: category.contains('luxe') ? 0.6 : 1.3,
        compression: category.contains('luxe') ? 0.92 : 0.78,
        gravity: gravity,
      );
    }
    if (category.contains('quiz') ||
        category.contains('prompt') ||
        category.contains('compat')) {
      return _FeedCardVisualSpec(
        label: 'Aura prompt',
        glyph: TruLuraGlyph.insights,
        accentA: TruLuraBrandColors.glowGold,
        accentB: p.glowB,
        radius: 26,
        leftInset: 4,
        topLift: 4,
        bottomBreath: 7,
        seed: seed,
        emotionalWeight: 0.70,
        motionTempo: 0.82,
        floatRange: 0.9,
        compression: 0.96,
        gravity: gravity,
      );
    }
    if (category.contains('community') || category.contains('discussion')) {
      return _FeedCardVisualSpec(
        label: 'Conversation starter',
        glyph: TruLuraGlyph.groups,
        accentA: TruLuraTokens.auraCyan,
        accentB: p.glowA,
        radius: 27,
        leftInset: 0,
        topLift: 2,
        bottomBreath: 6,
        seed: seed,
        emotionalWeight: 0.52,
        motionTempo: 1.10,
        floatRange: 1.1,
        compression: 0.82,
        gravity: gravity,
      );
    }
    if (category.contains('repost') || category.contains('thread')) {
      return _FeedCardVisualSpec(
        label: category.contains('thread') ? 'Threaded reply' : 'Repost aura',
        glyph: category.contains('thread')
            ? TruLuraGlyph.messages
            : TruLuraGlyph.share,
        accentA: TruLuraTokens.auraCyan,
        accentB: TruLuraTokens.auraViolet,
        radius: 26,
        leftInset: 5,
        topLift: 5,
        bottomBreath: 9,
        seed: seed,
        emotionalWeight: 0.76,
        motionTempo: 0.72,
        floatRange: 0.8,
        compression: 1.02,
        gravity: gravity,
      );
    }
    if (category.contains('music') || category.contains('audio')) {
      return _FeedCardVisualSpec(
        label: category.contains('audio') ? 'Audio mood' : 'Music-linked',
        glyph: TruLuraGlyph.tv,
        accentA: TruLuraTokens.auraPink,
        accentB: TruLuraBrandColors.glowGold,
        radius: 30,
        leftInset: 1,
        topLift: 2,
        bottomBreath: 8,
        seed: seed,
        emotionalWeight: 0.64,
        motionTempo: 1.0,
        floatRange: 1.1,
        compression: 0.88,
        gravity: gravity,
      );
    }
    return _FeedCardVisualSpec(
      label: mood.isEmpty ? 'Aura note' : 'Mood post',
      glyph: TruLuraGlyph.spark,
      accentA: p.glowA,
      accentB: p.glowB,
      radius: 28,
      leftInset: seed.isEven ? 0 : 2,
      topLift: seed % 3 == 0 ? 4 : 0,
      bottomBreath: 6,
      seed: seed,
      emotionalWeight: 0.58,
      motionTempo: 0.86,
      floatRange: 0.8,
      compression: 0.90,
      gravity: gravity,
    );
  }

  static double _gravityFor(Post post) {
    final text =
        '${post.category} ${post.moodTag ?? ''} ${post.content}'.toLowerCase();
    var gravity = post.emotionalIntensityScore.clamp(0, 100) / 100.0 * 0.72;
    if (text.contains('confess') ||
        text.contains('vulnerable') ||
        text.contains('healing') ||
        text.contains('milestone') ||
        text.contains('memory') ||
        text.contains('reconnect')) {
      gravity += 0.20;
    }
    if (post.isAnonymous || post.contentType == TruPostContentType.support) {
      gravity += 0.14;
    }
    return gravity.clamp(0.0, 1.0);
  }
}

class _AmbientCardLightPainter extends CustomPainter {
  final Color accentA;
  final Color accentB;
  final int seed;
  final double progress;
  final double emotionalWeight;

  const _AmbientCardLightPainter({
    required this.accentA,
    required this.accentB,
    required this.seed,
    required this.progress,
    required this.emotionalWeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..blendMode = BlendMode.screen;
    final shift = (seed % 17) / 17.0;
    final phase = progress * math.pi * 2;
    final breath = 0.5 + math.sin(phase) * 0.5;
    final weight = emotionalWeight.clamp(0.45, 1.25);

    void glow(Offset center, double radius, Color color, double alpha) {
      paint.shader = RadialGradient(
        colors: [color.withValues(alpha: alpha), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    glow(
      Offset(size.width * (0.12 + shift * 0.10), size.height * 0.18),
      size.shortestSide * (0.50 + breath * 0.08),
      accentA,
      0.11 + weight * 0.06,
    );
    glow(
      Offset(size.width * (0.86 - shift * 0.08),
          size.height * (0.88 - breath * 0.04)),
      size.shortestSide * (0.58 + weight * 0.08),
      accentB,
      0.090 + weight * 0.05,
    );
    glow(
      Offset(size.width * (0.52 + shift * 0.06), size.height * 0.02),
      size.shortestSide * 0.42,
      Colors.white,
      0.028,
    );

    final arcPaint = Paint()
      ..blendMode = BlendMode.screen
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1
      ..shader = SweepGradient(
        colors: [
          accentA.withValues(alpha: 0.0),
          accentA.withValues(alpha: 0.16),
          accentB.withValues(alpha: 0.10),
          accentA.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * (0.50 + shift * 0.08), size.height * 0.22),
        radius: size.shortestSide * 0.52,
      ));
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * (0.50 + shift * 0.08), size.height * 0.22),
        radius: size.shortestSide * 0.52,
      ),
      -1.2,
      2.35,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientCardLightPainter oldDelegate) {
    return oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.seed != seed ||
        oldDelegate.progress != progress ||
        oldDelegate.emotionalWeight != emotionalWeight;
  }
}

class _PostEnergyFlowPainter extends CustomPainter {
  final double progress;
  final Color accentA;
  final Color accentB;
  final int seed;
  final double emotionalWeight;
  final double compression;

  const _PostEnergyFlowPainter({
    required this.progress,
    required this.accentA,
    required this.accentB,
    required this.seed,
    required this.emotionalWeight,
    required this.compression,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final phase = progress * math.pi * 2;
    final weight = emotionalWeight.clamp(0.45, 1.25);
    final pressure = compression.clamp(0.7, 1.45);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.1);

    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.24 + i * 0.22 + math.sin(phase + i) * 0.018);
      paint
        ..strokeWidth = (0.7 + weight * 0.65) * pressure
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            (i.isEven ? accentA : accentB).withValues(alpha: 0.070 * weight),
            Colors.white.withValues(alpha: 0.018 * weight),
            Colors.transparent,
          ],
        ).createShader(rect);
      final path = Path()
        ..moveTo(-size.width * 0.06, y)
        ..cubicTo(
          size.width * (0.18 + math.sin(phase * 0.7 + i) * 0.035),
          y - 12 / pressure,
          size.width * 0.66,
          y + 16 / pressure,
          size.width * 1.06,
          y - 5,
        );
      canvas.drawPath(path, paint);
    }

    final dot = Paint()..blendMode = BlendMode.plus;
    final count = (7 + weight * 8).round();
    for (var i = 0; i < count; i++) {
      final lane = ((seed + i * 23) % 100) / 100.0;
      final x = ((lane + progress * (0.018 + i * 0.001)) % 1.0) * size.width;
      final y = size.height *
          (0.14 + (((seed ~/ 3) + i * 17) % 72) / 100.0 / pressure);
      dot.color =
          (i.isEven ? accentA : accentB).withValues(alpha: 0.040 * weight);
      canvas.drawCircle(Offset(x, y), 0.9 + (i % 3) * 0.35, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _PostEnergyFlowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.seed != seed ||
        oldDelegate.emotionalWeight != emotionalWeight ||
        oldDelegate.compression != compression;
  }
}

class _EmotionalGravityPainter extends CustomPainter {
  final double progress;
  final double gravity;
  final Color accentA;
  final Color accentB;
  final int seed;

  const _EmotionalGravityPainter({
    required this.progress,
    required this.gravity,
    required this.accentA,
    required this.accentB,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || gravity <= 0.08) return;
    final rect = Offset.zero & size;
    final phase = progress * math.pi * 2;
    final breathe = 0.5 + math.sin(phase * 0.55 + seed % 7) * 0.5;
    final g = gravity.clamp(0.0, 1.0);

    final dim = Paint()
      ..blendMode = BlendMode.srcOver
      ..shader = RadialGradient(
        center: Alignment(0.05 + math.sin(phase) * 0.08, 0.12),
        radius: 1.05 - g * 0.16,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.10 * g),
          Colors.black.withValues(alpha: 0.24 * g),
        ],
        stops: const [0.0, 0.70, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, dim);

    final focus = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: Alignment(-0.22 + breathe * 0.18, -0.28),
        radius: 0.78,
        colors: [
          accentA.withValues(alpha: 0.10 * g),
          accentB.withValues(alpha: 0.035 * g),
          Colors.transparent,
        ],
        stops: const [0, 0.46, 1],
      ).createShader(rect);
    canvas.drawRect(rect, focus);

    final silence = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 + g * 1.2
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..color = Colors.white.withValues(alpha: 0.020 + g * 0.030)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    final y = size.height * (0.78 - breathe * 0.08);
    final path = Path()
      ..moveTo(size.width * 0.16, y)
      ..cubicTo(size.width * 0.34, y + 8, size.width * 0.62, y - 10,
          size.width * 0.86, y + 2);
    canvas.drawPath(path, silence);
  }

  @override
  bool shouldRepaint(covariant _EmotionalGravityPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.gravity != gravity ||
        oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.seed != seed;
  }
}

class _EmotionalWeatherOverlayPainter extends CustomPainter {
  final Color accentA;
  final Color accentB;
  final int seed;
  final double progress;
  final double compression;

  const _EmotionalWeatherOverlayPainter({
    required this.accentA,
    required this.accentB,
    required this.seed,
    required this.progress,
    required this.compression,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final phase = progress * math.pi * 2;
    final pressure = compression.clamp(0.75, 1.45);
    final mist = Paint()
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        begin:
            Alignment(-1.0 + math.sin(phase) * 0.05, -0.55 + (seed % 5) * 0.06),
        end: Alignment(1.0 - math.cos(phase) * 0.04, 0.62),
        colors: [
          Colors.transparent,
          accentA.withValues(alpha: 0.046 / pressure),
          Colors.white.withValues(alpha: 0.018),
          accentB.withValues(alpha: 0.038 / pressure),
          Colors.transparent,
        ],
        stops: const [0.0, 0.24, 0.48, 0.72, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, mist);

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..color = Colors.white.withValues(alpha: 0.045);
    for (var row = 0; row < 3; row++) {
      final y = size.height *
          (0.30 + row * 0.18 / pressure + math.sin(phase + row) * 0.008);
      final path = Path()..moveTo(size.width * -0.05, y);
      path.cubicTo(size.width * 0.25, y - 8 - row * 2, size.width * 0.62,
          y + 10, size.width * 1.05, y - 4);
      canvas.drawPath(path, wavePaint);
    }

    final dot = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 10; i++) {
      final x = size.width * (((seed + i * 19) % 100) / 100);
      final y = size.height * (0.12 + ((seed + i * 29) % 70) / 100 / pressure);
      dot.color = (i.isEven ? accentA : accentB).withValues(alpha: 0.045);
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.45, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _EmotionalWeatherOverlayPainter oldDelegate) {
    return oldDelegate.accentA != accentA ||
        oldDelegate.accentB != accentB ||
        oldDelegate.seed != seed ||
        oldDelegate.progress != progress ||
        oldDelegate.compression != compression;
  }
}

class _PostContentBlock extends StatelessWidget {
  final String text;
  final String? caption;
  final String type;
  final String? textStyle;
  final String? backgroundColorHex;
  final bool isStyledText;
  final _FeedCardVisualSpec visualSpec;

  const _PostContentBlock({
    required this.text,
    required this.caption,
    required this.type,
    required this.textStyle,
    required this.backgroundColorHex,
    required this.isStyledText,
    required this.visualSpec,
  });

  Color? _backgroundColor() {
    final raw = backgroundColorHex?.trim();
    if (raw == null || raw.isEmpty || !raw.startsWith('#') || raw.length != 7) {
      return null;
    }
    return Color(int.parse('0xFF${raw.substring(1)}'));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final display =
        text.trim().isNotEmpty ? text.trim() : (caption ?? '').trim();
    final styleKey = (textStyle ?? '').toLowerCase();
    final baseStyle = (styleKey == 'editorial' || type == 'quote')
        ? t.headlineSmall
        : styleKey == 'glow'
            ? t.titleLarge
            : t.bodyLarge;
    final labelStyle = t.labelSmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.72),
      fontWeight: FontWeight.w900,
      letterSpacing: 0.18,
    );
    final textWidget = Text(
      display,
      style: baseStyle?.copyWith(
        height: 1.42,
        color: Colors.white.withValues(alpha: 0.93),
        fontWeight: styleKey == 'glow' ? FontWeight.w900 : null,
        fontStyle: type == 'quote' ? FontStyle.italic : null,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        14,
        visualSpec.hasTypeLabel ? 11 : 13,
        14,
        14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (_backgroundColor() ?? visualSpec.accentA)
                .withValues(alpha: isStyledText ? 0.22 : 0.12),
            Colors.black.withValues(alpha: 0.18),
            visualSpec.accentB.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.13),
          width: TruLuraSurfaces.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: visualSpec.accentA.withValues(alpha: 0.10),
            blurRadius: 22,
            spreadRadius: -12,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (visualSpec.hasTypeLabel) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TruLuraIcon(
                  glyph: visualSpec.glyph,
                  size: 14,
                  active: true,
                  color: Colors.white.withValues(alpha: 0.76),
                ),
                const SizedBox(width: 7),
                Text(visualSpec.label, style: labelStyle),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (display.isNotEmpty) textWidget,
        ],
      ),
    );
  }
}

class _PostMediaPanel extends StatelessWidget {
  final String type;
  final String? imageUrl;
  final String? caption;

  const _PostMediaPanel({
    required this.type,
    required this.imageUrl,
    required this.caption,
  });

  ImageProvider<Object>? _imageProviderFor(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    final isNetwork = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    return isNetwork ? NetworkImage(v) : AssetImage(v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final provider = _imageProviderFor(imageUrl);
    final isVideo = type == 'video';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: isVideo ? 16 / 9 : 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (provider != null)
              Image(image: provider, fit: BoxFit.cover)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TruLuraTokens.auraViolet.withValues(alpha: 0.44),
                      TruLuraTokens.auraCyan.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.48),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.34),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: TruLuraSurfaces.hairline,
                  ),
                ),
                child: TruLuraIcon(
                  glyph: isVideo ? TruLuraGlyph.video : TruLuraGlyph.image,
                  size: 24,
                  active: true,
                  color: Colors.white,
                ),
              ),
            ),
            if ((caption ?? '').trim().isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Text(
                  caption!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedHeaderRow extends StatelessWidget {
  final TruLuraMode mode;
  final String name;
  final String vibeLabel;
  final String? moodTag;
  final bool isAnonymous;
  final bool isFallbackIdentity;
  final bool isBoosted;
  final bool isMonetized;
  final _FeedCardVisualSpec visualSpec;
  final bool showTransparency;
  final String? profileImage;
  final VoidCallback? onTapProfile;
  final VoidCallback onTapMore;
  final ImageProvider<Object>? imageProvider;

  const _FeedHeaderRow({
    required this.mode,
    required this.name,
    required this.vibeLabel,
    required this.moodTag,
    required this.isAnonymous,
    required this.isFallbackIdentity,
    required this.isBoosted,
    required this.isMonetized,
    required this.visualSpec,
    required this.showTransparency,
    required this.profileImage,
    required this.onTapProfile,
    required this.onTapMore,
    required this.imageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = kTruLuraPalettes[mode]!;
    final cs = Theme.of(context).colorScheme;

    int derivedCompatibility() {
      // Stable, “pleasant” looking percent: 60–94.
      final s = '$name|${moodTag ?? ''}|${profileImage ?? ''}';
      final hash =
          s.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
      return 60 + (hash % 35);
    }

    return Row(
      children: [
        _NoSplashTap(
          onTap: onTapProfile,
          child: BreathingGlow(
            enabled: !isAnonymous,
            glowColor: p.glowB.withValues(alpha: 0.65),
            maxBlur: 34,
            minBlur: 18,
            maxAlpha: 0.34,
            minAlpha: 0.18,
            child: TruLuraHaloAvatar(
              radius: 22,
              tone: TruLuraModeTone.aura,
              image: imageProvider,
              // Keep a gentle % badge — makes identity feel energetic.
              matchPercent:
                  isAnonymous ? null : (derivedCompatibility() / 100.0),
              fallback: const TruLuraIcon(glyph: TruLuraGlyph.person, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NoSplashTap(
                onTap: onTapProfile,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.08), end: Offset.zero)
                          .animate(anim),
                      child: child,
                    ),
                  ),
                  child: Row(
                    key: ValueKey<String>(
                        'name:$name:${isFallbackIdentity ? 'fallback' : 'real'}'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.15,
                            color: Colors.white.withValues(alpha: 0.98),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isAnonymous) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (isFallbackIdentity ? p.glowA : p.glowB)
                                .withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    visualSpec.accentB.withValues(alpha: 0.38),
                                width: TruLuraSurfaces.hairline),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    visualSpec.accentA.withValues(alpha: 0.14),
                                blurRadius: 14,
                                spreadRadius: -8,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            vibeLabel,
                            style: t.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.18,
                                color: Colors.white.withValues(alpha: 0.92)),
                          ),
                        ),
                        if (showTransparency && (isBoosted || isMonetized)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cs.surface.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  width: TruLuraSurfaces.hairline),
                            ),
                            child: Text(
                              isBoosted ? 'BOOST' : 'INFO',
                              style: t.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.22,
                                  color: Colors.white.withValues(alpha: 0.90)),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              if (moodTag != null || isAnonymous || isFallbackIdentity)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TruLuraIcon(
                          glyph: TruLuraGlyph.spark,
                          size: 14,
                          active: true,
                          color: Colors.white.withValues(alpha: 0.82)),
                      const SizedBox(width: 6),
                      Text(
                        isAnonymous
                            ? 'Anonymous share'
                            : (isFallbackIdentity
                                ? 'Identity syncing…'
                                : 'Mood'),
                        style: t.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.18,
                            color: Colors.white.withValues(alpha: 0.82)),
                      ),
                      if (moodTag != null) ...[
                        const SizedBox(width: 8),
                        TruLuraOrbChip(
                          label: moodTag!,
                          selected: true,
                          compact: true,
                          size: 28,
                          glyph: TruLuraGlyph.spark,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (showTransparency)
          _NoSplashIconButton(
            tooltip: 'Why am I seeing this?',
            onTap: onTapMore,
            child: TruLuraIcon(
                glyph: TruLuraGlyph.info,
                size: 20,
                active: false,
                color: Colors.white.withValues(alpha: 0.82)),
          ),
        _NoSplashIconButton(
          tooltip: 'More',
          onTap: onTapMore,
          child: TruLuraIcon(
              glyph: TruLuraGlyph.more,
              size: 20,
              active: false,
              color: Colors.white.withValues(alpha: 0.90)),
        ),
      ],
    );
  }
}

class _PostAuraBackground extends StatelessWidget {
  final TruLuraMode mode;
  final String? moodTag;
  final String? imageAssetOrUrl;
  final Brightness brightness;
  final _FeedCardVisualSpec spec;

  const _PostAuraBackground(
      {required this.mode,
      required this.moodTag,
      required this.imageAssetOrUrl,
      required this.brightness,
      required this.spec});

  ImageProvider<Object>? _imageProvider() {
    final raw = imageAssetOrUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    final isNetwork = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    return isNetwork ? NetworkImage(raw) : AssetImage(raw);
  }

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    final mood = MoodColors.glow(moodTag ?? '');
    final image = _imageProvider();

    // We avoid flat cards: a living, full-bleed “scene”.
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(Colors.black, p.bg0, 0.82) ?? p.bg0,
                  Color.lerp(TruLuraTokens.ink, p.bg1, 0.70) ?? p.bg1,
                  Color.lerp(TruLuraTokens.deepIndigo, spec.accentA, 0.18) ??
                      TruLuraTokens.deepIndigo,
                ],
              ),
            ),
          ),
        ),
        if (image != null)
          Positioned.fill(
            child: Image(
              image: image,
              fit: BoxFit.cover,
              color: Colors.black.withValues(
                  alpha: brightness == Brightness.dark ? 0.10 : 0.06),
              colorBlendMode: BlendMode.darken,
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.25, -0.15),
                  radius: 1.05,
                  colors: [
                    mood.withValues(alpha: 0.36),
                    spec.accentB.withValues(alpha: 0.26),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TruLuraTokens.auraViolet.withValues(alpha: 0.13),
                    spec.accentA.withValues(alpha: 0.105),
                    spec.accentB.withValues(alpha: 0.09),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.72, -0.92),
                  radius: 1.0,
                  colors: [
                    Colors.white.withValues(alpha: 0.070),
                    spec.accentB.withValues(alpha: 0.055),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PostPresenceStrip extends StatelessWidget {
  final TruLuraMode mode;
  final int glowCount;
  final int reactCount;
  final int shareCount;
  final String? moodTag;
  final bool isCreator;

  const _PostPresenceStrip({
    required this.mode,
    required this.glowCount,
    required this.reactCount,
    required this.shareCount,
    required this.moodTag,
    required this.isCreator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final palette = kTruLuraPalettes[mode]!;
    final total = glowCount + reactCount + shareCount;
    final label = isCreator
        ? 'creator room active'
        : total >= 8
            ? 'orbit energy rising'
            : total >= 3
                ? '$total people tuning into this vibe'
                : (moodTag?.trim().isNotEmpty ?? false)
                    ? 'people are reflecting here'
                    : 'quiet space tonight';
    final sub = total >= 8
        ? 'Active discussion'
        : total >= 3
            ? 'Vibe chain'
            : isCreator
                ? 'Live aura'
                : 'Low-pressure';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.070),
            palette.glowB.withValues(alpha: 0.070),
            Colors.black.withValues(alpha: 0.060),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.095),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Row(
        children: [
          _TinyPulse(color: palette.glowB),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.88),
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            sub,
            style: t.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPulse extends StatefulWidget {
  final Color color;

  const _TinyPulse({required this.color});

  @override
  State<_TinyPulse> createState() => _TinyPulseState();
}

class _TinyPulseState extends State<_TinyPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final v = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.48 + 0.28 * v),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.18 + 0.18 * v),
                blurRadius: 12 + 8 * v,
                spreadRadius: -3,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmotionalActionRow extends StatelessWidget {
  final TruLuraMode mode;
  final TruParticipationContext ctx;
  final bool hasGlowed;
  final int glowCount;
  final bool reacted;
  final int reactCount;
  final int glowPulseTick;
  final int shareCount;
  final bool sharing;
  final bool shareSuppressed;
  final VoidCallback onTapGlow;
  final VoidCallback onTapSpark;
  final VoidCallback onTapEcho;
  final VoidCallback onTapShare;

  const _EmotionalActionRow({
    required this.mode,
    required this.ctx,
    required this.hasGlowed,
    required this.glowCount,
    required this.reacted,
    required this.reactCount,
    required this.glowPulseTick,
    required this.shareCount,
    required this.sharing,
    required this.shareSuppressed,
    required this.onTapGlow,
    required this.onTapSpark,
    required this.onTapEcho,
    required this.onTapShare,
  });

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    final spec = _ActionSpec.forContext(ctx);
    return Row(
      children: [
        Expanded(
          child: _GlowPulse(
            tick: glowPulseTick,
            child: BreathingGlow(
              enabled: hasGlowed,
              glowColor: p.glowB,
              maxBlur: 34,
              minBlur: 18,
              maxAlpha: 0.32,
              minAlpha: 0.12,
              child: _ActionPill(
                mode: mode,
                glyph: spec.primaryGlyph,
                label: spec.primaryLabel,
                count: glowCount,
                emphasized: hasGlowed,
                primary: true,
                onTap: onTapGlow,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Opacity(
            opacity: spec.showSecondary ? 1.0 : 0.35,
            child: _ActionPill(
              mode: mode,
              glyph: spec.secondaryGlyph,
              label: spec.secondaryLabel,
              count: spec.secondaryShowsCount ? reactCount : null,
              emphasized: reacted,
              onTap: spec.showSecondary ? onTapSpark : null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Opacity(
            opacity: spec.showTertiary ? 1.0 : 0.35,
            child: _ActionPill(
              mode: mode,
              glyph: spec.tertiaryGlyph,
              label: spec.tertiaryLabel,
              count: null,
              onTap: spec.showTertiary ? onTapEcho : null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Opacity(
            opacity: shareSuppressed ? 0.35 : 1.0,
            child: _ActionPill(
              mode: mode,
              glyph: TruLuraGlyph.share,
              label: sharing ? 'Share...' : 'Share',
              count: shareCount,
              badgeTight: true,
              integratedBadge: true,
              onTap: shareSuppressed ? null : onTapShare,
            ),
          ),
        ),
      ],
    );
  }
}

@immutable
class _ActionSpec {
  final String primaryLabel;
  final TruLuraGlyph primaryGlyph;
  final String secondaryLabel;
  final TruLuraGlyph secondaryGlyph;
  final String tertiaryLabel;
  final TruLuraGlyph tertiaryGlyph;
  final bool showSecondary;
  final bool showTertiary;
  final bool secondaryShowsCount;

  const _ActionSpec({
    required this.primaryLabel,
    required this.primaryGlyph,
    required this.secondaryLabel,
    required this.secondaryGlyph,
    required this.tertiaryLabel,
    required this.tertiaryGlyph,
    required this.showSecondary,
    required this.showTertiary,
    required this.secondaryShowsCount,
  });

  static _ActionSpec forContext(TruParticipationContext ctx) {
    // First: hard protections.
    if (ctx.isYouthContext) {
      return const _ActionSpec(
        primaryLabel: 'Glow',
        primaryGlyph: TruLuraGlyph.spark,
        secondaryLabel: 'Echo',
        secondaryGlyph: TruLuraGlyph.heartOutline,
        tertiaryLabel: 'Soft Reply',
        tertiaryGlyph: TruLuraGlyph.messages,
        showSecondary: false,
        showTertiary: false,
        secondaryShowsCount: false,
      );
    }
    if (ctx.isProtectedEmotionalSpace) {
      return const _ActionSpec(
        primaryLabel: 'Hold',
        primaryGlyph: TruLuraGlyph.moon,
        secondaryLabel: 'Reflect',
        secondaryGlyph: TruLuraGlyph.heartOutline,
        tertiaryLabel: 'Support',
        tertiaryGlyph: TruLuraGlyph.messages,
        showSecondary: true,
        showTertiary: true,
        secondaryShowsCount: true,
      );
    }

    switch (ctx.activeMode) {
      case TruExperienceMode.dating:
        return const _ActionSpec(
          primaryLabel: 'Spark',
          primaryGlyph: TruLuraGlyph.spark,
          secondaryLabel: 'Glow',
          secondaryGlyph: TruLuraGlyph.heartOutline,
          tertiaryLabel: 'Whisper',
          tertiaryGlyph: TruLuraGlyph.messages,
          showSecondary: true,
          showTertiary: true,
          secondaryShowsCount: true,
        );
      case TruExperienceMode.altIntimate:
        return const _ActionSpec(
          primaryLabel: 'Signal',
          primaryGlyph: TruLuraGlyph.shield,
          secondaryLabel: 'Glow',
          secondaryGlyph: TruLuraGlyph.heartOutline,
          tertiaryLabel: 'Whisper',
          tertiaryGlyph: TruLuraGlyph.messages,
          showSecondary: true,
          showTertiary: true,
          secondaryShowsCount: true,
        );
      case TruExperienceMode.luxe:
        return const _ActionSpec(
          primaryLabel: 'Glow',
          primaryGlyph: TruLuraGlyph.spark,
          secondaryLabel: 'Admire',
          secondaryGlyph: TruLuraGlyph.heartOutline,
          tertiaryLabel: 'Note',
          tertiaryGlyph: TruLuraGlyph.messages,
          showSecondary: true,
          showTertiary: true,
          secondaryShowsCount: true,
        );
      case TruExperienceMode.creator:
        return const _ActionSpec(
          primaryLabel: 'Glow',
          primaryGlyph: TruLuraGlyph.spark,
          secondaryLabel: 'Vibe Bomb',
          secondaryGlyph: TruLuraGlyph.heartOutline,
          tertiaryLabel: 'Echo',
          tertiaryGlyph: TruLuraGlyph.messages,
          showSecondary: true,
          showTertiary: true,
          secondaryShowsCount: true,
        );
      case TruExperienceMode.friendship:
        return const _ActionSpec(
          primaryLabel: 'Glow',
          primaryGlyph: TruLuraGlyph.spark,
          secondaryLabel: 'Support',
          secondaryGlyph: TruLuraGlyph.heartOutline,
          tertiaryLabel: 'Soft Intro',
          tertiaryGlyph: TruLuraGlyph.messages,
          showSecondary: true,
          showTertiary: true,
          secondaryShowsCount: true,
        );

      case TruExperienceMode.social:
        return const _ActionSpec(
          primaryLabel: 'Glow',
          primaryGlyph: TruLuraGlyph.spark,
          secondaryLabel: 'Reflect',
          secondaryGlyph: TruLuraGlyph.heartOutline,
          tertiaryLabel: 'Echo',
          tertiaryGlyph: TruLuraGlyph.messages,
          showSecondary: true,
          showTertiary: true,
          secondaryShowsCount: true,
        );

      case TruExperienceMode.vent:
      case TruExperienceMode.youth:
        // handled above.
        return const _ActionSpec(
          primaryLabel: 'Glow',
          primaryGlyph: TruLuraGlyph.spark,
          secondaryLabel: 'Reflect',
          secondaryGlyph: TruLuraGlyph.heartOutline,
          tertiaryLabel: 'Support',
          tertiaryGlyph: TruLuraGlyph.messages,
          showSecondary: true,
          showTertiary: true,
          secondaryShowsCount: true,
        );
    }
  }
}

class _ReactionChip extends StatelessWidget {
  final String label;
  final TruLuraGlyph glyph;
  final VoidCallback onTap;

  const _ReactionChip(
      {required this.label, required this.glyph, required this.onTap});

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
          border: Border.all(
              color: cs.outline.withValues(alpha: 0.16),
              width: TruLuraSurfaces.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TruLuraIcon(
                glyph: glyph, size: 18, active: true, color: cs.onSurface),
            const SizedBox(width: 8),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final TruLuraMode mode;
  final TruLuraGlyph glyph;
  final String label;
  final int? count;
  final bool emphasized;
  final bool primary;
  final bool badgeTight;
  final bool integratedBadge;
  final VoidCallback? onTap;

  const _ActionPill({
    required this.mode,
    required this.glyph,
    required this.label,
    this.count,
    this.emphasized = false,
    this.primary = false,
    this.badgeTight = false,
    this.integratedBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = kTruLuraPalettes[mode]!;

    const pillHeight = 42.0;
    const hPad = 10.0;
    const vPad = 10.0;

    final String resolvedLabel = label.trim();

    final bool isConnect = resolvedLabel == 'CONNECT';

    if (isConnect) {
      return _NoSplashTap(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding:
                const EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(colors: [p.glowA, p.glowB]),
              boxShadow: [
                BoxShadow(
                  color: p.glowB.withValues(alpha: 0.50),
                  blurRadius: 25,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: SizedBox(
              height: pillHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const TruLuraIcon(
                      glyph: TruLuraGlyph.spark,
                      size: 18,
                      active: true,
                      color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        resolvedLabel,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.45),
                      ),
                    ),
                  ),
                  if (count != null) ...[
                    SizedBox(width: badgeTight ? 8 : 10),
                    _CountBadge(
                        count: count!,
                        emphasized: true,
                        mode: mode,
                        integrated: integratedBadge),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _NoSplashTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: (primary || emphasized)
              ? [
                  BoxShadow(
                    color: (emphasized ? p.glowB : p.glowA)
                        .withValues(alpha: emphasized ? 0.26 : 0.18),
                    blurRadius: emphasized ? 20 : 14,
                    spreadRadius: -8,
                    offset: const Offset(0, 9),
                  ),
                ]
              : const [],
        ),
        child: SizedBox(
          height: pillHeight,
          child: TruLuraGlassCard(
            paletteMode: mode,
            gradientStroke: primary,
            radius: 999,
            blur: 14,
            depth: primary || emphasized,
            padding:
                const EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            fillAOverride: primary
                ? p.glowA.withValues(alpha: emphasized ? 0.28 : 0.20)
                : TruLuraTokens.nebula
                    .withValues(alpha: emphasized ? 0.34 : 0.26),
            fillBOverride: primary
                ? p.glowB.withValues(alpha: emphasized ? 0.24 : 0.16)
                : TruLuraTokens.deepIndigo
                    .withValues(alpha: emphasized ? 0.28 : 0.22),
            borderColorOverride: primary
                ? p.glowB.withValues(alpha: emphasized ? 0.66 : 0.50)
                : p.border.withValues(alpha: emphasized ? 0.55 : 0.40),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.38, -0.20),
                          radius: 1.05,
                          colors: [
                            (primary ? p.glowA : p.glowB).withValues(
                              alpha: emphasized || primary ? 0.15 : 0.055,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TruLuraIcon(
                      glyph: glyph,
                      size: primary ? 18 : 17,
                      active: emphasized || primary,
                      color: primary
                          ? (emphasized
                              ? p.glowB
                              : p.glowA.withValues(alpha: 0.96))
                          : (emphasized
                              ? p.glowB
                              : cs.onSurface.withValues(alpha: 0.84)),
                    ),
                    const SizedBox(width: 8),
                    // Primary actions must never ellipsize; scale-down keeps the full label visible.
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          resolvedLabel,
                          maxLines: 1,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: cs.onSurface
                                    .withValues(alpha: primary ? 0.98 : 0.90),
                                fontWeight:
                                    primary ? FontWeight.w900 : FontWeight.w800,
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                    ),
                    if (count != null) ...[
                      SizedBox(width: badgeTight ? 8 : 10),
                      _CountBadge(
                          count: count!,
                          emphasized: emphasized || primary,
                          mode: mode,
                          integrated: integratedBadge),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowPulse extends StatelessWidget {
  final int tick;
  final Widget child;

  const _GlowPulse({required this.tick, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        final scale = TweenSequence<double>([
          TweenSequenceItem(
              tween: Tween(begin: 1.0, end: 1.04)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
              weight: 40),
          TweenSequenceItem(
              tween: Tween(begin: 1.04, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeInOutCubic)),
              weight: 60),
        ]).animate(animation);
        return ScaleTransition(scale: scale, child: child);
      },
      child: KeyedSubtree(key: ValueKey<int>(tick), child: child),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool emphasized;
  final TruLuraMode mode;
  final bool integrated;

  const _CountBadge(
      {required this.count,
      required this.emphasized,
      required this.mode,
      this.integrated = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = kTruLuraPalettes[mode]!;

    final bg = integrated
        ? (emphasized
            ? p.glowB.withValues(alpha: 0.14)
            : cs.onSurface.withValues(alpha: 0.08))
        : (emphasized
            ? p.glowB.withValues(alpha: 0.16)
            : cs.surfaceContainerHighest.withValues(alpha: 0.45));
    final border = integrated
        ? (emphasized
            ? p.glowB.withValues(alpha: 0.28)
            : cs.outline.withValues(alpha: 0.10))
        : (emphasized
            ? p.glowB.withValues(alpha: 0.35)
            : cs.outline.withValues(alpha: 0.16));
    final fg = emphasized ? p.glowB : cs.onSurface.withValues(alpha: 0.80);

    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: EdgeInsets.symmetric(
          horizontal: integrated ? 7 : 8, vertical: integrated ? 4 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: TruLuraSurfaces.hairline),
      ),
      child: Text(
        count.toString(),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _NoSplashIconButton extends StatelessWidget {
  final Widget child;
  final String? tooltip;
  final VoidCallback? onTap;

  const _NoSplashIconButton(
      {required this.child, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return _NoSplashTap(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: child,
        ),
      ),
    );
  }
}

class _NoSplashTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _NoSplashTap({required this.child, required this.onTap});

  @override
  State<_NoSplashTap> createState() => _NoSplashTapState();
}

class _NoSplashTapState extends State<_NoSplashTap> {
  bool _pressed = false;

  void _set(bool v) {
    if (!mounted) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: enabled ? 1 : 0.55,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          scale: _pressed && enabled ? 0.98 : 1,
          child: widget.child,
        ),
      ),
    );
  }
}
