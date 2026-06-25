import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'powerup_component.dart';

class ActivePowerup {
  final PowerupType type;
  double flashTime;

  ActivePowerup({required this.type, this.flashTime = 0.6});
}

class PowerupHudComponent extends PositionComponent {
  final List<ActivePowerup> activePowerups = [];
  final Vector2 screenSize;

  // Flash animation when a new power-up is collected
  double _flashTime = 0;

  static const double iconSize = 32.0;
  static const double iconGap = 8.0;
  static const double topMargin = 50.0;

  PowerupHudComponent({required this.screenSize})
    : super(position: Vector2.zero());

  /// Add a collected power-up. If same type exists, stack it (not shown as
  /// separate icon — just increments internal count via duplicate entries).
  void addPowerup(PowerupType type) {
    activePowerups.add(ActivePowerup(type: type));
    _flashTime = 0.7;
  }

  /// Remove one instance of [type]. Returns true if it existed.
  bool consumePowerup(PowerupType type) {
    final idx = activePowerups.indexWhere((p) => p.type == type);
    if (idx == -1) return false;
    activePowerups.removeAt(idx);
    return true;
  }

  bool has(PowerupType type) => activePowerups.any((p) => p.type == type);

  int countOf(PowerupType type) =>
      activePowerups.where((p) => p.type == type).length;

  @override
  void update(double dt) {
    if (_flashTime > 0) _flashTime -= dt;
    for (final p in activePowerups) {
      if (p.flashTime > 0) p.flashTime -= dt;
    }
  }

  @override
  void render(Canvas canvas) {
    if (activePowerups.isEmpty) return;

    // Deduplicate for display (group by type, show count badge)
    final grouped = <PowerupType, int>{};
    for (final p in activePowerups) {
      grouped[p.type] = (grouped[p.type] ?? 0) + 1;
    }

    final types = grouped.keys.toList();
    final totalWidth = types.length * iconSize + (types.length - 1) * iconGap;
    final startX = (screenSize.x - totalWidth) / 2;

    for (int i = 0; i < types.length; i++) {
      final type = types[i];
      final count = grouped[type]!;
      final cx = startX + i * (iconSize + iconGap) + iconSize / 2;
      const cy = topMargin + iconSize / 2;

      // Flash highlight when just collected
      final isNew = activePowerups.any(
        (p) => p.type == type && p.flashTime > 0,
      );
      final flashAlpha = isNew ? 0.35 : 0.0;

      _drawIconSlot(canvas, Offset(cx, cy), type, count, flashAlpha);
    }
  }

  void _drawIconSlot(
    Canvas canvas,
    Offset center,
    PowerupType type,
    int count,
    double flashAlpha,
  ) {
    final color = _colorFor(type);
    final r = iconSize / 2;

    // Slot background
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: iconSize, height: iconSize),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: iconSize, height: iconSize),
        const Radius.circular(8),
      ),
      Paint()
        ..color = color.withOpacity(0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Flash glow
    if (flashAlpha > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: iconSize + 8,
            height: iconSize + 8,
          ),
          const Radius.circular(10),
        ),
        Paint()
          ..color = color.withOpacity(flashAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Inner icon (drawn manually, same as PowerupComponent)
    canvas.save();
    canvas.translate(center.dx, center.dy - 2);
    _drawMiniIcon(canvas, type, color, r * 0.48);
    canvas.restore();

    // Count badge (if > 1)
    if (count > 1) {
      final badgeCenter = Offset(center.dx + r * 0.6, center.dy - r * 0.6);
      canvas.drawCircle(badgeCenter, 8, Paint()..color = color);
      final tp = TextPainter(
        text: TextSpan(
          text: '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(badgeCenter.dx - tp.width / 2, badgeCenter.dy - tp.height / 2),
      );
    }
  }

  Color _colorFor(PowerupType type) {
    switch (type) {
      case PowerupType.extraLife:
        return const Color(0xFFFF4081);
      case PowerupType.extraPoints:
        return const Color(0xFFFFD600);
      case PowerupType.stoneCrasher:
        return const Color(0xFFFF6D00);
    }
  }

  void _drawMiniIcon(Canvas canvas, PowerupType type, Color color, double s) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case PowerupType.extraLife:
        final path = Path();
        path.moveTo(0, s * 0.4);
        path.cubicTo(-s * 0.1, -s * 0.2, -s, -s * 0.2, -s, s * 0.4);
        path.cubicTo(-s, s, 0, s * 1.3, 0, s * 1.3);
        path.cubicTo(0, s * 1.3, s, s, s, s * 0.4);
        path.cubicTo(s, -s * 0.2, s * 0.1, -s * 0.2, 0, s * 0.4);
        canvas.save();
        canvas.translate(0, -s * 0.3);
        canvas.drawPath(path, paint);
        canvas.restore();
        break;

      case PowerupType.extraPoints:
        final starPath = Path();
        for (int i = 0; i < 5; i++) {
          final outerAngle = (i * 2 * pi / 5) - pi / 2;
          final innerAngle = outerAngle + pi / 5;
          final ox = cos(outerAngle) * s;
          final oy = sin(outerAngle) * s;
          final ix = cos(innerAngle) * s * 0.42;
          final iy = sin(innerAngle) * s * 0.42;
          if (i == 0) {
            starPath.moveTo(ox, oy);
          } else {
            starPath.lineTo(ox, oy);
          }
          starPath.lineTo(ix, iy);
        }
        starPath.close();
        canvas.drawPath(starPath, paint);
        break;

      case PowerupType.stoneCrasher:
        final boltPath = Path()
          ..moveTo(s * 0.2, -s)
          ..lineTo(-s * 0.3, -s * 0.05)
          ..lineTo(s * 0.15, -s * 0.05)
          ..lineTo(-s * 0.2, s)
          ..lineTo(s * 0.4, -s * 0.2)
          ..lineTo(-s * 0.05, -s * 0.2)
          ..close();
        canvas.drawPath(boltPath, paint);
        break;
    }
  }
}
