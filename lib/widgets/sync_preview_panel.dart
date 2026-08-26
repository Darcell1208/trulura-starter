import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/aura_state.dart';
import 'package:trulura/trulura_mode.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_safe_avatar.dart';

class SyncPreviewPanel extends StatelessWidget {
  final TruLuraMode mode;

  // UI state
  final TextEditingController controller;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  // Data
  final List<MiniProfile> profiles;
  final ValueChanged<MiniProfile> onTapProfile;

  const SyncPreviewPanel({
    super.key,
    required this.mode,
    required this.controller,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.profiles,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;

    return TruLuraGlassCard(
      mode: mode,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Discovery',
                style: TextStyle(
                    color: p.text,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    fontSize: 14),
              ),
              const Spacer(),
              _GhostChip(
                  mode: mode,
                  icon: Icons.tune_rounded,
                  label: 'FILTERS',
                  onTap: () {}),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _SearchField(
                      mode: mode,
                      controller: controller,
                      hint: 'Search people, signals...',
                      onChanged: onSearchChanged)),
              const SizedBox(width: 10),
              _IconButtonGlass(
                  mode: mode,
                  icon: Icons.search_rounded,
                  onTap: () => onSearchChanged(controller.text)),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final selected = f == selectedFilter;
                return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                        mode: mode,
                        label: f,
                        selected: selected,
                        onTap: () => onFilterChanged(f)));
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final m = profiles[i];
                return MiniProfileCard(
                    mode: mode, model: m, onTap: () => onTapProfile(m));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MiniProfile {
  final String name;
  final int match;
  final String descriptor;
  final ImageProvider avatar;

  const MiniProfile(
      {required this.name,
      required this.match,
      required this.descriptor,
      required this.avatar});
}

class MiniProfileCard extends StatelessWidget {
  final TruLuraMode mode;
  final MiniProfile model;
  final VoidCallback onTap;

  const MiniProfileCard(
      {super.key,
      required this.mode,
      required this.model,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;

    final auraGlow = context.watch<AuraStateController>().auraColor;
    final blendedGlow = Color.lerp(p.glowB, auraGlow, 0.45) ?? auraGlow;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Stack(
          children: [
            TruLuraGlassCard(
              mode: mode,
              radius: 18,
              padding: const EdgeInsets.all(12),
              glow: blendedGlow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MiniAvatar(mode: mode, image: model.avatar),
                      const Spacer(),
                      _MiniPercent(mode: mode, percent: model.match),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    model.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: p.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      model.descriptor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: p.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          height: 1.25),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -18,
              top: -18,
              child: IgnorePointer(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        blendedGlow.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final TruLuraMode mode;
  final ImageProvider image;
  const _MiniAvatar({required this.mode, required this.image});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [p.glowA, p.glowB]),
        boxShadow: [
          BoxShadow(
              blurRadius: 14,
              spreadRadius: -6,
              color: p.glowA.withValues(alpha: 0.35),
              offset: const Offset(0, 10))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.2),
        child: TruLuraSafeAvatar(
            radius: 15,
            image: image,
            fallback: const Icon(Icons.person, size: 14)),
      ),
    );
  }
}

class _MiniPercent extends StatelessWidget {
  final TruLuraMode mode;
  final int percent;
  const _MiniPercent({required this.mode, required this.percent});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [p.glowA, p.glowB])),
      child: Text('$percent%',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TruLuraMode mode;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField(
      {required this.mode,
      required this.controller,
      required this.hint,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: p.card.withValues(alpha: 0.18),
        border: Border.all(color: p.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: p.text, fontWeight: FontWeight.w700),
        cursorColor: p.glowB,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          hintText: hint,
          hintStyle: TextStyle(
              color: p.muted.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final TruLuraMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.mode,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? LinearGradient(
                  begin: const Alignment(-1, -1),
                  end: const Alignment(1, 1),
                  colors: [p.glowB, p.glowA])
              : null,
          color: selected ? null : p.card.withValues(alpha: 0.14),
          border: Border.all(
              color:
                  selected ? Colors.white.withValues(alpha: 0.12) : p.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: p.glowB.withValues(alpha: 0.28),
                    blurRadius: 18,
                    spreadRadius: -6,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [],
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : p.text,
                fontWeight: FontWeight.w900,
                fontSize: 11.5)),
      ),
    );
  }
}

class _IconButtonGlass extends StatelessWidget {
  final TruLuraMode mode;
  final IconData icon;
  final VoidCallback onTap;

  const _IconButtonGlass(
      {required this.mode, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              p.card.withValues(alpha: 0.22),
              p.card.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(color: p.border),
        ),
        child: Icon(icon, color: p.text, size: 20),
      ),
    );
  }
}

class _GhostChip extends StatelessWidget {
  final TruLuraMode mode;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GhostChip(
      {required this.mode,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = kTruLuraPalettes[mode]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.black.withValues(alpha: 0.20),
          border: Border.all(color: p.border.withValues(alpha: 0.85)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: p.muted),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: p.muted, fontWeight: FontWeight.w900, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
