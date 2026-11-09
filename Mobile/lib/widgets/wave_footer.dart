import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class WaveFooter extends StatelessWidget {
  final double? height;

  const WaveFooter({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final effectiveHeight = (height ?? MediaQuery.sizeOf(context).height * 0.16) + bottomInset;

    return IgnorePointer(
      child: SizedBox(
        height: effectiveHeight,
        width: double.infinity,
        child: CustomPaint(
          painter: _WavePainter(),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Back wave (softBlue)
    final backPaint = Paint()
      ..color = AppColors.softBlue
      ..style = PaintingStyle.fill;
    final backPath = Path()
      ..moveTo(0, h * 0.35)
      ..quadraticBezierTo(w * 0.3, h * 0.05, w * 0.65, h * 0.4)
      ..quadraticBezierTo(w * 0.85, h * 0.6, w, h * 0.3)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backPath, backPaint);

    // Layer 2: Mid wave (waveBlue at 65% opacity)
    final midPaint = Paint()
      ..color = AppColors.waveBlue.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    final midPath = Path()
      ..moveTo(0, h * 0.6)
      ..quadraticBezierTo(w * 0.35, h * 0.25, w * 0.7, h * 0.58)
      ..quadraticBezierTo(w * 0.88, h * 0.75, w, h * 0.52)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(midPath, midPaint);

    // Layer 3: Front wave (primaryBlue at 25% opacity)
    final frontPaint = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final frontPath = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.4, h * 0.5, w * 0.78, h * 0.75)
      ..quadraticBezierTo(w * 0.9, h * 0.85, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
