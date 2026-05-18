import 'package:flutter/material.dart';
import '../score_service.dart';
import 'dart:math' as math;
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bestScore = ScoreService.getBestScore();

    return Scaffold(
      backgroundColor: const Color(0xFF060612),
      body: Stack(
        children: [
          // Starfield background (CSS-like gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF1A1040), Color(0xFF060612)],
              ),
            ),
          ),

          // Animated orbit illustration (simple circles)
          const Positioned.fill(child: _OrbitIllustration()),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0097A7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'VOIDLEAP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Navigate the cosmos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Best score
                if (bestScore > 0) ...[
                  Text(
                    'BEST SCORE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$bestScore',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Play button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'PLAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 5,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _Instruction(
                        icon: Icons.touch_app,
                        text: 'Tap & hold for direction and speed control',
                      ),
                      const SizedBox(height: 8),
                      _Instruction(
                        icon: Icons.radio_button_unchecked,
                        text: 'Release when aligned with the next orbit',
                      ),
                      const SizedBox(height: 8),
                      _Instruction(
                        icon: Icons.warning_amber,
                        text: 'Avoid obstacles & black holes',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Instruction({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white30, size: 16),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _OrbitIllustration extends StatefulWidget {
  const _OrbitIllustration();

  @override
  State<_OrbitIllustration> createState() => _OrbitIllustrationState();
}

class _OrbitIllustrationState extends State<_OrbitIllustration>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) =>
          CustomPaint(painter: _OrbitPainter(_ctrl.value), size: Size.infinite),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double t;
  _OrbitPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.38;

    // Orbit ring
    canvas.drawCircle(
      Offset(cx, cy),
      80,
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Outer ring
    canvas.drawCircle(
      Offset(cx, cy),
      130,
      Paint()
        ..color = Colors.white.withOpacity(0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Planet
    canvas.drawCircle(
      Offset(cx, cy),
      18,
      Paint()
        ..color = const Color(0xFF7C4DFF).withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      14,
      Paint()..color = const Color(0xFF7C4DFF),
    );

    // Orbiting dot
    final angle = t * 2 * 3.14159;
    final dotX = cx + 80 * (cos(angle) as double);
    final dotY = cy + 80 * (sin(angle) as double);
    canvas.drawCircle(
      Offset(dotX, dotY),
      7,
      Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()..color = const Color(0xFF00E5FF),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t;
}

double cos(double x) => (x.isNaN) ? 0 : _mathCos(x);
double sin(double x) => (x.isNaN) ? 0 : _mathSin(x);

double _mathCos(double x) {
  return math.cos(x);
}

double _mathSin(double x) {
  return math.sin(x);
}
