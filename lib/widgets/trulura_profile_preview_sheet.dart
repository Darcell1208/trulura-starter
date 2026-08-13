import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/models/profile/compatibility_report.dart';
import 'package:trulura/services/compatibility_service.dart';
import 'package:trulura/services/connection_service.dart';
import 'package:trulura/services/reporting_service.dart';
import 'package:trulura/services/safety_center_service.dart';
import 'package:trulura/services/safety_meter_service.dart';
import 'package:trulura/theme.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/widgets/trulura_glass_card.dart';
import 'package:trulura/widgets/trulura_halo_avatar.dart';
import 'package:trulura/widgets/trulura_icon.dart';
import 'package:trulura/widgets/trulura_safety_meter_pill.dart';

class TruluraProfilePreviewSheet {
  static Future<void> show(
      {required BuildContext context,
      required String userId,
      User? user,
      required bool isAnonymous,
      required String displayName,
      String? profileImage}) async {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final compat = CompatibilityService();
    final graph = ConnectionService();
    final viewer =
        user; // best-effort: in feed we only reliably have inline user or current cached user.
    final report = (viewer != null)
        ? compat.buildSelfReport(
            viewer: viewer, context: viewer.activeIdentityMode)
        : null;
    final isFollowing = !isAnonymous ? await graph.isFollowing(userId) : false;
    final hasSparked = !isAnonymous ? await graph.hasSparked(userId) : false;
    final safetyPrefs = await SafetyCenterService().getPrefs();
    final canSpark = safetyPrefs.allowNonMutualSparks || isFollowing;
    final reporting = ReportingService();
    final isBlocked = !isAnonymous ? await reporting.isBlocked(userId) : false;
    final meter = const SafetyMeterService().meterForUser(user);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TruLuraGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(16),
              depth: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TruLuraHaloAvatar(
                        radius: 26,
                        image: (profileImage != null &&
                                profileImage.trim().isNotEmpty)
                            ? NetworkImage(profileImage)
                            : null,
                        fallback: const TruLuraIcon(
                            glyph: TruLuraGlyph.person, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAnonymous
                                  ? 'Anonymous'
                                  : User.publicDisplayNameFrom(
                                      displayName,
                                      email: user?.email,
                                      fallback: 'New member',
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAnonymous
                                  ? 'Identity protected in this space'
                                  : (user?.bio ?? 'Tap to preview profile'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.72),
                                  height: 1.3),
                            ),
                            if (!isAnonymous) ...[
                              const SizedBox(height: 8),
                              TruLuraSafetyMeterPill(
                                meter: meter,
                                onTap: safetyPrefs.showSafetyMeterDetails
                                    ? () {
                                        context.pop();
                                        context
                                            .push(AppRoutes.safetyVerification);
                                      }
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
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
                  const SizedBox(height: 14),
                  if (report != null && !isAnonymous) ...[
                    _CompatibilityMini(report: report),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _SheetAction(
                          glyph: TruLuraGlyph.spark,
                          label: 'Glow',
                          onTap: (isAnonymous || isBlocked)
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Glow sent.')));
                                  context.pop();
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SheetAction(
                          glyph: TruLuraGlyph.heartOutline,
                          label: hasSparked ? 'Sparked' : 'Spark',
                          onTap: (isAnonymous || isBlocked || !canSpark)
                              ? null
                              : () {
                                  unawaited(graph.sendSpark(userId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Spark sent.')));
                                  context.pop();
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SheetAction(
                          glyph: TruLuraGlyph.postPlus,
                          label: isFollowing ? 'Following' : 'Follow',
                          onTap: (isAnonymous || isBlocked)
                              ? null
                              : () {
                                  unawaited(graph.toggleFollow(userId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(isFollowing
                                              ? 'Unfollowed.'
                                              : 'Followed.')));
                                  context.pop();
                                },
                        ),
                      ),
                    ],
                  ),
                  if (!isAnonymous) ...[
                    const SizedBox(height: 12),
                    if (!canSpark) ...[
                      Text(
                        'Spark is gated by your Safety Center: turn on “non-mutual sparks” or follow first.',
                        style: t.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.72),
                            height: 1.3),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _SheetAction(
                            glyph: TruLuraGlyph.close,
                            label: isBlocked ? 'Blocked' : 'Block',
                            onTap: () async {
                              await reporting.blockUser(userId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('User blocked.')));
                              }
                              if (context.mounted) context.pop();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SheetAction(
                            glyph: TruLuraGlyph.info,
                            label: 'Report',
                            onTap: () {
                              context.pop();
                              context.push(
                                  '${AppRoutes.report}?type=user&id=${Uri.encodeComponent(userId)}');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!isAnonymous) ...[
                    const SizedBox(height: 12),
                    _SheetAction(
                      glyph: TruLuraGlyph.chevronRight,
                      label: 'Open profile',
                      fullWidth: true,
                      onTap: () {
                        context.pop();
                        context.push(
                            '/p?title=${Uri.encodeComponent(displayName)}&subtitle=${Uri.encodeComponent('Profile preview (stub)')}');
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompatibilityMini extends StatelessWidget {
  final TruCompatibilityReport report;
  const _CompatibilityMini({required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: TruLuraSurfaces.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: TruLuraTokens.auraGradient(opacity: 0.95),
              boxShadow: TruLuraTokens.softGlow(TruLuraTokens.auraViolet)
                  .map(
                      (s) => s.copyWith(color: s.color.withValues(alpha: 0.18)))
                  .toList(),
            ),
            child: Center(
              child: Text(_rhythmLabel(report.overall),
                  style: t.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emotional rhythm',
                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'There may be a gentle movement between emotional, intellectual, visual, cultural, and lifestyle layers.',
                  style: t.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.72), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _rhythmLabel(int score) {
    if (score >= 82) return 'deep';
    if (score >= 68) return 'warm';
    return 'open';
  }
}

class _SheetAction extends StatelessWidget {
  final TruLuraGlyph glyph;
  final String label;
  final VoidCallback? onTap;
  final bool fullWidth;

  const _SheetAction(
      {required this.glyph,
      required this.label,
      required this.onTap,
      this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final disabled = onTap == null;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest
            .withValues(alpha: disabled ? 0.25 : 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: TruLuraSurfaces.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TruLuraIcon(
              glyph: glyph,
              size: 18,
              active: !disabled,
              color: disabled
                  ? cs.onSurface.withValues(alpha: 0.35)
                  : cs.onSurface),
          const SizedBox(width: 8),
          Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: disabled
                          ? cs.onSurface.withValues(alpha: 0.35)
                          : cs.onSurface))),
        ],
      ),
    );
    if (fullWidth) {
      return GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
    }
    return GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
  }
}
