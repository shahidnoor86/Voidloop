import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';

class BlackHoleComponent extends PositionComponent {
  double _rotationTime = 0;
  double _pulseTime = 0;

  BlackHoleComponent({required Vector2 position})
    : super(position: position, anchor: Anchor.center);

  double get gravityRadius => GameConstants.blackHoleGravityRadius;
  double get destroyRadius => GameConstants.blackHoleDestroyRadius;
  double get gravityStrength => GameConstants.blackHoleGravityStrength;

  /// Returns gravity force vector to apply to player
  Vector2 gravityForce(Vector2 playerPos) {
    final diff = position - playerPos;
    final dist = diff.length;
    if (dist > gravityRadius || dist < 1) return Vector2.zero();
    final strength = gravityStrength * (1 - dist / gravityRadius);
    return diff.normalized() * strength;
  }

  bool destroysPoint(Vector2 point) {
    return position.distanceTo(point) < destroyRadius;
  }

  @override
  void update(double dt) {
    _rotationTime += dt * 1.2;
    _pulseTime += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.1 * sin(_pulseTime * 2.0);

    // Gravity field hint (outer glow)
    final fieldPaint = Paint()
      ..color = Colors.purple.withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset.zero, gravityRadius * 0.6, fieldPaint);

    // Accretion disk rings
    for (int i = 3; i >= 1; i--) {
      canvas.save();
      canvas.rotate(_rotationTime * (0.3 * i));
      canvas.scale(1.0, 0.3);
      final ringPaint = Paint()
        ..color = const Color(0xFF7C4DFF).withOpacity(0.15 * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 + i * 1.5;
      canvas.drawOval(
        Rect.fromCircle(
          center: Offset.zero,
          radius: GameConstants.blackHoleRadius * (1.2 + i * 0.4),
        ),
        ringPaint,
      );
      canvas.restore();
    }

    // Inner glow
    final innerGlowPaint = Paint()
      ..color = Colors.deepPurple.withOpacity(0.5 + pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      Offset.zero,
      GameConstants.blackHoleRadius * 1.2,
      innerGlowPaint,
    );

    // Core — absolute black
    final corePaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, GameConstants.blackHoleRadius, corePaint);

    // Event horizon rim
    final rimPaint = Paint()
      ..color = const Color(0xFF7C4DFF).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset.zero, GameConstants.blackHoleRadius, rimPaint);
  }
}
