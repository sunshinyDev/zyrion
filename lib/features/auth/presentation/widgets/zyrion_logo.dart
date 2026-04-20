import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ZyrionLogo extends StatelessWidget {
  final double size;

  const ZyrionLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF2A0A5E), Color(0xFF050510)],
          center: Alignment(-0.3, -0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.55),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.04,
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(0.25),
            blurRadius: size * 0.9,
            spreadRadius: size * 0.08,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hexagon border
          CustomPaint(
            size: Size(size * 0.88, size * 0.88),
            painter: _HexPainter(),
          ),
          // Alien face
          Text(
            '👽',
            style: TextStyle(fontSize: size * 0.44),
          ),
          // Play badge bottom-right
          Positioned(
            bottom: size * 0.1,
            right: size * 0.1,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.7),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: size * 0.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF7B2FFF),
          Color(0xFF00E5FF),
          Color(0xFFFF2D78),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 * 0.92;
    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
