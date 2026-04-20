import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/zyrion_logo.dart';

// Navigation is handled entirely by the router's refreshListenable (AuthNotifier).
// This page just shows the brand while the router decides where to go.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _StarField(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ZyrionLogo(size: 120),
                const SizedBox(height: 28),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.neonGradient.createShader(bounds),
                  child: const Text(
                    'ZYRION',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PLAY',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'O universo do entretenimento',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _StarPainter(),
    );
  }
}

class _StarPainter extends CustomPainter {
  static const _stars = [
    [0.1, 0.05, 1.5], [0.3, 0.12, 1.0], [0.7, 0.08, 2.0],
    [0.9, 0.15, 1.2], [0.15, 0.25, 1.8], [0.5, 0.18, 1.0],
    [0.8, 0.3, 1.5], [0.05, 0.45, 1.2], [0.95, 0.4, 1.0],
    [0.25, 0.6, 1.8], [0.6, 0.55, 1.3], [0.85, 0.65, 1.0],
    [0.4, 0.75, 1.5], [0.75, 0.8, 2.0], [0.1, 0.85, 1.2],
    [0.55, 0.9, 1.0], [0.9, 0.92, 1.5], [0.35, 0.35, 1.0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in _stars) {
      paint.color = Colors.white.withOpacity(0.4 + (s[2] as double) * 0.2);
      canvas.drawCircle(
        Offset(size.width * (s[0] as double), size.height * (s[1] as double)),
        s[2] as double,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
