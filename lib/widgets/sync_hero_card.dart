import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/aura_state.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/tag_pill.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_halo_avatar.dart';
import 'package:trulura/widgets/trulura_secondary_buttons.dart';

/// Sync Mode hero profile card.
///
/// This matches the locked Sync visual language: pink-led glass glow,
/// halo avatar with % match badge, trait pills, and Pass/Connect actions.
class SyncHeroCard extends StatelessWidget {
  /// New (palette-driven) API: when this is non-null, the widget renders the
  /// locked palette-based layout.
  final TruLuraMode? mode;

  /// Optional avatar image (used by the legacy Sync layout).
  final ImageProvider<Object>? image;
  final String name;
  final int age;

  /// Legacy compatibility percent (used by the legacy Sync layout).
  final int? match;

  /// New API compatibility percent (preferred when [mode] is provided).
  final int? percent;

  /// Optional short label shown under the title in the palette-driven layout.
  final String? headline;

  /// Legacy bio field.
  final String? bio;

  /// New API bio field (preferred when [mode] is provided).
  final String? bioLine;

  /// Optional distance line. Used in both layouts when provided.
  final String? distance;
  final VoidCallback? onPass;
  final VoidCallback? onConnect;
  final VoidCallback? onGlow;
  final VoidCallback? onHelp;

  /// Optional label override for the CONNECT button.
  final String connectLabel;

  /// Optional label override for the Glow button.
  final String glowLabel;

  /// Interaction map hooks.
  final VoidCallback? onTapProfile;
  final VoidCallback? onTapCompatibility;

  /// New (palette-driven) API fields.
  final List<String>? tags;

  const SyncHeroCard({
    super.key,
    this.mode,
    this.image,
    required this.name,
    required this.age,
    this.match,
    this.percent,
    this.headline,
    this.bio,
    this.bioLine,
    this.distance,
    this.tags,
    this.onPass,
    this.onConnect,
    this.onGlow,
    this.onHelp,
    this.connectLabel = 'CONNECT',
    this.glowLabel = 'GLOW',
    this.onTapProfile,
    this.onTapCompatibility,
  });

  /// Palette-driven constructor that matches your latest snippet.
  const SyncHeroCard.locked({
    super.key,
    required this.mode,
    required this.name,
    required this.age,
    required this.percent,
    required this.bio,
    required this.tags,
    required this.onConnect,
    this.onGlow,
    required this.onPass,
    this.connectLabel = 'CONNECT',
    this.glowLabel = 'GLOW',
    this.onTapProfile,
    this.onTapCompatibility,
  })  : headline = null,
        bioLine = null,
        image = null,
        match = null,
        distance = null,
        onHelp = null;

  @override
  Widget build(BuildContext context) {
    final auraGlow = context.watch<AuraStateController>().auraColor;

    if (mode != null) {
          final p = kTruLuraPalettes[mode!]!;
          final computedPercent = (percent ?? match ?? 0).clamp(0, 100);
          final computedBio = (bioLine ?? bio ?? '').trim();
          final ImageProvider<Object> avatar =
              image ??
              const AssetImage(
                'assets/images/portrait_young_woman_smiling_null_1772162274859.jpg',
              );

          return TruLuraGlassCard(
            mode: mode,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    (Color.lerp(p.glowB, auraGlow, 0.55) ??
                                            auraGlow)
                                        .withValues(alpha: 0.25),
                                    (Color.lerp(p.glowA, auraGlow, 0.35) ??
                                            auraGlow)
                                        .withValues(alpha: 0.10),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onTapProfile,
                        child: TruLuraHaloAvatar(
                          radius: 54,
                          image: avatar,
                          tone: TruLuraModeTone.sync,
                          matchPercent: computedPercent / 100.0,
                          matched: computedPercent >= 90,
                        ),
                      ),
                      Positioned(
                        right: -12,
                        bottom: -14,
                        child: _PercentBadge(
                          mode: mode!,
                          percent: computedPercent,
                          onTap: onTapCompatibility ?? onHelp,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$name, $age',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: p.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                      ),
                    ),
                    if (onHelp != null) ...[
                      IconButton(
                        onPressed: onHelp,
                        tooltip: 'Help',
                        icon:
                            Icon(Icons.help_outline_rounded, color: p.text),
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
                if ((headline ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    headline!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: p.text,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
                if (computedBio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    computedBio,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: p.muted,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                if ((distance ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: p.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          distance!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: p.muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (tags ?? const <String>[])
                      .map((t) => _SegmentPill(mode: mode!, label: t))
                      .toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryButton(
                        mode: mode!,
                        label: 'PASS',
                        icon: Icons.close_rounded,
                        onTap: onPass,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SecondaryButton(
                        mode: mode!,
                        label: glowLabel,
                        icon: Icons.emoji_emotions_rounded,
                        onTap: onGlow,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TruluraActionButton(
                        mode: mode,
                        label: connectLabel,
                        onTap: onConnect,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

    final legacyMatch = (match ?? percent ?? 0).clamp(0, 100);
    final legacyBio = (bio ?? bioLine ?? '').trim();
    final legacyDistance = (distance ?? '').trim();

    return TruLuraGlassCard(
          tone: TruLuraModeTone.sync,
          glow: Color.lerp(TruLuraTokens.auraPink, auraGlow, 0.55),
          radius: TruLuraTokens.r24,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TruLuraHaloAvatar(
                    radius: 41,
                    image: image,
                    tone: TruLuraModeTone.sync,
                    matchPercent: legacyMatch / 100.0,
                    matched: legacyMatch >= 90,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name, $age',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: TruLuraTokens.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$legacyMatch% • Highly compatible',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: TruLuraTokens.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          legacyBio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: TruLuraTokens.textMuted,
                                    height: 1.25,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: TruLuraTokens.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                legacyDistance,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: TruLuraTokens.textMuted,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  TagPill(icon: Icons.auto_awesome, text: 'Intent Alignment'),
                  TagPill(
                    icon: Icons.psychology_alt_outlined,
                    text: 'Valuing depth',
                  ),
                  TagPill(icon: Icons.link, text: 'Seeking long-term'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryGlassButton(
                      text: 'PASS',
                      icon: Icons.close,
                      onTap: onPass,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      radius: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryGlassButton(
                      text: glowLabel,
                      icon: Icons.emoji_emotions,
                      onTap: onGlow,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      radius: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ConnectButton(
                      text: connectLabel,
                      icon: Icons.favorite,
                      onTap: onConnect,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      radius: 18,
                      glowColor: Color.lerp(
                            TruLuraTokens.auraPink,
                            auraGlow,
                            0.55,
                          ) ??
                          TruLuraTokens.auraPink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
  }
}

class _PercentBadge extends StatelessWidget {
  final TruLuraMode mode;
  final int percent;
  final VoidCallback? onTap;

  const _PercentBadge({
    required this.mode,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    return _InteractivePercentBadge(p: p, percent: percent, onTap: onTap);
  }
}

class _InteractivePercentBadge extends StatefulWidget {
  final TruLuraPalette p;
  final int percent;
  final VoidCallback? onTap;

  const _InteractivePercentBadge({
    required this.p,
    required this.percent,
    required this.onTap,
  });

  @override
  State<_InteractivePercentBadge> createState() =>
      _InteractivePercentBadgeState();
}

class _InteractivePercentBadgeState extends State<_InteractivePercentBadge> {
  bool _hover = false;
  bool _pressed = false;

  void _setHover(bool value) {
    if (!mounted) return;
    setState(() => _hover = value);
  }

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final enabled = widget.onTap != null;
    final scale = _pressed
        ? 0.97
        : (_hover && enabled)
            ? 1.03
            : 1.0;

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) {
        _setHover(false);
        _setPressed(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [p.glowA, p.glowB]),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: (_hover && enabled) ? 0.22 : 0.14,
                ),
                width: TruLuraSurfaces.hairline,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 14,
                  spreadRadius: -8,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: p.glowB.withValues(
                    alpha: (_hover && enabled) ? 0.72 : 0.60,
                  ),
                  blurRadius: (_hover && enabled) ? 18 : 14,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Text(
              '${widget.percent}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final TruLuraMode mode;
  final String label;

  const _SegmentPill({required this.mode, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.18),
        border: Border.all(color: p.border, width: TruLuraSurfaces.hairline),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: p.text,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final TruLuraMode mode;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SecondaryButton({
    required this.mode,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    final disabled = onTap == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 140),
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: 46,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: 0.20),
              border: Border.all(color: p.border),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: p.text),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(color: p.text, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
