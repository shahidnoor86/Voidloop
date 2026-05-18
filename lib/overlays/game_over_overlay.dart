import 'package:flutter/material.dart';
import '../game/orbit_game.dart';
import '../score_service.dart';
import 'overlay_button.dart';

class GameOverOverlay extends StatelessWidget {
  final OrbitGame game;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final isNewBest =
        game.currentScore >= ScoreService.getBestScore() &&
        game.currentScore > 0;

    return Material(
      color: Colors.black.withOpacity(0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Death icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF5252), width: 2),
                color: const Color(0xFFFF5252).withOpacity(0.15),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFFF5252),
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 32),

            // Score card
            Container(
              width: 240,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR SCORE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${game.currentScore}',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  if (isNewBest) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        ),
                      ),
                      child: const Text(
                        '★ NEW BEST',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'BEST  ${game.currentBest}',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 40),
            OverlayButton(
              label: 'PLAY AGAIN',
              color: const Color(0xFF00E5FF),
              onTap: onRestart,
            ),
            const SizedBox(height: 16),
            OverlayButton(
              label: 'HOME',
              color: Colors.white12,
              textColor: Colors.white60,
              onTap: onHome,
            ),
          ],
        ),
      ),
    );
  }
}
