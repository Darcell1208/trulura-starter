import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/core/navigation/tru_route_observer.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/services/database_service/database_service.dart';
import 'package:trulura/services/post_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/widgets/trulura_glass_app_bar.dart';
import 'package:trulura/widgets/trulura_layered_background.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_post_composer.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_screen_state.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_feed_components.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/experience_mode_controller.dart';
import 'package:trulura/models/experience/experience_mode.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> with RouteAware {
  final _contentController = TextEditingController();
  final _captionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _postType = 'Public';
  String _format = 'Text';
  String _privacy = 'Public';
  String? _selectedMood;
  bool _isAnonymous = false;
  bool _isPosting = false;
  String? _errorText;
  bool _mediaStubAttached = false;
  String _textStyle = 'Serif';
  String _textBackground = '#1A1B3F';
  String _textTemplate = 'Freeform';

  final List<String> _moods = [
    'Cheerful',
    'Energetic',
    'Calm',
    'Creative',
    'Adventurous',
    'Focused'
  ];

  void _applyTemplate(String template) {
    setState(() {
      _textTemplate = template;
      if (template == 'Quote') {
        _contentController.text = '“A short line that feels true right now.”';
        _textStyle = 'Editorial';
      } else if (template == 'Statement') {
        _contentController.text =
            'Here is the energy I am bringing into today.';
        _textStyle = 'Glow';
      } else {
        _contentController.clear();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Soft default based on active experience mode.
    // This keeps the current backend schema intact while making the UI behave
    // as an intent-driven system.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = context.read<ExperienceModeController>().participationContext;
      if (ctx.activeMode == TruExperienceMode.vent) {
        setState(() {
          _postType = 'Vent';
          _privacy = 'Private';
          _isAnonymous = true;
        });
      } else if (ctx.activeMode == TruExperienceMode.creator) {
        setState(() {
          _postType = 'Public';
          _privacy = 'Public';
          _isAnonymous = false;
        });
      } else if (ctx.activeMode == TruExperienceMode.dating ||
          ctx.activeMode == TruExperienceMode.altIntimate ||
          ctx.activeMode == TruExperienceMode.luxe) {
        setState(() {
          _postType = 'Mood';
          _privacy = 'Public';
          _selectedMood ??= _moods.first;
          _isAnonymous = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      truRouteObserver.unsubscribe(this);
      truRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    truRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    _contentController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  String _mapPrivacyForDb(String value) {
    switch (value.toLowerCase()) {
      case 'public':
        return 'public';
      case 'friends':
        return 'followers';
      case 'private':
        return 'private';
      default:
        return 'public';
    }
  }

  Future<void> _createPost() async {
    if (_isPosting) return;
    final ctx = context.read<ExperienceModeController>().participationContext;
    final content = _contentController.text.trim();
    final caption = _captionController.text.trim();
    final primaryText = _format == 'Text' ? content : caption;
    if (primaryText.isEmpty &&
        (_selectedMood == null || _selectedMood!.trim().isEmpty)) {
      setState(() => _errorText = 'Add text, media, or a mood before posting.');
      return;
    }

    setState(() {
      _errorText = null;
      _isPosting = true;
    });

    final currentAuthUser = DatabaseService.instance.client.auth.currentUser;
    if (currentAuthUser == null) {
      setState(() {
        _errorText = 'You need to be signed in to post.';
        _isPosting = false;
      });
      return;
    }

    final post = Post(
      id: '',
      userId: currentAuthUser.id,
      user: null,
      content: primaryText,
      caption: _format == 'Text' ? null : caption,
      imageUrl: null,
      type: _format.toLowerCase(),
      textStyle: _format == 'Text' ? _textStyle.toLowerCase() : null,
      backgroundColorHex: _format == 'Text' ? _textBackground : null,
      moodTag: _selectedMood,
      privacy: _mapPrivacyForDb(_privacy),
      category: _postType == 'Vent' ? 'Vent' : 'ForYou',
      isAnonymous: _isAnonymous || _postType == 'Vent',
      experienceMode: ctx.activeMode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await PostService().savePost(post);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Posted ✨')));
      context.pop();
    } catch (e) {
      truLogStateError('CreatePost._createPost', e);
      if (!mounted) return;
      final msg = e.toString();
      String friendly = 'Your post couldn’t be published right now. Try again.';
      if (msg.contains('PGRST204')) {
        friendly =
            'Backend schema mismatch (missing column). Please sync your posts table columns.';
      } else if (msg.contains('42501') || msg.toLowerCase().contains('rls')) {
        friendly =
            'Not allowed by privacy rules (RLS). Check posts RLS for inserts.';
      } else if (msg.contains('23503') &&
          msg.toLowerCase().contains('profiles')) {
        friendly =
            'Posting is blocked by a backend foreign key to profiles. Remove that FK (auth-only) or create a profile row.';
      }
      setState(() => _errorText = friendly);
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui =
        truParseUiState(GoRouterState.of(context).uri.queryParameters['ui']);
    final ctx = context.watch<ExperienceModeController>().participationContext;

    if (ui == TruUiState.action) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: TruLuraGlassAppBar(
          mode: TruLuraMode.aura,
          showBack: true,
          title: 'Create Post',
        ),
        body: TruLuraLayeredBackground(
          tone: TruLuraModeTone.aura,
          mode: TruLuraMode.aura,
          padding: const EdgeInsets.only(top: 86),
          child: SafeArea(
            top: false,
            child: TruStatePanel(
              glyph: TruLuraGlyph.spark,
              title: 'Posted',
              message: 'Your post is live in Aura. Want to keep the momentum?',
              actions: [
                TruStateAction(
                    label: 'Back to Aura',
                    glyph: TruLuraGlyph.aura,
                    onTap: () => context.pop(),
                    primary: true),
                TruStateAction(
                    label: 'Create another',
                    glyph: TruLuraGlyph.edit,
                    onTap: () => context.go('/create_post')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TruLuraGlassAppBar(
        mode: TruLuraMode.aura,
        showBack: true,
        title: 'Create Post',
      ),
      body: TruLuraLayeredBackground(
        tone: TruLuraModeTone.aura,
        mode: TruLuraMode.aura,
        padding: const EdgeInsets.only(top: 86),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: kTruluraFeedMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ComposerWorldHeader(
                      glyph: ctx.activeMode.glyph,
                      modeLabel: ctx.activeMode.label,
                      contextLabel: ctx.activePermissions.interaction.label,
                      postType: _postType,
                      mood: _selectedMood,
                    ),
                    const SizedBox(height: 16),
                    TruLuraGlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          TruLuraIcon(
                              glyph: ctx.activeMode.glyph,
                              size: 18,
                              active: true,
                              color: TruLuraTokens.textPrimary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Posting in ${ctx.activeMode.label} • ${ctx.activePermissions.interaction.label} context',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (ui == TruUiState.empty) ...[
                      TruStatePanel(
                        glyph: TruLuraGlyph.edit,
                        title: 'Your first post sets the tone',
                        message:
                            'Pick a vibe, write one honest line, or open Vent for a protected release. You can post anonymously when it matters.',
                        actions: [
                          TruStateAction(
                            label: 'Pick your vibe',
                            glyph: TruLuraGlyph.spark,
                            onTap: () {
                              setState(() {
                                _postType = 'Mood';
                                _selectedMood ??= _moods.first;
                              });
                            },
                            primary: true,
                          ),
                          TruStateAction(
                            label: 'Open Vent mode',
                            glyph: TruLuraGlyph.shield,
                            onTap: () => setState(() {
                              _postType = 'Vent';
                              _privacy = 'Private';
                              _isAnonymous = true;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (ui == TruUiState.loading) ...[
                      TruShimmer(
                        child: Column(
                          children: const [
                            TruSkeletonBox(
                                width: double.infinity, height: 44, radius: 18),
                            SizedBox(height: 14),
                            TruSkeletonBox(
                                width: double.infinity,
                                height: 170,
                                radius: 18),
                            SizedBox(height: 14),
                            TruSkeletonBox(
                                width: double.infinity, height: 44, radius: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ] else if (_contentController.text.trim().isEmpty &&
                        _selectedMood == null) ...[
                      TruLuraGlassCard(
                        radius: 22,
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _postType == 'Vent'
                              ? 'This space is for honest release — share what you’re feeling. You can stay anonymous.'
                              : 'What’s on your mind today? Try a mood tag + one real sentence.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.45),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_postType == 'Vent') ...[
                      const TruInlineBanner(
                          glyph: TruLuraGlyph.shield,
                          text:
                              'Anonymous Vent • Your identity stays private in this space.'),
                      const SizedBox(height: 14),
                    ],
                    _ComposerCanvas(
                      accent: _postType == 'Vent'
                          ? TruLuraTokens.auraCyan
                          : (_selectedMood == 'Energetic'
                              ? TruLuraBrandColors.glowGold
                              : TruLuraTokens.auraPink),
                      quiet: _postType == 'Vent',
                      child: TruluraPostComposer(
                        contentController: _contentController,
                        captionController: _captionController,
                        postType: _postType,
                        format: _format,
                        privacy: _privacy,
                        selectedMood: _selectedMood,
                        isAnonymous: _isAnonymous,
                        isPosting: _isPosting || ui == TruUiState.loading,
                        mediaStubAttached: _mediaStubAttached,
                        textTemplate: _textTemplate,
                        textStyle: _textStyle,
                        textBackground: _textBackground,
                        errorText: _errorText,
                        moods: _moods,
                        onPostTypeChanged: (type) {
                          setState(() {
                            _postType = type;
                            _errorText = null;
                            if (type == 'Vent') {
                              _privacy = 'Private';
                              _isAnonymous = true;
                            }
                          });
                        },
                        onFormatChanged: (format) {
                          setState(() {
                            _format = format;
                            _errorText = null;
                          });
                        },
                        onPrivacyChanged: (value) =>
                            setState(() => _privacy = value),
                        onTemplateChanged: _applyTemplate,
                        onTextStyleChanged: (value) =>
                            setState(() => _textStyle = value),
                        onTextBackgroundChanged: (value) =>
                            setState(() => _textBackground = value),
                        onMoodChanged: (value) =>
                            setState(() => _selectedMood = value),
                        onAnonymousChanged: (value) =>
                            setState(() => _isAnonymous = value),
                        onToggleMediaStub: () => setState(
                            () => _mediaStubAttached = !_mediaStubAttached),
                        onSubmit: (_isPosting || ui == TruUiState.loading)
                            ? null
                            : _createPost,
                        onContentChanged: () => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerWorldHeader extends StatelessWidget {
  final TruLuraGlyph glyph;
  final String modeLabel;
  final String contextLabel;
  final String postType;
  final String? mood;

  const _ComposerWorldHeader({
    required this.glyph,
    required this.modeLabel,
    required this.contextLabel,
    required this.postType,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    final accent = postType == 'Vent'
        ? TruLuraTokens.auraCyan
        : mood == 'Energetic'
            ? TruLuraBrandColors.glowGold
            : TruLuraTokens.auraPink;
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.16),
                TruLuraTokens.deepIndigo.withValues(alpha: 0.34),
                Colors.black.withValues(alpha: 0.24),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: TruLuraSurfaces.hairline,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.24),
                blurRadius: 54,
                spreadRadius: -24,
                offset: const Offset(0, 28),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -34,
                top: -40,
                width: 180,
                height: 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.34),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.42),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: TruLuraIcon(
                          glyph: glyph,
                          size: 28,
                          active: true,
                          color: TruLuraTokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compose the atmosphere',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$modeLabel layer - $contextLabel context',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: TruLuraTokens.textSecondary,
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ComposerAtmosphereChip(label: postType),
                              if (mood != null)
                                _ComposerAtmosphereChip(label: mood!),
                              const _ComposerAtmosphereChip(
                                label: 'soft signal',
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _ComposerAtmosphereChip extends StatelessWidget {
  final String label;

  const _ComposerAtmosphereChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.065),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: TruLuraSurfaces.hairline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TruLuraTokens.textPrimary,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _ComposerCanvas extends StatelessWidget {
  final Color accent;
  final bool quiet;
  final Widget child;

  const _ComposerCanvas({
    required this.accent,
    required this.quiet,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: quiet ? 0.035 : 0.055),
                  accent.withValues(alpha: quiet ? 0.055 : 0.095),
                  Colors.black.withValues(alpha: quiet ? 0.28 : 0.20),
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: quiet ? 0.18 : 0.26),
                width: TruLuraSurfaces.hairline,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.42),
                  blurRadius: 46,
                  spreadRadius: -22,
                  offset: const Offset(0, 30),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: quiet ? 0.16 : 0.25),
                  blurRadius: 70,
                  spreadRadius: -30,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -70,
                  top: 80,
                  width: 210,
                  height: 210,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: quiet ? 0.14 : 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
