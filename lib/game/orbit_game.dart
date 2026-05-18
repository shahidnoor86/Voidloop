import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../score_service.dart';
import 'components/background_component.dart';
import 'components/black_hole_component.dart';
import 'components/hud_component.dart';
import 'components/obstacle_component.dart';
import 'components/asteroid_component.dart';
import 'components/planet_component.dart';
import 'components/player_component.dart';
import 'components/power_bar_component.dart';

enum GamePhase { playing, paused, gameOver }

class OrbitGame extends FlameGame with TapCallbacks {
  static const String pauseOverlay = 'PauseOverlay';
  static const String gameOverOverlay = 'GameOverOverlay';

  // ── State ──────────────────────────────────────────────────
  GamePhase phase = GamePhase.playing;
  int score = 0;
  int bestScore = 0;
  int orbitsCompleted = 0;
  int _highestOrbitReached = 0;
  int _totalPlanetsSpawned = 0;

  // ── Core components ────────────────────────────────────────
  late final World _world;
  late final CameraComponent _camera;
  late final PlayerComponent _player;
  late final PowerBarComponent _powerBar;
  late final HudComponent _hud;

  // ── Level objects ──────────────────────────────────────────
  final List<PlanetComponent> _planets = [];
  final List<ObstacleComponent> _obstacles = []; // red sphere orbiters
  final List<AsteroidComponent> _asteroids = []; // rocky asteroids
  final List<BlackHoleComponent> _blackHoles = [];

  final Random _rng = Random();
  double _worldWidth = 0;
  double _highestPlanetY = 0;

  // ── Input ──────────────────────────────────────────────────
  bool _isTapping = false;

  // ── Death timer ────────────────────────────────────────────
  double _deathTimer = 0;
  static const double _deathDelay = 1.2;

  // ─────────────────────────────────────────────────────────────
  @override
  Color backgroundColor() => GameConstants.bgColor;

  @override
  Future<void> onLoad() async {
    _worldWidth = size.x;
    bestScore = ScoreService.getBestScore();

    _world = World();
    _camera = CameraComponent(world: _world)..viewfinder.anchor = Anchor.center;
    addAll([_world, _camera]);

    // Starfield background (tall enough to never run out)
    _world.add(
      BackgroundComponent(worldSize: Vector2(_worldWidth, size.y * 60)),
    );

    _generateInitialLevel();

    _player = PlayerComponent();
    _world.add(_player);

    final start = _planets.first;
    _player.position = start.position + Vector2(start.orbitRadius, 0);
    _player.snapToPlanet(start);

    // Camera follows player (maxSpeed keeps it smooth during play)
    _camera.follow(_player, maxSpeed: 280);

    // Power bar (viewport = screen space)
    _powerBar = PowerBarComponent(position: Vector2(size.x - 38, size.y / 2));
    _camera.viewport.add(_powerBar);

    _hud = HudComponent(screenSize: size);
    _camera.viewport.add(_hud);

    _hud.updateScore(score, bestScore, _currentLevel());
  }

  // ── Level generation ────────────────────────────────────────

  void _generateInitialLevel() {
    var lastPos = Vector2(_worldWidth / 2, size.y * 0.72);
    for (int i = 0; i < 6; i++) {
      _spawnPlanet(lastPos);
      lastPos = _planets.last.position;
    }
    _highestPlanetY = _planets.last.position.y;
  }

  void _spawnPlanet(Vector2 below) {
    final index = _totalPlanetsSpawned;
    _totalPlanetsSpawned++;
    final spacing =
        (GameConstants.basePlanetSpacing +
                index * GameConstants.spacingIncreasePerLevel)
            .clamp(
              GameConstants.basePlanetSpacing,
              GameConstants.maxPlanetSpacing,
            );

    final maxDx = _worldWidth * 0.35;
    final dx = (_rng.nextDouble() * 2 - 1) * maxDx;
    final newX = (below.x + dx).clamp(85.0, _worldWidth - 85.0);
    final newY = below.y - spacing;

    final planetR =
        GameConstants.planetMinRadius +
        _rng.nextDouble() *
            (GameConstants.planetMaxRadius - GameConstants.planetMinRadius);
    final orbitR =
        GameConstants.orbitMinRadius +
        _rng.nextDouble() *
            (GameConstants.orbitMaxRadius - GameConstants.orbitMinRadius);
    final color = GameConstants
        .planetColors[_rng.nextInt(GameConstants.planetColors.length)];

    final planet = PlanetComponent(
      position: Vector2(newX, newY),
      planetRadius: planetR,
      orbitRadius: orbitR,
      color: color,
      orbitIndex: index,
    );
    _planets.add(planet);
    _world.add(planet);

    // Orbiting obstacles (red spheres + asteroids) around this planet
    if (index >= GameConstants.obstacleStartOrbit) {
      _spawnOrbitingObstacles(planet, index);
    }

    // Drifting asteroids in the gap between this and previous planet
    if (index >= 3) {
      _spawnDriftingAsteroids(below, Vector2(newX, newY), index);
    }

    // Black hole in the gap
    if (index >= GameConstants.blackHoleStartOrbit &&
        _rng.nextDouble() < 0.45) {
      _spawnBlackHoleBetween(below, Vector2(newX, newY));
    }
  }

  /// Spawns a mix of red-sphere orbiters AND orbiting asteroids around [planet].
  void _spawnOrbitingObstacles(PlanetComponent planet, int level) {
    final multiLevel = level >= GameConstants.multiObstacleStartOrbit;
    final totalCount = multiLevel
        ? (_rng.nextInt(2) + 2)
        : (_rng.nextInt(2) + 1);

    for (int i = 0; i < totalCount; i++) {
      final speed =
          GameConstants.obstacleOrbitSpeedMin +
          _rng.nextDouble() *
              (GameConstants.obstacleOrbitSpeedMax -
                  GameConstants.obstacleOrbitSpeedMin);
      final startAngle = _rng.nextDouble() * 2 * pi;
      final cw = _rng.nextBool();

      // Alternate between red sphere and asteroid
      if (i % 2 == 0) {
        final obs = ObstacleComponent(
          planet: planet,
          startAngle: startAngle,
          angularSpeed: speed,
          clockwise: cw,
        );
        _obstacles.add(obs);
        _world.add(obs);
      } else {
        final ast = AsteroidComponent.orbiting(
          planet: planet,
          startAngle: startAngle,
          orbitSpeed: speed,
          clockwise: cw,
          seed: _rng.nextInt(9999),
        );
        _asteroids.add(ast);
        _world.add(ast);
      }
    }

    // Extra asteroid on a slightly different orbit radius for variety
    if (level >= 5 && _rng.nextDouble() < 0.6) {
      final innerR = planet.orbitRadius * (_rng.nextBool() ? 0.75 : 1.25);
      final ast = AsteroidComponent.orbiting(
        planet: planet,
        startAngle: _rng.nextDouble() * 2 * pi,
        orbitSpeed: 0.9 + _rng.nextDouble() * 0.8,
        clockwise: _rng.nextBool(),
        orbitRadius: innerR.clamp(45.0, 130.0),
        seed: _rng.nextInt(9999),
      );
      _asteroids.add(ast);
      _world.add(ast);
    }
  }

  /// Spawns slow-drifting asteroids floating freely in the gap between planets.
  void _spawnDriftingAsteroids(Vector2 from, Vector2 to, int level) {
    // Number of drifting asteroids grows with level
    final count = (_rng.nextInt(2) + (level >= 6 ? 2 : 1));

    for (int i = 0; i < count; i++) {
      // Random position between the two planets
      final t = 0.25 + _rng.nextDouble() * 0.5;
      final midX =
          from.x +
          (to.x - from.x) * t +
          (_rng.nextDouble() * 2 - 1) * _worldWidth * 0.28;
      final midY = from.y + (to.y - from.y) * t;

      // Keep within screen bounds
      final clampedX = midX.clamp(40.0, _worldWidth - 40.0);

      // Slow horizontal drift
      final driftX = (_rng.nextDouble() * 2 - 1) * 28;
      final driftY = (_rng.nextDouble() * 2 - 1) * 12;

      final size = 9.0 + _rng.nextDouble() * 10.0;

      final ast = AsteroidComponent.drifting(
        position: Vector2(clampedX, midY),
        drift: Vector2(driftX, driftY),
        size: size,
        seed: _rng.nextInt(9999),
      );
      _asteroids.add(ast);
      _world.add(ast);
    }
  }

  void _spawnBlackHoleBetween(Vector2 from, Vector2 to) {
    final mid = (from + to) / 2;
    final offsetX = (_rng.nextDouble() * 2 - 1) * 60;
    final bh = BlackHoleComponent(position: Vector2(mid.x + offsetX, mid.y));
    _blackHoles.add(bh);
    _world.add(bh);
  }

  int _currentLevel() => (orbitsCompleted / 5).floor() + 1;

  // ── Input ────────────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    if (phase != GamePhase.playing) return;
    if (_player.isDead) return;

    // Pause button (top-right corner)
    final pos = event.localPosition;
    if (pos.x > size.x - 70 && pos.y < 100) {
      pauseGame();
      return;
    }

    _isTapping = true;
    _powerBar.show();
    _player.startAiming();
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (phase != GamePhase.playing || !_isTapping) return;
    _isTapping = false;
    final power = _powerBar.currentPower;
    _powerBar.hide();
    _player.launch(power);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (!_isTapping) return;
    _isTapping = false;
    _powerBar.hide();
    _player.launch(_powerBar.currentPower);
  }

  // ── Pause / Resume ───────────────────────────────────────────

  void pauseGame() {
    if (phase != GamePhase.playing) return;
    phase = GamePhase.paused;
    pauseEngine();
    overlays.add(pauseOverlay);
  }

  void resumeGame() {
    phase = GamePhase.playing;
    overlays.remove(pauseOverlay);
    resumeEngine();
  }

  // ── Restart ──────────────────────────────────────────────────

  void restartGame() {
    overlays.remove(pauseOverlay);
    overlays.remove(gameOverOverlay);

    // Clear all level objects
    for (final p in _planets) p.removeFromParent();
    for (final o in _obstacles) o.removeFromParent();
    for (final a in _asteroids) a.removeFromParent();
    for (final b in _blackHoles) b.removeFromParent();
    _planets.clear();
    _obstacles.clear();
    _asteroids.clear();
    _blackHoles.clear();

    score = 0;
    orbitsCompleted = 0;
    _highestOrbitReached = 0;
    _totalPlanetsSpawned = 0;
    _deathTimer = 0;
    _isTapping = false;
    phase = GamePhase.playing;

    _generateInitialLevel();

    // Reset player
    final start = _planets.first;
    _player.position = start.position + Vector2(start.orbitRadius, 0);
    _player.state = PlayerState.orbiting;
    _player.velocity = Vector2.zero();
    _player.snapToPlanet(start);

    // ── FIX: snap camera instantly to player's new position ──
    // Stop smooth-follow, teleport, then re-attach follow.
    _camera.stop();
    _camera.viewfinder.position = _player.position;
    _camera.follow(_player, maxSpeed: 280);

    _powerBar.hide();
    _hud.updateScore(score, bestScore, _currentLevel());

    resumeEngine();
  }

  // ── Update loop ──────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (phase != GamePhase.playing) return;

    // Live preview while holding
    if (_isTapping) {
      _player.updateAiming(_powerBar.currentPower);
    }

    if (_player.state == PlayerState.flying) {
      // Black hole gravity
      _player.applyBlackHoleGravity(_blackHoles, dt);

      // Black hole destruction
      if (_player.checkBlackHoleCollision(_blackHoles)) {
        _triggerDeath();
        return;
      }

      // Red sphere obstacle collision
      if (_player.checkObstacleCollision(_obstacles)) {
        _triggerDeath();
        return;
      }

      // Asteroid collision
      if (_checkAsteroidCollision()) {
        _triggerDeath();
        return;
      }

      // Planet capture
      PlanetComponent? captured;
      for (final planet in _planets) {
        if (planet == _player.currentPlanet) continue;
        if (planet.position.distanceTo(_player.position) <=
            planet.captureRadius) {
          captured = planet;
          break;
        }
      }
      if (captured != null) {
        _player.snapToPlanet(captured);
        _onOrbitComplete(captured); // ← pass the planet
      }

      // Out of bounds
      if (_isPlayerOffScreen()) {
        _triggerDeath();
        return;
      }
    }

    // Death delay before game-over overlay
    if (_player.isDead) {
      _deathTimer += dt;
      if (_deathTimer >= _deathDelay) {
        _showGameOver();
      }
      return;
    }

    // Expand level as player ascends
    if (_player.position.y < _highestPlanetY + 700) {
      _expandLevel();
    }

    // Remove far-below components
    _cleanupOldComponents();
  }

  bool _checkAsteroidCollision() {
    for (final ast in _asteroids) {
      if (ast.collidesWithPoint(_player.position)) return true;
    }
    return false;
  }

  bool _isPlayerOffScreen() {
    return _player.position.x < -120 ||
        _player.position.x > _worldWidth + 120 ||
        _player.position.y > _player.position.y + size.y * 1.8;
  }

  void _triggerDeath() {
    _player.die();
    _deathTimer = 0;
    _isTapping = false;
    _powerBar.hide();
  }

  void _showGameOver() {
    phase = GamePhase.gameOver;
    ScoreService.saveBestScore(score);
    bestScore = ScoreService.getBestScore();
    overlays.add(gameOverOverlay);
  }

  void _onOrbitComplete(PlanetComponent newPlanet) {
    final newIndex = newPlanet.orbitIndex;

    // Going backwards or revisiting — no points
    if (newIndex <= _highestOrbitReached) return;

    // How many orbits were jumped in one shot (bonus for skipping)
    final orbitsAdvanced = newIndex - _highestOrbitReached;
    _highestOrbitReached = newIndex;

    orbitsCompleted++;
    score += GameConstants.pointsPerOrbit * _currentLevel() * orbitsAdvanced;
    if (score > bestScore) bestScore = score;
    _hud.updateScore(score, bestScore, _currentLevel());
  }

  void _expandLevel() {
    // final nextIndex = _planets.length;
    _spawnPlanet(_planets.last.position);
    _highestPlanetY = _planets.last.position.y;
  }

  void _cleanupOldComponents() {
    final cutoff = _player.position.y + size.y * 2.8;

    _planets.removeWhere((p) {
      if (p.position.y > cutoff) {
        p.removeFromParent();
        return true;
      }
      return false;
    });
    _obstacles.removeWhere((o) {
      if (o.planet.position.y > cutoff) {
        o.removeFromParent();
        return true;
      }
      return false;
    });
    _asteroids.removeWhere((a) {
      // Remove drifting ones that have gone far off screen too
      final tooFarDown = a.position.y > cutoff;
      final tooFarSide =
          a.position.x < -200 || a.position.x > _worldWidth + 200;
      if (tooFarDown || tooFarSide) {
        a.removeFromParent();
        return true;
      }
      return false;
    });
    _blackHoles.removeWhere((b) {
      if (b.position.y > cutoff) {
        b.removeFromParent();
        return true;
      }
      return false;
    });
  }

  // ── Exposed for overlays ─────────────────────────────────────
  int get currentScore => score;
  int get currentBest => bestScore;
}
