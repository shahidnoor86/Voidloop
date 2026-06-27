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
import 'components/powerup_component.dart';
import 'components/powerup_hud_component.dart';
import 'components/floating_text_component.dart';

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
  // NOTE: _revivedThisRun removed — consumePowerup() returning false
  // is the correct guard; the flag was blocking second extra lives.

  // ── Core components ────────────────────────────────────────
  late final World _world;
  late final CameraComponent _camera;
  late final PlayerComponent _player;
  late final PowerBarComponent _powerBar;
  late final HudComponent _hud;
  late final PowerupHudComponent _powerupHud;

  // ── Level objects ──────────────────────────────────────────
  final List<PlanetComponent> _planets = [];
  final List<ObstacleComponent> _obstacles = [];
  final List<AsteroidComponent> _asteroids = [];
  final List<BlackHoleComponent> _blackHoles = [];
  final List<PowerupComponent> _powerups = [];

  final Random _rng = Random();
  double _worldWidth = 0;
  double _highestPlanetY = 0;

  // ── Input ──────────────────────────────────────────────────
  bool _isTapping = false;

  // ── Death ──────────────────────────────────────────────────
  double _deathTimer = 0;
  static const double _deathDelay = 1.2;

  // ── Revival cooldown (prevents double-consume in same frame) ──
  // Set to true the moment we revive; reset when player orbits next planet.
  bool _justRevived = false;

  @override
  Color backgroundColor() => GameConstants.bgColor;

  @override
  Future<void> onLoad() async {
    _worldWidth = size.x;
    bestScore = ScoreService.getBestScore();

    _world = World();
    _camera = CameraComponent(world: _world)..viewfinder.anchor = Anchor.center;
    addAll([_world, _camera]);

    _world.add(
      BackgroundComponent(worldSize: Vector2(_worldWidth, size.y * 60)),
    );

    _generateInitialLevel();

    _player = PlayerComponent();
    _world.add(_player);

    final start = _planets.first;
    _player.position = start.position + Vector2(start.orbitRadius, 0);
    _player.snapToPlanet(start);

    _camera.follow(_player, maxSpeed: 280);

    _powerBar = PowerBarComponent(position: Vector2(size.x - 38, size.y / 2));
    _camera.viewport.add(_powerBar);

    _hud = HudComponent(screenSize: size);
    _camera.viewport.add(_hud);

    _powerupHud = PowerupHudComponent(screenSize: size);
    _camera.viewport.add(_powerupHud);

    _hud.updateScore(score, bestScore, _currentLevel());
  }

  // ── Level generation ─────────────────────────────────────────

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

    final dx = (_rng.nextDouble() * 2 - 1) * _worldWidth * 0.35;
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

    if (index >= GameConstants.obstacleStartOrbit) {
      _spawnOrbitingObstacles(planet, index);
    }
    if (index >= 3) {
      _spawnDriftingAsteroids(below, Vector2(newX, newY), index);
    }
    if (index >= GameConstants.blackHoleStartOrbit &&
        _rng.nextDouble() < 0.45) {
      _spawnBlackHoleBetween(below, Vector2(newX, newY));
    }
    if (index >= 1) {
      _spawnPowerupsBetween(below, Vector2(newX, newY), index);
    }
  }

  void _spawnOrbitingObstacles(PlanetComponent planet, int level) {
    final count = (level >= GameConstants.multiObstacleStartOrbit)
        ? _rng.nextInt(2) + 2
        : _rng.nextInt(2) + 1;

    for (int i = 0; i < count; i++) {
      final speed =
          GameConstants.obstacleOrbitSpeedMin +
          _rng.nextDouble() *
              (GameConstants.obstacleOrbitSpeedMax -
                  GameConstants.obstacleOrbitSpeedMin);
      final startAngle = _rng.nextDouble() * 2 * pi;
      final cw = _rng.nextBool();

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

  void _spawnDriftingAsteroids(Vector2 from, Vector2 to, int level) {
    final count = _rng.nextInt(2) + (level >= 6 ? 2 : 1);
    for (int i = 0; i < count; i++) {
      final t = 0.25 + _rng.nextDouble() * 0.5;
      final midX =
          from.x +
          (to.x - from.x) * t +
          (_rng.nextDouble() * 2 - 1) * _worldWidth * 0.28;
      final midY = from.y + (to.y - from.y) * t;
      final cx = midX.clamp(40.0, _worldWidth - 40.0);

      final ast = AsteroidComponent.drifting(
        position: Vector2(cx, midY),
        drift: Vector2(
          (_rng.nextDouble() * 2 - 1) * 28,
          (_rng.nextDouble() * 2 - 1) * 12,
        ),
        size: 9.0 + _rng.nextDouble() * 10.0,
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

  // ── Power-up spawning ─────────────────────────────────────────
  // Spawn chance: 20% per gap (was 65% — reduced by 75%)

  void _spawnPowerupsBetween(Vector2 from, Vector2 to, int levelIndex) {
    if (_rng.nextDouble() > 0.20) return; // 20% spawn chance

    final count = (levelIndex >= 8 && _rng.nextDouble() < 0.4) ? 2 : 1;

    for (int i = 0; i < count; i++) {
      final t = 0.3 + _rng.nextDouble() * 0.4;
      final midX =
          from.x + (to.x - from.x) * t + (_rng.nextDouble() * 2 - 1) * 30;
      final midY = from.y + (to.y - from.y) * t;
      final cx = midX.clamp(40.0, _worldWidth - 40.0);

      final type = _pickPowerupType(levelIndex);
      final powerup = PowerupComponent(position: Vector2(cx, midY), type: type);
      _powerups.add(powerup);
      _world.add(powerup);
    }
  }

  PowerupType _pickPowerupType(int level) {
    final roll = _rng.nextDouble();
    if (level <= 4) {
      if (roll < 0.60) return PowerupType.extraPoints;
      if (roll < 0.85) return PowerupType.stoneCrasher;
      return PowerupType.extraLife;
    } else if (level <= 8) {
      if (roll < 0.35) return PowerupType.extraPoints;
      if (roll < 0.70) return PowerupType.stoneCrasher;
      return PowerupType.extraLife;
    } else {
      if (roll < 0.25) return PowerupType.extraPoints;
      if (roll < 0.55) return PowerupType.stoneCrasher;
      return PowerupType.extraLife;
    }
  }

  int _currentLevel() => (orbitsCompleted / 5).floor() + 1;

  // ── Input ─────────────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    if (phase != GamePhase.playing) return;
    if (_player.isDead) return;
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

  // ── Pause / Resume ────────────────────────────────────────────

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

  // ── Restart ───────────────────────────────────────────────────

  void restartGame() {
    overlays.remove(pauseOverlay);
    overlays.remove(gameOverOverlay);

    for (final p in _planets) p.removeFromParent();
    for (final o in _obstacles) o.removeFromParent();
    for (final a in _asteroids) a.removeFromParent();
    for (final b in _blackHoles) b.removeFromParent();
    for (final p in _powerups) p.removeFromParent();
    _planets.clear();
    _obstacles.clear();
    _asteroids.clear();
    _blackHoles.clear();
    _powerups.clear();
    _powerupHud.activePowerups.clear();

    score = 0;
    orbitsCompleted = 0;
    _highestOrbitReached = 0;
    _totalPlanetsSpawned = 0;
    _deathTimer = 0;
    _isTapping = false;
    _justRevived = false;
    phase = GamePhase.playing;

    _generateInitialLevel();

    final start = _planets.first;
    _player.position = start.position + Vector2(start.orbitRadius, 0);
    _player.state = PlayerState.orbiting;
    _player.velocity = Vector2.zero();
    _player.snapToPlanet(start);

    _camera.stop();
    _camera.viewfinder.position = _player.position;
    _camera.follow(_player, maxSpeed: 280);

    _powerBar.hide();
    _hud.updateScore(score, bestScore, _currentLevel());
    resumeEngine();
  }

  // ── Update loop ───────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (phase != GamePhase.playing) return;

    if (_isTapping) _player.updateAiming(_powerBar.currentPower);

    if (_player.state == PlayerState.flying) {
      _player.applyBlackHoleGravity(_blackHoles, dt);

      // Black hole — no power-up saves this
      if (_player.checkBlackHoleCollision(_blackHoles)) {
        _triggerDeath();
        return;
      }

      // Red sphere obstacles — no power-up saves this
      if (_player.checkObstacleCollision(_obstacles)) {
        _triggerDeath();
        return;
      }

      // Asteroid — Stone Crasher intercepts ──────────────────────
      final hitAsteroid = _findCollidingAsteroid();
      if (hitAsteroid != null) {
        if (_powerupHud.consumePowerup(PowerupType.stoneCrasher)) {
          // Remove the asteroid, player passes through safely
          _asteroids.remove(hitAsteroid);
          hitAsteroid.removeFromParent();
          final bonus = 50 * _currentLevel();
          _addScore(bonus);
          // Feedback: show "ASTEROID CRUSHED!" centre screen
          _showFloating(
            'ASTEROID CRUSHED!',
            const Color(0xFFFF6D00),
            fontSize: 22,
          );
        } else {
          _triggerDeath();
          return;
        }
      }

      // Collect power-ups
      _checkPowerupCollection();

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
        _onOrbitComplete(captured);
      }

      if (_isPlayerOffScreen()) {
        _triggerDeath();
        return;
      }
    }

    // ── Death countdown ───────────────────────────────────────
    // Extra Life intercepts at half-way through death animation.
    // _justRevived prevents double-consuming in the same death event.
    if (_player.isDead) {
      _deathTimer += dt;

      if (_deathTimer >= _deathDelay * 0.5 && !_justRevived) {
        if (_powerupHud.consumePowerup(PowerupType.extraLife)) {
          _revivePlayer();
          return;
        }
      }

      if (_deathTimer >= _deathDelay) {
        _showGameOver();
      }
      return;
    }

    if (_player.position.y < _highestPlanetY + 700) _expandLevel();
    _cleanupOldComponents();
  }

  // ── Power-up collection ───────────────────────────────────────

  void _checkPowerupCollection() {
    final toRemove = <PowerupComponent>[];
    for (final powerup in _powerups) {
      if (powerup.collected) continue;
      if (powerup.collidesWithPlayer(_player.position)) {
        powerup.collected = true;
        toRemove.add(powerup);
        _applyPowerup(powerup.type);
      }
    }
    for (final p in toRemove) {
      _powerups.remove(p);
      p.removeFromParent();
    }
  }

  void _applyPowerup(PowerupType type) {
    switch (type) {
      case PowerupType.extraPoints:
        // Instant bonus — no inventory slot
        final bonus = 150 * _currentLevel();
        _addScore(bonus);
        // Show floating "+150 PTS" (or whatever the bonus is)
        _showFloating(
          '+$bonus PTS',
          const Color(0xFFFFD600),
          fontSize: 34,
          riseSpeed: 60,
        );
        break;

      case PowerupType.extraLife:
        _powerupHud.addPowerup(type);
        _showFloating('EXTRA LIFE!', const Color(0xFFFF4081), fontSize: 24);
        break;

      case PowerupType.stoneCrasher:
        _powerupHud.addPowerup(type);
        _showFloating('STONE CRASHER!', const Color(0xFFFF6D00), fontSize: 24);
        break;
    }
  }

  // ── Extra life revival ────────────────────────────────────────

  void _revivePlayer() {
    _justRevived = true; // blocks double-consume within this death event
    _deathTimer = 0;

    final planet = _player.currentPlanet ?? _planets.last;
    _player.position = planet.position + Vector2(planet.orbitRadius, 0);
    _player.state = PlayerState.orbiting;
    _player.velocity = Vector2.zero();
    _player.snapToPlanet(planet);

    // Feedback
    final remaining = _powerupHud.countOf(PowerupType.extraLife);
    final msg = remaining > 0
        ? 'LIFE SAVED!  ($remaining left)'
        : 'LIFE SAVED!';
    _showFloating(msg, const Color(0xFFFF4081), fontSize: 26);
  }

  // ── Floating text helper ──────────────────────────────────────

  /// Shows a floating label centred on screen, rising and fading.
  void _showFloating(
    String text,
    Color color, {
    double fontSize = 26,
    double riseSpeed = 45,
    double duration = 1.6,
  }) {
    _camera.viewport.add(
      FloatingTextComponent(
        position: Vector2(size.x / 2, size.y * 0.48),
        text: text,
        color: color,
        fontSize: fontSize,
        riseSpeed: riseSpeed,
        duration: duration,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  AsteroidComponent? _findCollidingAsteroid() {
    for (final ast in _asteroids) {
      if (ast.collidesWithPoint(_player.position)) return ast;
    }
    return null;
  }

  bool _isPlayerOffScreen() {
    return _player.position.x < -120 ||
        _player.position.x > _worldWidth + 120 ||
        _player.position.y > _player.position.y + size.y * 1.8;
  }

  void _triggerDeath() {
    _player.die();
    _deathTimer = 0;
    _justRevived = false; // fresh death — allow revival again
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
    if (newIndex <= _highestOrbitReached) return;

    final orbitsAdvanced = newIndex - _highestOrbitReached;
    _highestOrbitReached = newIndex;
    orbitsCompleted++;

    // Player safely reached a new orbit — allow revival again on next death
    _justRevived = false;

    _addScore(GameConstants.pointsPerOrbit * _currentLevel() * orbitsAdvanced);
  }

  void _addScore(int points) {
    score += points;
    if (score > bestScore) bestScore = score;
    _hud.updateScore(score, bestScore, _currentLevel());
  }

  void _expandLevel() {
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
      final gone =
          a.position.y > cutoff ||
          a.position.x < -200 ||
          a.position.x > _worldWidth + 200;
      if (gone) {
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
    _powerups.removeWhere((p) {
      if (p.position.y > cutoff) {
        p.removeFromParent();
        return true;
      }
      return false;
    });
  }

  int get currentScore => score;
  int get currentBest => bestScore;
}
