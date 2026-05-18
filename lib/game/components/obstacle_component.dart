import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import 'planet_component.dart';

class ObstacleComponent extends PositionComponent {
  final PlanetComponent planet;
  double _angle;
  final double _angularSpeed;
  final bool _clockwise;
  final double _orbitRadius;
  double _glowTime = 0;

  static const double radius = GameConstants.obstacleRadius;

  ObstacleComponent({
    required this.planet,
    required double startAngle,
    required double angularSpeed,
    required bool clockwise,
    double? orbitRadius,
  }) : _angle = startAngle,
       _angularSpeed = angularSpeed,
       _clockwise = clockwise,
       _orbitRadius = orbitRadius ?? planet.orbitRadius,
       super(anchor: Anchor.center);

  Vector2 get worldPosition =>
      planet.position +
      Vector2(cos(_angle) * _orbitRadius, sin(_angle) * _orbitRadius);

  bool collidesWithPoint(Vector2 point) {
    return worldPosition.distanceTo(point) <
        radius + GameConstants.playerRadius;
  }

  @override
  void update(double dt) {
    _glowTime += dt;
    _angle += (_clockwise ? 1 : -1) * _angularSpeed * dt;
    position = worldPosition;
  }

  @override
  void render(Canvas canvas) {
    final glow = 0.15 * sin(_glowTime * 3);

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF5252).withOpacity(0.35 + glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, radius * 1.6, glowPaint);

    // Body
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFF8A80), Color(0xFFFF1744)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, bodyPaint);

    // Highlight
    canvas.drawCircle(
      Offset(-radius * 0.3, -radius * 0.3),
      radius * 0.3,
      Paint()..color = Colors.white.withOpacity(0.5),
    );
  }
}
