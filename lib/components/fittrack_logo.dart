import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Minimalist FitTrack app logo.
///
/// Renders a rounded square with a violet gradient and a white
/// lightning-bolt symbol — scalable to any [size].
class FitTrackLogo extends StatelessWidget {
  final double size;
  const FitTrackLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryMid, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.38),
            blurRadius: size * 0.30,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.50, size * 0.60),
          painter: _BoltPainter(),
        ),
      ),
    );
  }
}

/// Draws a clean white lightning-bolt.
class _BoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Lightning bolt path (geometric, flat top-right to bottom-left)
    final path = Path()
      ..moveTo(w * 0.60, 0)          // top-right of upper segment
      ..lineTo(w * 0.05, h * 0.52)   // middle-left tip
      ..lineTo(w * 0.48, h * 0.52)   // inner notch
      ..lineTo(w * 0.40, h)          // bottom of lower segment
      ..lineTo(w * 0.95, h * 0.48)   // middle-right tip
      ..lineTo(w * 0.52, h * 0.48)   // inner notch
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
