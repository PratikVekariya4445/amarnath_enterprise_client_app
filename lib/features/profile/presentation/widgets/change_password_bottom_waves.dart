import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Decorative layered mint green waves at the bottom of the Change Password screen.
///
/// Features 3 smooth curved pastel layers:
/// - Layer 1 (deepest): #E1F8EC
/// - Layer 2 (middle):  #D2F3E1
/// - Layer 3 (front):   #C4EFDA
class ChangePasswordBottomWaves extends StatelessWidget {
  const ChangePasswordBottomWaves({
    super.key,
    this.height,
  });

  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height ?? 130.dp,
      child: CustomPaint(
        painter: _ChangePasswordBottomWavesPainter(),
      ),
    );
  }
}

class _ChangePasswordBottomWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1 (deepest / back): #E1F8EC
    final paintLayer1 = Paint()
      ..color = const Color(0xFFE1F8EC)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, h * 0.45);
    path1.quadraticBezierTo(w * 0.22, h * 0.15, w * 0.52, h * 0.40);
    path1.quadraticBezierTo(w * 0.78, h * 0.62, w, h * 0.35);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, paintLayer1);

    // Layer 2 (middle): #D2F3E1
    final paintLayer2 = Paint()
      ..color = const Color(0xFFD2F3E1)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, h * 0.62);
    path2.quadraticBezierTo(w * 0.28, h * 0.35, w * 0.60, h * 0.55);
    path2.quadraticBezierTo(w * 0.82, h * 0.70, w, h * 0.52);
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, paintLayer2);

    // Layer 3 (front / bottom): #C4EFDA
    final paintLayer3 = Paint()
      ..color = const Color(0xFFC4EFDA)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(0, h * 0.78);
    path3.quadraticBezierTo(w * 0.35, h * 0.56, w * 0.70, h * 0.72);
    path3.quadraticBezierTo(w * 0.88, h * 0.80, w, h * 0.68);
    path3.lineTo(w, h);
    path3.lineTo(0, h);
    path3.close();
    canvas.drawPath(path3, paintLayer3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
