import 'package:flutter/material.dart';
import '../game/orbit_game.dart';
import 'overlay_button.dart';

class PauseOverlay extends StatelessWidget {
  final OrbitGame game;
  final VoidCallback onResume;
  final VoidCallback onHome;
  final VoidCallback onRestart;

  const PauseOverlay({
    super.key,
    required this.game,
    required this.onResume,
    required this.onHome,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Score: ${game.currentScore}',
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            OverlayButton(
              label: 'RESUME',
              color: const Color(0xFF00E5FF),
              onTap: onResume,
            ),
            const SizedBox(height: 16),
            OverlayButton(
              label: 'RESTART',
              color: const Color(0xFF7C4DFF),
              onTap: onRestart,
            ),
            const SizedBox(height: 16),
            OverlayButton(
              label: 'HOME',
              color: Colors.white24,
              textColor: Colors.white70,
              onTap: onHome,
            ),
          ],
        ),
      ),
    );
  }
}
