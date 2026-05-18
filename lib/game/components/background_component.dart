import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Star {
  final Vector2 position;
  final double radius;
  final double opacity;
  double twinkle;
  final double twinkleSpeed;

  Star({
    required this.position,
    required this.radius,
    required this.opacity,
    required this.twinkle,
    required this.twinkleSpeed,
  });
}

class BackgroundComponent extends Component {
  final List<Star> _stars = [];
  static const int starCount = 200;
  final Vector2 worldSize;

  BackgroundComponent({required this.worldSize});

  @override
  Future<void> onLoad() async {
    final rng = Random();
    for (int i = 0; i < starCount; i++) {
      _stars.add(
        Star(
          position: Vector2(
            rng.nextDouble() * worldSize.x,
            rng.nextDouble() * worldSize.y,
          ),
          radius: rng.nextDouble() * 1.8 + 0.3,
          opacity: rng.nextDouble() * 0.7 + 0.3,
          twinkle: rng.nextDouble() * 2 * pi,
          twinkleSpeed: rng.nextDouble() * 1.5 + 0.5,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    for (final star in _stars) {
      star.twinkle += star.twinkleSpeed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    // Deep space gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF060612), Color(0xFF0A0820)],
      ).createShader(Rect.fromLTWH(0, 0, worldSize.x, worldSize.y));

    canvas.drawRect(Rect.fromLTWH(0, 0, worldSize.x, worldSize.y), bgPaint);

    // Stars
    for (final star in _stars) {
      final twinkleOpacity = star.opacity * (0.6 + 0.4 * sin(star.twinkle));
      final paint = Paint()
        ..color = Colors.white.withOpacity(twinkleOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(star.position.toOffset(), star.radius, paint);
    }
  }
}
