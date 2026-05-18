import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HudComponent extends PositionComponent {
  int score = 0;
  int bestScore = 0;
  int level = 1;

  final Vector2 screenSize;

  final _scoreLabelPainter = TextPainter(textDirection: TextDirection.ltr);
  final _scoreValuePainter = TextPainter(textDirection: TextDirection.ltr);
  final _bestPainter = TextPainter(textDirection: TextDirection.ltr);
  final _levelPainter = TextPainter(textDirection: TextDirection.ltr);

  HudComponent({required this.screenSize})
    : super(position: Vector2.zero(), size: screenSize);

  void updateScore(int newScore, int newBest, int newLevel) {
    score = newScore;
    bestScore = newBest;
    level = newLevel;
  }

  @override
  void render(Canvas canvas) {
    final w = screenSize.x;

    // ── LEFT: Score label ────────────────────────────────────
    _scoreLabelPainter.text = const TextSpan(
      text: 'SCORE',
      style: TextStyle(
        color: Color(0x88FFFFFF),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
    _scoreLabelPainter.layout();
    _scoreLabelPainter.paint(canvas, const Offset(20, 52));

    // ── LEFT: Score value ────────────────────────────────────
    _scoreValuePainter.text = TextSpan(
      text: '$score',
      style: const TextStyle(
        color: Color(0xFF00E5FF),
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
    _scoreValuePainter.layout();
    _scoreValuePainter.paint(canvas, const Offset(20, 64));

    // ── LEFT: Best score ─────────────────────────────────────
    _bestPainter.text = TextSpan(
      text: 'BEST  $bestScore',
      style: const TextStyle(
        color: Color(0x55FFFFFF),
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      ),
    );
    _bestPainter.layout();
    _bestPainter.paint(canvas, const Offset(20, 96));

    // ── RIGHT TOP: Pause button (36×36) ──────────────────────
    // Sits at top-right with 14px margin from edge and 44px from top
    final pauseLeft = w - 50;
    const pauseTop = 44.0;
    const pauseSize = 36.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pauseLeft, pauseTop, pauseSize, pauseSize),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.white.withOpacity(0.14),
    );

    // Pause icon — two vertical bars centred inside the button
    final barPaint = Paint()
      ..color = Colors.white.withOpacity(0.80)
      ..style = PaintingStyle.fill;

    final barCentreX = pauseLeft + pauseSize / 2;
    const barHeight = 16.0;
    const barWidth = 5.0;
    const barGap = 5.0;
    final barTop = pauseTop + (pauseSize - barHeight) / 2;

    // Left bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          barCentreX - barGap / 2 - barWidth,
          barTop,
          barWidth,
          barHeight,
        ),
        const Radius.circular(2),
      ),
      barPaint,
    );
    // Right bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barCentreX + barGap / 2, barTop, barWidth, barHeight),
        const Radius.circular(2),
      ),
      barPaint,
    );

    // ── RIGHT BOTTOM: LVL badge ──────────────────────────────
    // Positioned directly below the pause button with an 8px gap
    _levelPainter.text = TextSpan(
      text: 'LVL  $level',
      style: const TextStyle(
        color: Color(0xCCE040FB),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
    _levelPainter.layout();
    _levelPainter.paint(
      canvas,
      Offset(
        w - _levelPainter.width - 14, // right-align with 14 px margin
        pauseTop + pauseSize + 8, // 8 px below pause button
      ),
    );
  }
}
