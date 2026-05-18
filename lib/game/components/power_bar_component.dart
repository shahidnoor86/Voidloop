import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';

class PowerBarComponent extends PositionComponent {
  bool isVisible = false;
  double _progress = 0.0; // 0.0 to 1.0
  double _direction = 1.0;
  double _time = 0;

  // Bar dimensions
  static const double barWidth = 18.0;
  static const double barHeight = 140.0;
  static const double cornerRadius = 9.0;

  PowerBarComponent({required Vector2 position})
    : super(position: position, anchor: Anchor.center);

  double get currentPower => _progress;

  Color get _indicatorColor {
    if (_progress < 0.30) {
      // Yellow zone — too slow
      return Color.lerp(
        const Color(0xFFFFD600),
        const Color(0xFFAED581),
        _progress / 0.30,
      )!;
    } else if (_progress < 0.70) {
      // Green zone — sweet spot
      return Color.lerp(
        const Color(0xFFAED581),
        const Color(0xFF69F0AE),
        (_progress - 0.30) / 0.40,
      )!;
    } else {
      // Red zone — too fast
      return Color.lerp(
        const Color(0xFFFFAB40),
        const Color(0xFFFF5252),
        (_progress - 0.70) / 0.30,
      )!;
    }
  }

  void show() {
    isVisible = true;
    _progress = 0.0;
    _direction = 1.0;
    _time = 0;
  }

  void hide() {
    isVisible = false;
  }

  @override
  void update(double dt) {
    if (!isVisible) return;
    _time += dt;
    _progress += _direction * GameConstants.powerBarCyclesPerSecond * 2.0 * dt;
    if (_progress >= 1.0) {
      _progress = 1.0;
      _direction = -1.0;
    } else if (_progress <= 0.0) {
      _progress = 0.0;
      _direction = 1.0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(2, 2),
          width: barWidth,
          height: barHeight,
        ),
        const Radius.circular(cornerRadius),
      ),
      Paint()..color = Colors.black.withOpacity(0.4),
    );

    // Track background
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: barWidth, height: barHeight),
      const Radius.circular(cornerRadius),
    );
    canvas.drawRRect(
      trackRect,
      Paint()..color = Colors.white.withOpacity(0.12),
    );

    // Colored fill (full bar, zoned colors)
    final zoneHeight = barHeight / 3;

    // Red zone (top)
    final redRect = Rect.fromLTWH(
      -barWidth / 2,
      -barHeight / 2,
      barWidth,
      zoneHeight,
    );
    canvas.save();
    canvas.clipRRect(trackRect);
    canvas.drawRect(
      redRect,
      Paint()
        ..color = const Color(0xFFFF5252).withOpacity(0.25)
        ..style = PaintingStyle.fill,
    );
    // Green zone (middle)
    final greenRect = Rect.fromLTWH(
      -barWidth / 2,
      -barHeight / 2 + zoneHeight,
      barWidth,
      zoneHeight,
    );
    canvas.drawRect(
      greenRect,
      Paint()
        ..color = const Color(0xFF69F0AE).withOpacity(0.20)
        ..style = PaintingStyle.fill,
    );
    // Yellow zone (bottom)
    final yellowRect = Rect.fromLTWH(
      -barWidth / 2,
      -barHeight / 2 + zoneHeight * 2,
      barWidth,
      zoneHeight,
    );
    canvas.drawRect(
      yellowRect,
      Paint()
        ..color = const Color(0xFFFFD600).withOpacity(0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    // Zone dividers
    final dividerPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(-barWidth / 2, -barHeight / 2 + zoneHeight),
      Offset(barWidth / 2, -barHeight / 2 + zoneHeight),
      dividerPaint,
    );
    canvas.drawLine(
      Offset(-barWidth / 2, -barHeight / 2 + zoneHeight * 2),
      Offset(barWidth / 2, -barHeight / 2 + zoneHeight * 2),
      dividerPaint,
    );

    // Track border
    canvas.drawRRect(
      trackRect,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Indicator knob
    // _progress = 0 → bottom of bar, 1 → top
    final indicatorY = (barHeight / 2) - _progress * barHeight;
    final indicatorColor = _indicatorColor;

    // Knob glow
    canvas.drawCircle(
      Offset(0, indicatorY),
      barWidth * 0.55,
      Paint()
        ..color = indicatorColor.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Knob body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, indicatorY),
          width: barWidth + 6,
          height: 14,
        ),
        const Radius.circular(7),
      ),
      Paint()..color = indicatorColor,
    );

    // Zone label
    String label;
    if (_progress < 0.30) {
      label = 'SLOW';
    } else if (_progress < 0.70) {
      label = 'GO!';
    } else {
      label = 'FAST';
    }

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _indicatorColor,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, barHeight / 2 + 8));
  }
}
