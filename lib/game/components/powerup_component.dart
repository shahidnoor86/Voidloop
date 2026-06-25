import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';

enum PowerupType { extraLife, extraPoints, stoneCrasher }

class PowerupComponent extends PositionComponent {
  final PowerupType type;
  double _pulseTime = 0;
  double _floatTime = 0;
  bool collected = false;

  static const double radius = 16.0;
  static const double collectRadius = radius + GameConstants.playerRadius + 4;

  PowerupComponent({required Vector2 position, required this.type})
    : super(position: position, anchor: Anchor.center);

  // ── Visual config per type ──────────────────────────────────
  Color get _coreColor {
    switch (type) {
      case PowerupType.extraLife:
        return const Color(0xFFFF4081);
      case PowerupType.extraPoints:
        return const Color(0xFFFFD600);
      case PowerupType.stoneCrasher:
        return const Color(0xFFFF6D00);
    }
  }

  Color get _glowColor {
    switch (type) {
      case PowerupType.extraLife:
        return const Color(0xFFFF80AB);
      case PowerupType.extraPoints:
        return const Color(0xFFFFFF8D);
      case PowerupType.stoneCrasher:
        return const Color(0xFFFFAB40);
    }
  }

  IconData get icon {
    switch (type) {
      case PowerupType.extraLife:
        return Icons.favorite;
      case PowerupType.extraPoints:
        return Icons.stars;
      case PowerupType.stoneCrasher:
        return Icons.flash_on;
    }
  }

  String get label {
    switch (type) {
      case PowerupType.extraLife:
        return 'LIFE';
      case PowerupType.extraPoints:
        return '+PTS';
      case PowerupType.stoneCrasher:
        return 'BREAK';
    }
  }

  bool collidesWithPlayer(Vector2 playerPos) {
    return position.distanceTo(playerPos) < collectRadius;
  }

  @override
  void update(double dt) {
    _pulseTime += dt * 2.8;
    _floatTime += dt * 1.4;
    // Gentle floating bob
    position.y += sin(_floatTime) * 0.35;
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;

    final pulse = 0.12 * sin(_pulseTime);
    final r = radius + pulse * radius;

    // Outer soft glow
    canvas.drawCircle(
      Offset.zero,
      r * 2.2,
      Paint()
        ..color = _glowColor.withOpacity(0.12 + pulse * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Mid glow ring
    canvas.drawCircle(
      Offset.zero,
      r * 1.5,
      Paint()
        ..color = _coreColor.withOpacity(0.22 + pulse * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Spinning dashed ring
    canvas.save();
    canvas.rotate(_pulseTime * 0.4);
    final dashPaint = Paint()
      ..color = _coreColor.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawDashedCircle(canvas, r + 5, 12, dashPaint);
    canvas.restore();

    // Core circle (gradient)
    final shader = RadialGradient(
      colors: [_glowColor, _coreColor],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, Paint()..shader = shader);

    // Icon symbol drawn manually
    _drawIcon(canvas, r);

    // Label below
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, r + 5));
  }

  void _drawDashedCircle(Canvas canvas, double r, int count, Paint paint) {
    final dashAngle = (2 * pi / count) * 0.55;
    for (int i = 0; i < count; i++) {
      final start = (i / count) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        start,
        dashAngle,
        false,
        paint,
      );
    }
  }

  void _drawIcon(Canvas canvas, double r) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.fill;

    switch (type) {
      case PowerupType.extraLife:
        // Heart shape
        final s = r * 0.42;
        final path = Path();
        path.moveTo(0, s * 0.4);
        path.cubicTo(-s * 0.1, -s * 0.2, -s, -s * 0.2, -s, s * 0.4);
        path.cubicTo(-s, s, 0, s * 1.3, 0, s * 1.3);
        path.cubicTo(0, s * 1.3, s, s, s, s * 0.4);
        path.cubicTo(s, -s * 0.2, s * 0.1, -s * 0.2, 0, s * 0.4);
        canvas.save();
        canvas.translate(0, -s * 0.3);
        canvas.drawPath(path, paint);
        canvas.restore();
        break;

      case PowerupType.extraPoints:
        // Star shape
        final s = r * 0.48;
        final starPath = Path();
        for (int i = 0; i < 5; i++) {
          final outerAngle = (i * 2 * pi / 5) - pi / 2;
          final innerAngle = outerAngle + pi / 5;
          final ox = cos(outerAngle) * s;
          final oy = sin(outerAngle) * s;
          final ix = cos(innerAngle) * s * 0.42;
          final iy = sin(innerAngle) * s * 0.42;
          if (i == 0) {
            starPath.moveTo(ox, oy);
          } else {
            starPath.lineTo(ox, oy);
          }
          starPath.lineTo(ix, iy);
        }
        starPath.close();
        canvas.drawPath(starPath, paint);
        break;

      case PowerupType.stoneCrasher:
        // Lightning bolt
        final s = r * 0.42;
        final boltPath = Path()
          ..moveTo(s * 0.2, -s)
          ..lineTo(-s * 0.3, -s * 0.05)
          ..lineTo(s * 0.15, -s * 0.05)
          ..lineTo(-s * 0.2, s)
          ..lineTo(s * 0.4, -s * 0.2)
          ..lineTo(-s * 0.05, -s * 0.2)
          ..close();
        canvas.drawPath(boltPath, paint);
        break;
    }
  }
}
