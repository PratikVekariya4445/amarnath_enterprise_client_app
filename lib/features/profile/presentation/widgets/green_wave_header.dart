import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Top Header with flowing layered green wave curves and the "Profile" title.
class GreenWaveHeader extends StatelessWidget {
  const GreenWaveHeader({
    super.key,
    required this.title,
    this.height,
  });

  final String title;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final totalHeight = height ?? (180.dp + topPadding);

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Painted Green Waves
          CustomPaint(
            size: Size(double.infinity, totalHeight),
            painter: _GreenWavesPainter(),
          ),

          // 2. Profile Title
          Positioned(
            top: topPadding + 10.dp,
            left: 22.dp,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreenWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base background gradient: #00864D -> #00995B -> #18B779
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00864D),
          Color(0xFF00995B),
          Color(0xFF14A86C),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final baseRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(baseRect, basePaint);

    // Layer 1: Deep organic wave
    final wave1Paint = Paint()
      ..color = const Color(0xFF0CA465).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, h * 0.45);
    path1.quadraticBezierTo(w * 0.35, h * 0.30, w * 0.70, h * 0.55);
    path1.quadraticBezierTo(w * 0.88, h * 0.68, w, h * 0.52);
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, wave1Paint);

    // Layer 2: Vibrant middle wave (#18B779)
    final wave2Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF18B779),
          Color(0xFF26C987),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.4, w, h * 0.6))
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, h * 0.68);
    path2.cubicTo(
      w * 0.28,
      h * 0.85,
      w * 0.62,
      h * 0.50,
      w,
      h * 0.72,
    );
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, wave2Paint);

    // Layer 3: Soft mint transition wave blending into #F5FAF7
    final wave3Paint = Paint()
      ..color = const Color(0xFF38D595).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(0, h * 0.82);
    path3.quadraticBezierTo(w * 0.45, h * 0.65, w, h * 0.88);
    path3.lineTo(w, h);
    path3.lineTo(0, h);
    path3.close();
    canvas.drawPath(path3, wave3Paint);

    // Layer 4: Soft background blend
    final blendPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFFF5FAF7).withValues(alpha: 0.2),
          const Color(0xFFF5FAF7),
        ],
        stops: const [0.75, 0.90, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, w, h * 0.25), blendPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
