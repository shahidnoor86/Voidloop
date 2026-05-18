import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/orbit_game.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/pause_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final OrbitGame _game;

  @override
  void initState() {
    super.initState();
    _game = OrbitGame();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Auto-pause when app goes to background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_game.phase == GamePhase.playing) {
        _game.resumeGame(); // ensure we're in right state before pausing
        _game.pauseGame(); // pause internally
      }
    } else if (state == AppLifecycleState.resumed) {
      // Game remains paused until user explicitly resumes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060612),
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          OrbitGame.pauseOverlay: (context, game) => PauseOverlay(
            game: game as OrbitGame,
            onResume: () => (game as OrbitGame).resumeGame(),
            onHome: () => Navigator.of(context).pop(),
            onRestart: () => (game as OrbitGame).restartGame(),
          ),
          OrbitGame.gameOverOverlay: (context, game) => GameOverOverlay(
            game: game as OrbitGame,
            onRestart: () => (game as OrbitGame).restartGame(),
            onHome: () => Navigator.of(context).pop(),
          ),
        },
      ),
    );
  }
}
