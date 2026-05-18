import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../constants.dart';

class PlanetComponent extends PositionComponent {
  final double planetRadius;
  final double orbitRadius;
  final Color color;
  final int orbitIndex;
  bool isActive = false; // Currently being orbited by player
  double _pulseTime = 0;

  PlanetComponent({
    required Vector2 position,
    required this.planetRadius,
    required this.orbitRadius,
    required this.color,
    required this.orbitIndex,
  }) : super(position: position, anchor: Anchor.center);

  double get captureRadius => orbitRadius + GameConstants.captureRadiusExtra;

  @override
  void update(double dt) {
    _pulseTime += dt;
  }

  @override
  void render(Canvas canvas) {
    _drawOrbitRing(canvas);
    _drawPlanet(canvas);
  }

  void _drawOrbitRing(Canvas canvas) {
    // Dashed orbit ring
    final paint = Paint()
      ..color = isActive
          ? color.withOpacity(0.35)
          : GameConstants.orbitRingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 1.5 : 1.0;

    if (isActive) {
      // Solid glowing ring when active
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset.zero, orbitRadius, paint);
      paint.maskFilter = null;
      paint.color = color.withOpacity(0.15);
      paint.strokeWidth = 1.0;
      canvas.drawCircle(Offset.zero, orbitRadius, paint);
    } else {
      // Dashed ring
      _drawDashedCircle(canvas, orbitRadius, paint);
    }
  }

  void _drawDashedCircle(Canvas canvas, double radius, Paint paint) {
    const int segments = 32;
    const double dashFraction = 0.6;
    for (int i = 0; i < segments; i++) {
      final startAngle = (i / segments) * 2 * pi;
      final sweepAngle = (1 / segments) * 2 * pi * dashFraction;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  void _drawPlanet(Canvas canvas) {
    final pulse = 0.08 * sin(_pulseTime * 1.8);

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25 + pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, planetRadius * 1.2);
    canvas.drawCircle(Offset.zero, planetRadius * 1.5, glowPaint);

    // Planet body gradient
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 1.0,
      colors: [
        Color.lerp(color, Colors.white, 0.4)!,
        color,
        Color.lerp(color, Colors.black, 0.4)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final bodyPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: Offset.zero, radius: planetRadius),
      );
    canvas.drawCircle(Offset.zero, planetRadius, bodyPaint);

    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(-planetRadius * 0.3, -planetRadius * 0.3),
      planetRadius * 0.25,
      highlightPaint,
    );

    // Ring decoration (for some planets)
    if (orbitIndex % 3 == 1) {
      final ringPaint = Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.save();
      canvas.scale(1.0, 0.28);
      canvas.drawCircle(Offset.zero, planetRadius * 1.55, ringPaint);
      canvas.restore();
    }
  }
}
