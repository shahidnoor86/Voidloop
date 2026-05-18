import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import 'planet_component.dart';

/// An asteroid that can either orbit a planet or drift freely.
class AsteroidComponent extends PositionComponent {
  final double asteroidSize;
  final List<Vector2> _shape;
  double _rotation = 0;
  final double _rotationSpeed;

  // ── Orbiting mode ──────────────────────────────────────────
  final PlanetComponent? planet;
  double _orbitAngle;
  final double _orbitRadius;
  final double _orbitSpeed;
  final bool _orbitClockwise;

  // ── Drifting mode ──────────────────────────────────────────
  final Vector2 _drift; // pixels/sec, zero if orbiting

  // ── Colour palette ─────────────────────────────────────────
  static const List<Color> _rockColors = [
    Color(0xFF8D6E63),
    Color(0xFF795548),
    Color(0xFF6D4C41),
    Color(0xFFA1887F),
    Color(0xFF9E9E9E),
    Color(0xFF757575),
  ];
  late final Color _baseColor;
  late final Color _darkColor;

  // ── World-space bounding radius for collision ───────────────
  double get collisionRadius =>
      asteroidSize * 0.85 + GameConstants.playerRadius;

  bool collidesWithPoint(Vector2 point) =>
      position.distanceTo(point) < collisionRadius;

  // ── Factory: orbiting asteroid ──────────────────────────────
  AsteroidComponent.orbiting({
    required this.planet,
    required double startAngle,
    required double orbitSpeed,
    required bool clockwise,
    double? orbitRadius,
    double? size,
    int? seed,
  }) : asteroidSize = size ?? (8 + Random(seed).nextDouble() * 7),
       _orbitAngle = startAngle,
       _orbitRadius = orbitRadius ?? planet!.orbitRadius,
       _orbitSpeed = orbitSpeed,
       _orbitClockwise = clockwise,
       _drift = Vector2.zero(),
       _rotationSpeed = (Random(seed).nextDouble() * 2 - 1) * 2.5,
       _shape = _buildShape(
         size ?? (8 + Random(seed).nextDouble() * 7),
         Random((seed ?? 0) + 1),
       ),
       super(anchor: Anchor.center) {
    final rng = Random(seed ?? 42);
    _baseColor = _rockColors[rng.nextInt(_rockColors.length)];
    _darkColor = Color.lerp(_baseColor, Colors.black, 0.4)!;
  }

  // ── Factory: drifting asteroid ──────────────────────────────
  AsteroidComponent.drifting({
    required Vector2 position,
    required Vector2 drift,
    double? size,
    int? seed,
  }) : planet = null,
       asteroidSize = size ?? (9 + Random(seed).nextDouble() * 8),
       _orbitAngle = 0,
       _orbitRadius = 0,
       _orbitSpeed = 0,
       _orbitClockwise = true,
       _drift = drift,
       _rotationSpeed = (Random(seed).nextDouble() * 2 - 1) * 1.8,
       _shape = _buildShape(
         size ?? (9 + Random(seed).nextDouble() * 8),
         Random((seed ?? 0) + 7),
       ),
       super(position: position, anchor: Anchor.center) {
    final rng = Random(seed ?? 99);
    _baseColor = _rockColors[rng.nextInt(_rockColors.length)];
    _darkColor = Color.lerp(_baseColor, Colors.black, 0.4)!;
  }

  // ── Shape generation ────────────────────────────────────────
  static List<Vector2> _buildShape(double r, Random rng) {
    const vertices = 9;
    return List.generate(vertices, (i) {
      final angle = (i / vertices) * 2 * pi;
      final radius = r * (0.65 + rng.nextDouble() * 0.45);
      return Vector2(cos(angle) * radius, sin(angle) * radius);
    });
  }

  @override
  void update(double dt) {
    _rotation += _rotationSpeed * dt;

    if (planet != null) {
      // Orbiting mode
      _orbitAngle += (_orbitClockwise ? 1 : -1) * _orbitSpeed * dt;
      position =
          planet!.position +
          Vector2(
            cos(_orbitAngle) * _orbitRadius,
            sin(_orbitAngle) * _orbitRadius,
          );
    } else {
      // Drifting mode
      position += _drift * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(_rotation);

    final path = Path();
    for (int i = 0; i < _shape.length; i++) {
      final p = _shape[i];
      if (i == 0) {
        path.moveTo(p.x, p.y);
      } else {
        path.lineTo(p.x, p.y);
      }
    }
    path.close();

    // Shadow / glow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, asteroidSize * 0.5),
    );

    // Base fill
    canvas.drawPath(path, Paint()..color = _baseColor);

    // Dark edge shading
    canvas.drawPath(
      path,
      Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(0.3, 0.3),
              radius: 1.0,
              colors: [_baseColor, _darkColor],
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: asteroidSize),
            ),
    );

    // Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = _darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Surface craters (small circles)
    final craterPaint = Paint()
      ..color = _darkColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final craterPositions = [
      Offset(-asteroidSize * 0.25, -asteroidSize * 0.2),
      Offset(asteroidSize * 0.3, asteroidSize * 0.1),
      Offset(-asteroidSize * 0.1, asteroidSize * 0.35),
    ];
    for (final c in craterPositions) {
      canvas.drawCircle(c, asteroidSize * 0.12, craterPaint);
    }

    // Highlight
    canvas.drawCircle(
      Offset(-asteroidSize * 0.3, -asteroidSize * 0.3),
      asteroidSize * 0.18,
      Paint()..color = Colors.white.withOpacity(0.22),
    );

    canvas.restore();
  }
}
