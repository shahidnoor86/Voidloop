import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import 'planet_component.dart';
import 'obstacle_component.dart';
import 'black_hole_component.dart';

enum PlayerState { orbiting, aiming, flying, dead }

class PlayerComponent extends PositionComponent {
  PlayerState state = PlayerState.orbiting;

  PlanetComponent? currentPlanet;
  double orbitAngle = 0.0;
  double angularVelocity = 1.4; // radians/sec
  bool orbitClockwise = true;

  Vector2 velocity = Vector2.zero();

  // Trail
  final List<Vector2> _trail = [];

  // Death animation
  double _deathTime = 0;
  bool get isDead => state == PlayerState.dead;

  // Visual
  double _glowTime = 0;

  // Trajectory preview dots
  List<Vector2> trajectoryPoints = [];

  PlayerComponent() : super(anchor: Anchor.center);

  /// Called by game when tap starts
  void startAiming() {
    if (state == PlayerState.orbiting) {
      state = PlayerState.aiming;
      _updateTrajectoryPreview(0.5); // default preview
    }
  }

  /// Called by game with current power (0..1) to update preview
  void updateAiming(double power) {
    if (state == PlayerState.aiming) {
      _updateTrajectoryPreview(power);
    }
  }

  void _updateTrajectoryPreview(double power) {
    final speed = _speedFromPower(power);
    final dir = _launchDirection();
    trajectoryPoints = [];
    const steps = 18;
    const stepDist = 18.0;
    for (int i = 1; i <= steps; i++) {
      trajectoryPoints.add(position + dir * (speed / 300.0) * stepDist * i.toDouble());
    }
  }

  /// Called by game on tap release
  void launch(double power) {
    if (state != PlayerState.aiming && state != PlayerState.orbiting) return;
    final speed = _speedFromPower(power);
    velocity = _launchDirection() * speed;
    state = PlayerState.flying;
    trajectoryPoints = [];
    currentPlanet?.isActive = false;
    _trail.clear();
  }

  double _speedFromPower(double power) {
    return GameConstants.minLaunchSpeed +
        power * (GameConstants.maxLaunchSpeed - GameConstants.minLaunchSpeed);
  }

  Vector2 _launchDirection() {
    final angle = orbitAngle;
    // Tangent to orbit
    if (orbitClockwise) {
      return Vector2(-sin(angle), cos(angle));
    } else {
      return Vector2(sin(angle), -cos(angle));
    }
  }

  void snapToPlanet(PlanetComponent planet) {
    currentPlanet?.isActive = false;
    currentPlanet = planet;

    // Snap angle from current position relative to planet
    final diff = position - planet.position;
    orbitAngle = atan2(diff.y, diff.x);

    // Determine orbit direction based on current velocity
    final tangentCW = Vector2(-sin(orbitAngle), cos(orbitAngle));
    orbitClockwise = velocity.dot(tangentCW) >= 0;

    // Angular speed inversely proportional to orbit radius
    angularVelocity = 280.0 / planet.orbitRadius;

    state = PlayerState.orbiting;
    velocity = Vector2.zero();
    planet.isActive = true;
    _trail.clear();
  }

  void die() {
    if (state == PlayerState.dead) return;
    state = PlayerState.dead;
    _deathTime = 0;
    currentPlanet?.isActive = false;
    velocity = Vector2.zero();
    trajectoryPoints = [];
  }

  bool checkObstacleCollision(List<ObstacleComponent> obstacles) {
    for (final obs in obstacles) {
      if (obs.collidesWithPoint(position)) return true;
    }
    return false;
  }

  bool checkBlackHoleCollision(List<BlackHoleComponent> blackHoles) {
    for (final bh in blackHoles) {
      if (bh.destroysPoint(position)) return true;
    }
    return false;
  }

  void applyBlackHoleGravity(List<BlackHoleComponent> blackHoles, double dt) {
    for (final bh in blackHoles) {
      velocity += bh.gravityForce(position) * dt;
    }
  }

  @override
  void update(double dt) {
    _glowTime += dt;

    if (state == PlayerState.dead) {
      _deathTime += dt;
      return;
    }

    if (state == PlayerState.orbiting || state == PlayerState.aiming) {
      if (currentPlanet != null) {
        orbitAngle += (orbitClockwise ? 1 : -1) * angularVelocity * dt;
        position =
            currentPlanet!.position +
            Vector2(
              cos(orbitAngle) * currentPlanet!.orbitRadius,
              sin(orbitAngle) * currentPlanet!.orbitRadius,
            );
      }
    } else if (state == PlayerState.flying) {
      _trail.add(position.clone());
      if (_trail.length > GameConstants.playerTrailLength) {
        _trail.removeAt(0);
      }
      position += velocity * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    if (state == PlayerState.dead) {
      _renderDeath(canvas);
      return;
    }

    // Trajectory dots (aiming)
    if (state == PlayerState.aiming && trajectoryPoints.isNotEmpty) {
      _renderTrajectory(canvas);
    }

    // Trail
    if (_trail.isNotEmpty) {
      _renderTrail(canvas);
    }

    // Outer glow
    final glow = 0.1 * sin(_glowTime * 3);
    final glowPaint = Paint()
      ..color = GameConstants.playerColor.withOpacity(0.25 + glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset.zero, GameConstants.playerRadius * 1.8, glowPaint);

    // Core
    final corePaint = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0xFF80FFFF), Color(0xFF00E5FF), Color(0xFF0097A7)],
            stops: [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset.zero,
              radius: GameConstants.playerRadius,
            ),
          );
    canvas.drawCircle(Offset.zero, GameConstants.playerRadius, corePaint);

    // Highlight
    canvas.drawCircle(
      Offset(
        -GameConstants.playerRadius * 0.3,
        -GameConstants.playerRadius * 0.35,
      ),
      GameConstants.playerRadius * 0.28,
      Paint()..color = Colors.white.withOpacity(0.75),
    );
  }

  void _renderTrail(Canvas canvas) {
    for (int i = 0; i < _trail.length; i++) {
      final t = i / _trail.length;
      final trailPos = _trail[i] - position;
      final paint = Paint()
        ..color = GameConstants.playerColor.withOpacity(t * 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        trailPos.toOffset(),
        GameConstants.playerRadius * t * 0.7,
        paint,
      );
    }
  }

  void _renderTrajectory(Canvas canvas) {
    for (int i = 0; i < trajectoryPoints.length; i++) {
      final dot = trajectoryPoints[i] - position;
      final t = 1 - (i / trajectoryPoints.length);
      final dotPaint = Paint()
        ..color = GameConstants.playerColor.withOpacity(t * 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dot.toOffset(), 3.0 * t, dotPaint);
    }
  }

  void _renderDeath(Canvas canvas) {
    // Expanding explosion ring
    final expandRadius = GameConstants.playerRadius * (1 + _deathTime * 8);
    final alpha = (1 - _deathTime * 2).clamp(0.0, 1.0);

    final ringPaint = Paint()
      ..color = GameConstants.playerColor.withOpacity(alpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, expandRadius, ringPaint);

    // Fading core
    if (alpha > 0.1) {
      canvas.drawCircle(
        Offset.zero,
        GameConstants.playerRadius * alpha,
        Paint()..color = GameConstants.playerColor.withOpacity(alpha),
      );
    }
  }
}
