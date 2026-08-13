
import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/theme.dart';

/// TruLura locked icon kit.
///
/// Rules enforced:
/// - No Material Icons usage (stroke-based CustomPaint glyphs)
/// - Consistent stroke weight + neon-glass depth
/// - Soft Mode dulls icons (reduced glow + no bloom)
enum TruLuraGlyph {
  aura,
  sync,
  explore,
  messages,
  postPlus,
  moon,
  menu,
  close,
  chevronRight,
  back,
  search,
  filter,
  heart,
  heartOutline,
  person,
  at,
  edit,
  check,
  circle,
  tv,
  video,
  groups,
  shield,
  lock,
  help,
  info,
  logout,
  bookmark,
  insights,
  star,
  spark,
  more,
  share,
  image,
  inbox,
  battery,
  batteryCharging,
  send,
  pin,
  cake,
}

class TruLuraIcon extends StatelessWidget {
  final TruLuraGlyph glyph;
  final double size;

  /// When true, renders with the brighter active glow.
  final bool active;

  /// Optional explicit color. If null, uses [IconTheme] color.
  final Color? color;

  /// Optional asset-based icon path.
  ///
  /// This lets you use the exact concept PNG/SVG-rendered-to-PNG icons while
  /// keeping the existing CustomPaint glyph system as a fallback.
  final String? assetPath;

  const TruLuraIcon({super.key, required this.glyph, this.size = 22, this.active = false, this.color, this.assetPath});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final soft = app.softModeEnabled;
    final baseColor = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    final glow = soft ? 0.0 : (active ? 1.0 : 0.55) * app.glowScale;
    final alpha = soft ? (active ? 0.82 : 0.70) : 1.0;

    final cs = Theme.of(context).colorScheme;
    final glowA = TruLuraBrandColors.neonPurple;
    final glowB = TruLuraBrandColors.sparkMagenta;

    if (assetPath != null) {
      return _TruLuraAssetIcon(
        assetPath: assetPath!,
        size: size,
        active: active,
        soft: soft,
        glowScale: app.glowScale,
        tint: baseColor.withValues(alpha: alpha),
        glowA: glowA,
        glowB: glowB,
      );
    }

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _TruLuraIconPainter(glyph: glyph, color: baseColor.withValues(alpha: alpha), glowIntensity: glow, glowA: glowA, glowB: glowB, surfaceTint: cs.surface),
      ),
    );
  }
}

class _TruLuraAssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final bool active;
  final bool soft;
  final double glowScale;
  final Color tint;
  final Color glowA;
  final Color glowB;

  const _TruLuraAssetIcon({required this.assetPath, required this.size, required this.active, required this.soft, required this.glowScale, required this.tint, required this.glowA, required this.glowB});

  @override
  Widget build(BuildContext context) {
    final glow = soft ? 0.0 : (active ? 1.0 : 0.55) * glowScale;

    // If the asset is already pre-colored (as in your concept set), we avoid
    // forcing a tint; we just add glow + subtle fade in Soft Mode.
    final opacity = soft ? (active ? 0.82 : 0.70) : 1.0;

    return RepaintBoundary(
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            boxShadow: glow <= 0
                ? null
                : [
                    BoxShadow(color: glowA.withValues(alpha: 0.26 * glow), blurRadius: 16 * glow, spreadRadius: 0),
                    BoxShadow(color: glowB.withValues(alpha: 0.20 * glow), blurRadius: 24 * glow, spreadRadius: 0),
                  ],
          ),
          child: Image.asset(assetPath, width: size, height: size, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _TruLuraIconPainter extends CustomPainter {
  final TruLuraGlyph glyph;
  final Color color;
  final double glowIntensity;
  final Color glowA;
  final Color glowB;
  final Color surfaceTint;

  const _TruLuraIconPainter({required this.glyph, required this.color, required this.glowIntensity, required this.glowA, required this.glowB, required this.surfaceTint});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final sw = (s / 12).clamp(1.4, 2.6);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = sw
      ..color = color;

    Path? path;
    final paths = <Path>[];
    void add(Path p) => paths.add(p);

    switch (glyph) {
      case TruLuraGlyph.aura:
        add(_planet(size));
        add(_orbit(size));
        add(_sparkDot(size, const Offset(0.70, 0.28), r: 0.05));
        break;
      case TruLuraGlyph.sync:
        add(_infinity(size));
        add(_miniHeart(size));
        break;
      case TruLuraGlyph.explore:
        add(_swirl(size));
        add(_sparkDot(size, const Offset(0.74, 0.28), r: 0.045));
        break;
      case TruLuraGlyph.messages:
        add(_chatBubble(size));
        break;
      case TruLuraGlyph.postPlus:
        add(_plus(size));
        break;
      case TruLuraGlyph.moon:
        path = _crescent(size);
        break;
      case TruLuraGlyph.menu:
        add(_menu(size));
        break;
      case TruLuraGlyph.close:
        add(_close(size));
        break;
      case TruLuraGlyph.chevronRight:
        add(_chevronRight(size));
        break;
      case TruLuraGlyph.back:
        add(_back(size));
        break;
      case TruLuraGlyph.search:
        add(_search(size));
        break;
      case TruLuraGlyph.filter:
        add(_filter(size));
        break;
      case TruLuraGlyph.heart:
        path = _heart(size);
        break;
      case TruLuraGlyph.heartOutline:
        add(_heartOutline(size));
        break;
      case TruLuraGlyph.person:
        add(_person(size));
        break;
      case TruLuraGlyph.at:
        add(_at(size));
        break;
      case TruLuraGlyph.edit:
        add(_edit(size));
        break;
      case TruLuraGlyph.check:
        add(_check(size));
        break;
      case TruLuraGlyph.circle:
        add(_circle(size));
        break;
      case TruLuraGlyph.tv:
        add(_tv(size));
        break;
      case TruLuraGlyph.video:
        add(_video(size));
        break;
      case TruLuraGlyph.groups:
        add(_groups(size));
        break;
      case TruLuraGlyph.shield:
        add(_shield(size));
        break;
      case TruLuraGlyph.lock:
        add(_lock(size));
        break;
      case TruLuraGlyph.help:
        add(_help(size));
        break;
      case TruLuraGlyph.info:
        add(_info(size));
        break;
      case TruLuraGlyph.logout:
        add(_logout(size));
        break;
      case TruLuraGlyph.bookmark:
        add(_bookmark(size));
        break;
      case TruLuraGlyph.insights:
        add(_insights(size));
        break;
      case TruLuraGlyph.star:
        add(_star(size));
        break;
      case TruLuraGlyph.spark:
        add(_spark(size));
        break;
      case TruLuraGlyph.more:
        add(_more(size));
        break;
      case TruLuraGlyph.share:
        add(_share(size));
        break;
      case TruLuraGlyph.image:
        add(_image(size));
        break;
      case TruLuraGlyph.inbox:
        add(_inbox(size));
        break;
      case TruLuraGlyph.battery:
        add(_battery(size, charging: false));
        break;
      case TruLuraGlyph.batteryCharging:
        add(_battery(size, charging: true));
        break;
      case TruLuraGlyph.send:
        add(_send(size));
        break;
      case TruLuraGlyph.pin:
        add(_pin(size));
        break;
      case TruLuraGlyph.cake:
        add(_cake(size));
        break;
    }

    final Path? single = path;
    final drawStroke = single == null ? paths : <Path>[single];
    if (glowIntensity > 0.01) {
      // Glass-neon glow system: inner bloom + outer halo.
      // We do not rely on flat white. Glow is tinted by TruLura tokens.
      final inner = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = sw
        ..color = (Color.lerp(glowA, glowB, 0.35) ?? glowA).withValues(alpha: (0.22 * glowIntensity).clamp(0.0, 0.32))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (s / 10.5) * glowIntensity);

      final outer = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = sw
        ..color = (Color.lerp(glowB, glowA, 0.55) ?? glowB).withValues(alpha: (0.16 * glowIntensity).clamp(0.0, 0.26))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (s / 4.6) * glowIntensity);

      for (final p in drawStroke) {
        canvas.drawPath(p, outer);
        canvas.drawPath(p, inner);
      }

      // Subtle inner bloom (fill-ish) for “glassy” depth.
      final bloom = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = sw * 0.75
        ..color = surfaceTint.withValues(alpha: (0.10 * glowIntensity).clamp(0.0, 0.16))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (s / 16.0) * glowIntensity);
      for (final p in drawStroke) {
        canvas.drawPath(p, bloom);
      }
    }

    if (path != null) {
      // Some icons look better slightly filled (moon/heart), but still thin.
      if (glyph == TruLuraGlyph.moon) {
        canvas.drawPath(path, stroke);
      } else if (glyph == TruLuraGlyph.heart) {
        final heartFill = Paint()..color = color.withValues(alpha: 0.90);
        canvas.drawPath(path, heartFill);
      } else {
        canvas.drawPath(path, stroke);
      }
      return;
    }

    for (final p in paths) {
      canvas.drawPath(p, stroke);
    }
  }

  // ========================
  // Locked kit glyphs
  // ========================

  Path _planet(Size size) {
    final r = size.shortestSide * 0.22;
    final c = Offset(size.width * 0.48, size.height * 0.52);
    return Path()..addOval(Rect.fromCircle(center: c, radius: r));
  }

  Path _orbit(Size size) {
    final rect = Rect.fromCenter(center: Offset(size.width * 0.52, size.height * 0.50), width: size.width * 0.86, height: size.height * 0.48);
    final p = Path()..addOval(rect);
    // Clip the orbit so it feels like it passes behind the planet.
    final planet = Path()..addOval(Rect.fromCircle(center: Offset(size.width * 0.48, size.height * 0.52), radius: size.shortestSide * 0.22));
    return Path.combine(PathOperation.difference, p, planet);
  }

  Path _infinity(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.moveTo(w * 0.18, h * 0.52);
    p.cubicTo(w * 0.22, h * 0.30, w * 0.44, h * 0.30, w * 0.50, h * 0.52);
    p.cubicTo(w * 0.56, h * 0.74, w * 0.78, h * 0.74, w * 0.82, h * 0.52);
    p.cubicTo(w * 0.78, h * 0.30, w * 0.56, h * 0.30, w * 0.50, h * 0.52);
    p.cubicTo(w * 0.44, h * 0.74, w * 0.22, h * 0.74, w * 0.18, h * 0.52);
    return p;
  }

  Path _miniHeart(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    final cx = w * 0.64;
    final cy = h * 0.62;
    final s = size.shortestSide * 0.12;
    p.moveTo(cx, cy + s * 0.55);
    p.cubicTo(cx - s * 1.2, cy, cx - s * 0.6, cy - s * 1.1, cx, cy - s * 0.35);
    p.cubicTo(cx + s * 0.6, cy - s * 1.1, cx + s * 1.2, cy, cx, cy + s * 0.55);
    p.close();
    return p;
  }

  Path _swirl(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.moveTo(w * 0.78, h * 0.42);
    p.cubicTo(w * 0.70, h * 0.20, w * 0.38, h * 0.22, w * 0.30, h * 0.44);
    p.cubicTo(w * 0.20, h * 0.70, w * 0.52, h * 0.84, w * 0.70, h * 0.66);
    p.cubicTo(w * 0.86, h * 0.50, w * 0.56, h * 0.38, w * 0.46, h * 0.54);
    return p;
  }

  Path _chatBubble(Size size) {
    final r = size.shortestSide * 0.20;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.18, size.height * 0.22, size.width * 0.64, size.height * 0.50), Radius.circular(r));
    final p = Path()..addRRect(rect);
    p.moveTo(size.width * 0.44, size.height * 0.72);
    p.lineTo(size.width * 0.36, size.height * 0.84);
    p.lineTo(size.width * 0.58, size.height * 0.72);
    return p;
  }

  Path _plus(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.moveTo(w * 0.50, h * 0.22);
    p.lineTo(w * 0.50, h * 0.78);
    p.moveTo(w * 0.22, h * 0.50);
    p.lineTo(w * 0.78, h * 0.50);
    return p;
  }

  Path _crescent(Size size) {
    final outer = Path()..addOval(Rect.fromCircle(center: Offset(size.width * 0.50, size.height * 0.50), radius: size.shortestSide * 0.30));
    final inner = Path()..addOval(Rect.fromCircle(center: Offset(size.width * 0.58, size.height * 0.46), radius: size.shortestSide * 0.28));
    return Path.combine(PathOperation.difference, outer, inner);
  }

  // ========================
  // Utility/generic glyphs (same stroke style)
  // ========================

  Path _sparkDot(Size size, Offset unit, {double r = 0.05}) => Path()..addOval(Rect.fromCircle(center: Offset(size.width * unit.dx, size.height * unit.dy), radius: size.shortestSide * r));

  Path _menu(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.22, h * 0.32)
      ..lineTo(w * 0.78, h * 0.32)
      ..moveTo(w * 0.22, h * 0.50)
      ..lineTo(w * 0.78, h * 0.50)
      ..moveTo(w * 0.22, h * 0.68)
      ..lineTo(w * 0.78, h * 0.68);
  }

  Path _close(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.28, h * 0.28)
      ..lineTo(w * 0.72, h * 0.72)
      ..moveTo(w * 0.72, h * 0.28)
      ..lineTo(w * 0.28, h * 0.72);
  }

  Path _chevronRight(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.42, h * 0.28)
      ..lineTo(w * 0.64, h * 0.50)
      ..lineTo(w * 0.42, h * 0.72);
  }

  Path _back(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.64, h * 0.26)
      ..lineTo(w * 0.36, h * 0.50)
      ..lineTo(w * 0.64, h * 0.74);
  }

  Path _search(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(w * 0.46, h * 0.46), radius: size.shortestSide * 0.20));
    p.moveTo(w * 0.60, h * 0.60);
    p.lineTo(w * 0.78, h * 0.78);
    return p;
  }

  Path _filter(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.22, h * 0.30)
      ..lineTo(w * 0.78, h * 0.30)
      ..moveTo(w * 0.32, h * 0.50)
      ..lineTo(w * 0.68, h * 0.50)
      ..moveTo(w * 0.42, h * 0.70)
      ..lineTo(w * 0.58, h * 0.70);
  }

  Path _heart(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.moveTo(w * 0.50, h * 0.78);
    p.cubicTo(w * 0.18, h * 0.60, w * 0.22, h * 0.30, w * 0.40, h * 0.30);
    p.cubicTo(w * 0.46, h * 0.30, w * 0.50, h * 0.36, w * 0.50, h * 0.38);
    p.cubicTo(w * 0.50, h * 0.36, w * 0.54, h * 0.30, w * 0.60, h * 0.30);
    p.cubicTo(w * 0.78, h * 0.30, w * 0.82, h * 0.60, w * 0.50, h * 0.78);
    p.close();
    return p;
  }

  Path _heartOutline(Size size) => _heart(size);

  Path _person(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(w * 0.50, h * 0.40), radius: size.shortestSide * 0.16));
    p.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.58, w * 0.44, h * 0.26), Radius.circular(size.shortestSide * 0.16)));
    return p;
  }

  Path _at(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(w * 0.50, h * 0.50), radius: size.shortestSide * 0.28));
    p.addOval(Rect.fromCircle(center: Offset(w * 0.52, h * 0.52), radius: size.shortestSide * 0.12));
    p.moveTo(w * 0.64, h * 0.66);
    p.cubicTo(w * 0.78, h * 0.64, w * 0.78, h * 0.40, w * 0.66, h * 0.40);
    return p;
  }

  Path _edit(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.26, h * 0.70)
      ..lineTo(w * 0.26, h * 0.78)
      ..lineTo(w * 0.34, h * 0.78)
      ..lineTo(w * 0.76, h * 0.36)
      ..lineTo(w * 0.68, h * 0.28)
      ..close();
  }

  Path _check(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.26, h * 0.54)
      ..lineTo(w * 0.44, h * 0.70)
      ..lineTo(w * 0.76, h * 0.32);
  }

  Path _circle(Size size) => Path()..addOval(Rect.fromCircle(center: Offset(size.width * 0.50, size.height * 0.50), radius: size.shortestSide * 0.28));

  Path _tv(Size size) {
    final r = size.shortestSide * 0.14;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.20, size.height * 0.28, size.width * 0.60, size.height * 0.40), Radius.circular(r));
    final p = Path()..addRRect(rect);
    p.moveTo(size.width * 0.40, size.height * 0.24);
    p.lineTo(size.width * 0.50, size.height * 0.16);
    p.lineTo(size.width * 0.60, size.height * 0.24);
    return p;
  }

  Path _video(Size size) {
    final r = size.shortestSide * 0.14;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.20, size.height * 0.32, size.width * 0.46, size.height * 0.36), Radius.circular(r));
    final p = Path()..addRRect(rect);
    p.moveTo(size.width * 0.66, size.height * 0.40);
    p.lineTo(size.width * 0.82, size.height * 0.32);
    p.lineTo(size.width * 0.82, size.height * 0.68);
    p.lineTo(size.width * 0.66, size.height * 0.60);
    return p;
  }

  Path _groups(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(w * 0.42, h * 0.42), radius: size.shortestSide * 0.12));
    p.addOval(Rect.fromCircle(center: Offset(w * 0.62, h * 0.46), radius: size.shortestSide * 0.10));
    p.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.58, w * 0.44, h * 0.22), Radius.circular(size.shortestSide * 0.12)));
    return p;
  }

  Path _shield(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.moveTo(w * 0.50, h * 0.18);
    p.lineTo(w * 0.78, h * 0.28);
    p.lineTo(w * 0.74, h * 0.62);
    p.cubicTo(w * 0.70, h * 0.76, w * 0.60, h * 0.84, w * 0.50, h * 0.88);
    p.cubicTo(w * 0.40, h * 0.84, w * 0.30, h * 0.76, w * 0.26, h * 0.62);
    p.lineTo(w * 0.22, h * 0.28);
    p.close();
    return p;
  }

  Path _lock(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.30, h * 0.48, w * 0.40, h * 0.32), Radius.circular(size.shortestSide * 0.12)));
    p.moveTo(w * 0.36, h * 0.48);
    p.cubicTo(w * 0.36, h * 0.28, w * 0.64, h * 0.28, w * 0.64, h * 0.48);
    return p;
  }

  Path _help(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(w * 0.50, h * 0.50), radius: size.shortestSide * 0.28));
    p.moveTo(w * 0.44, h * 0.42);
    p.cubicTo(w * 0.44, h * 0.34, w * 0.56, h * 0.34, w * 0.56, h * 0.42);
    p.cubicTo(w * 0.56, h * 0.48, w * 0.50, h * 0.50, w * 0.50, h * 0.56);
    // Draw a real dot (a zero-length segment won't render).
    p.addOval(Rect.fromCircle(center: Offset(w * 0.50, h * 0.70), radius: size.shortestSide * 0.03));
    return p;
  }

  Path _info(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(w * 0.50, h * 0.50), radius: size.shortestSide * 0.28));
    p.moveTo(w * 0.50, h * 0.44);
    p.lineTo(w * 0.50, h * 0.68);
    p.addOval(Rect.fromCircle(center: Offset(w * 0.50, h * 0.32), radius: size.shortestSide * 0.03));
    return p;
  }

  Path _logout(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.26, h * 0.30, w * 0.34, h * 0.40), Radius.circular(size.shortestSide * 0.12)));
    p.moveTo(w * 0.56, h * 0.50);
    p.lineTo(w * 0.80, h * 0.50);
    p.moveTo(w * 0.72, h * 0.40);
    p.lineTo(w * 0.82, h * 0.50);
    p.lineTo(w * 0.72, h * 0.60);
    return p;
  }

  Path _bookmark(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.moveTo(w * 0.34, h * 0.22);
    p.lineTo(w * 0.66, h * 0.22);
    p.lineTo(w * 0.66, h * 0.82);
    p.lineTo(w * 0.50, h * 0.70);
    p.lineTo(w * 0.34, h * 0.82);
    p.close();
    return p;
  }

  Path _insights(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.26, h * 0.70)
      ..lineTo(w * 0.26, h * 0.48)
      ..moveTo(w * 0.44, h * 0.70)
      ..lineTo(w * 0.44, h * 0.36)
      ..moveTo(w * 0.62, h * 0.70)
      ..lineTo(w * 0.62, h * 0.56)
      ..moveTo(w * 0.80, h * 0.70)
      ..lineTo(w * 0.80, h * 0.30);
  }

  Path _star(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.moveTo(w * 0.50, h * 0.22);
    p.lineTo(w * 0.56, h * 0.44);
    p.lineTo(w * 0.78, h * 0.44);
    p.lineTo(w * 0.60, h * 0.56);
    p.lineTo(w * 0.68, h * 0.78);
    p.lineTo(w * 0.50, h * 0.64);
    p.lineTo(w * 0.32, h * 0.78);
    p.lineTo(w * 0.40, h * 0.56);
    p.lineTo(w * 0.22, h * 0.44);
    p.lineTo(w * 0.44, h * 0.44);
    p.close();
    return p;
  }

  Path _spark(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.50, h * 0.18)
      ..lineTo(w * 0.50, h * 0.82)
      ..moveTo(w * 0.18, h * 0.50)
      ..lineTo(w * 0.82, h * 0.50)
      ..moveTo(w * 0.30, h * 0.30)
      ..lineTo(w * 0.70, h * 0.70)
      ..moveTo(w * 0.70, h * 0.30)
      ..lineTo(w * 0.30, h * 0.70);
  }

  Path _more(Size size) {
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(size.width * 0.50, size.height * 0.30), radius: size.shortestSide * 0.04));
    p.addOval(Rect.fromCircle(center: Offset(size.width * 0.50, size.height * 0.50), radius: size.shortestSide * 0.04));
    p.addOval(Rect.fromCircle(center: Offset(size.width * 0.50, size.height * 0.70), radius: size.shortestSide * 0.04));
    return p;
  }

  Path _share(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.34, h * 0.56)
      ..lineTo(w * 0.66, h * 0.38)
      ..moveTo(w * 0.34, h * 0.44)
      ..lineTo(w * 0.66, h * 0.62)
      ..addOval(Rect.fromCircle(center: Offset(w * 0.30, h * 0.50), radius: size.shortestSide * 0.07))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.70, h * 0.34), radius: size.shortestSide * 0.07))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.70, h * 0.66), radius: size.shortestSide * 0.07));
  }

  Path _image(Size size) {
    final r = size.shortestSide * 0.14;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.22, size.height * 0.26, size.width * 0.56, size.height * 0.48), Radius.circular(r));
    final p = Path()..addRRect(rect);
    p.addOval(Rect.fromCircle(center: Offset(size.width * 0.38, size.height * 0.42), radius: size.shortestSide * 0.05));
    p.moveTo(size.width * 0.30, size.height * 0.68);
    p.lineTo(size.width * 0.46, size.height * 0.52);
    p.lineTo(size.width * 0.58, size.height * 0.64);
    p.lineTo(size.width * 0.70, size.height * 0.50);
    return p;
  }

  Path _inbox(Size size) {
    final r = size.shortestSide * 0.12;
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.22, size.height * 0.30, size.width * 0.56, size.height * 0.48), Radius.circular(r)));
    p.moveTo(size.width * 0.22, size.height * 0.46);
    p.lineTo(size.width * 0.40, size.height * 0.56);
    p.lineTo(size.width * 0.60, size.height * 0.56);
    p.lineTo(size.width * 0.78, size.height * 0.46);
    return p;
  }

  Path _battery(Size size, {required bool charging}) {
    final w = size.width;
    final h = size.height;
    final r = size.shortestSide * 0.10;
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.34, w * 0.52, h * 0.32), Radius.circular(r)));
    p.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.74, h * 0.44, w * 0.06, h * 0.12), Radius.circular(r * 0.6)));
    if (charging) {
      p.moveTo(w * 0.46, h * 0.34);
      p.lineTo(w * 0.40, h * 0.52);
      p.lineTo(w * 0.50, h * 0.52);
      p.lineTo(w * 0.44, h * 0.66);
    } else {
      p.addRect(Rect.fromLTWH(w * 0.26, h * 0.38, w * 0.26, h * 0.24));
    }
    return p;
  }

  Path _send(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.moveTo(w * 0.22, h * 0.50);
    p.lineTo(w * 0.82, h * 0.22);
    p.lineTo(w * 0.66, h * 0.82);
    p.lineTo(w * 0.52, h * 0.60);
    p.close();
    return p;
  }

  Path _pin(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(w * 0.50, h * 0.40), radius: size.shortestSide * 0.16));
    p.moveTo(w * 0.50, h * 0.56);
    p.cubicTo(w * 0.28, h * 0.58, w * 0.34, h * 0.86, w * 0.50, h * 0.90);
    p.cubicTo(w * 0.66, h * 0.86, w * 0.72, h * 0.58, w * 0.50, h * 0.56);
    return p;
  }

  Path _cake(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.26, h * 0.44, w * 0.48, h * 0.32), Radius.circular(size.shortestSide * 0.10)));
    p.moveTo(w * 0.30, h * 0.44);
    p.lineTo(w * 0.34, h * 0.30);
    p.moveTo(w * 0.42, h * 0.44);
    p.lineTo(w * 0.46, h * 0.30);
    p.moveTo(w * 0.54, h * 0.44);
    p.lineTo(w * 0.58, h * 0.30);
    p.addOval(Rect.fromCircle(center: Offset(w * 0.34, h * 0.26), radius: size.shortestSide * 0.03));
    p.addOval(Rect.fromCircle(center: Offset(w * 0.46, h * 0.26), radius: size.shortestSide * 0.03));
    p.addOval(Rect.fromCircle(center: Offset(w * 0.58, h * 0.26), radius: size.shortestSide * 0.03));
    return p;
  }

  @override
  bool shouldRepaint(covariant _TruLuraIconPainter oldDelegate) {
    return oldDelegate.glyph != glyph || oldDelegate.color != color || oldDelegate.glowIntensity != glowIntensity || oldDelegate.glowA != glowA || oldDelegate.glowB != glowB || oldDelegate.surfaceTint != surfaceTint;
  }

  @override
  bool? hitTest(Offset position) => false;
}
