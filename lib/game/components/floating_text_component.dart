import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A floating label that rises upward and fades out.
/// Add to camera.viewport so it stays in screen space.
class FloatingTextComponent extends PositionComponent {
  final String text;
  final Color color;
  final double fontSize;
  final double duration;
  final double riseSpeed;

  double _elapsed = 0;

  FloatingTextComponent({
    required Vector2 position,
    required this.text,
    this.color = Colors.white,
    this.fontSize = 26,
    this.duration = 1.6,
    this.riseSpeed = 50,
  }) : super(position: position, anchor: Anchor.center);

  // Stays opaque for first 40% of lifetime, then fades to 0
  double get _opacity {
    const holdFraction = 0.40;
    final holdEnd = duration * holdFraction;
    if (_elapsed <= holdEnd) return 1.0;
    return (1.0 - (_elapsed - holdEnd) / (duration - holdEnd)).clamp(0.0, 1.0);
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    position.y -= riseSpeed * dt;
    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final op = _opacity;
    if (op <= 0) return;

    // Drop shadow
    final shadow = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black.withOpacity(op * 0.65),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shadow.paint(
      canvas,
      Offset(-shadow.width / 2 + 1.5, -shadow.height / 2 + 1.5),
    );

    // Main text
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(op),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}
