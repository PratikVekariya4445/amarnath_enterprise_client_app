import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Decorative Storefront with Location Pin illustration for the "My Details" card.
class StorefrontIllustration extends StatelessWidget {
  const StorefrontIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72.dp,
      height: 52.dp,
      child: CustomPaint(
        painter: _StorefrontPainter(),
      ),
    );
  }
}

class _StorefrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft mint circular/organic background glow
    final glowPaint = Paint()
      ..color = const Color(0xFFDFF9E7).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.58, h * 0.55),
        width: w * 0.75,
        height: h * 0.85,
      ),
      glowPaint,
    );

    // 2. Base ground line
    final linePaint = Paint()
      ..color = const Color(0xFF24B875).withValues(alpha: 0.5)
      ..strokeWidth = 1.8.dp
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.22, h * 0.86),
      Offset(w * 0.95, h * 0.86),
      linePaint,
    );

    // 3. Shop Building body
    final buildingPaint = Paint()
      ..color = const Color(0xFF087A42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8.dp;

    final buildingRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.42, h * 0.38, w * 0.48, h * 0.46),
      Radius.circular(2.dp),
    );
    canvas.drawRRect(buildingRect, buildingPaint);

    // Door
    final doorPaint = Paint()
      ..color = const Color(0xFF087A42)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.47, h * 0.50, w * 0.12, h * 0.34),
      doorPaint,
    );

    // Window
    final windowPaint = Paint()
      ..color = const Color(0xFF087A42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4.dp;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.65, h * 0.52, w * 0.18, h * 0.18),
      windowPaint,
    );

    // 4. Striped Awning
    final awningPaint = Paint()
      ..color = const Color(0xFF24B875)
      ..style = PaintingStyle.fill;

    final awningPath = Path();
    awningPath.moveTo(w * 0.38, h * 0.38);
    awningPath.lineTo(w * 0.94, h * 0.38);
    awningPath.lineTo(w * 0.90, h * 0.26);
    awningPath.lineTo(w * 0.42, h * 0.26);
    awningPath.close();
    canvas.drawPath(awningPath, awningPaint);

    // Scallops along awning bottom
    final scallopPaint = Paint()
      ..color = const Color(0xFF24B875)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final cx = w * 0.42 + i * (w * 0.10);
      canvas.drawCircle(Offset(cx, h * 0.39), w * 0.045, scallopPaint);
    }

    // 5. Green Location Pin on Left
    final pinPaint = Paint()
      ..color = const Color(0xFF00864D)
      ..style = PaintingStyle.fill;

    final pinCenter = Offset(w * 0.28, h * 0.50);
    final pinRadius = w * 0.11;
    canvas.drawCircle(pinCenter, pinRadius, pinPaint);

    // Pin point
    final pinPath = Path();
    pinPath.moveTo(pinCenter.dx - pinRadius * 0.88, pinCenter.dy + pinRadius * 0.3);
    pinPath.lineTo(pinCenter.dx, pinCenter.dy + pinRadius * 2.1);
    pinPath.lineTo(pinCenter.dx + pinRadius * 0.88, pinCenter.dy + pinRadius * 0.3);
    pinPath.close();
    canvas.drawPath(pinPath, pinPaint);

    // Pin inner white dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinCenter, pinRadius * 0.45, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Decorative Green Shield with Lock illustration for the "Change Password" card.
class ShieldLockIllustration extends StatelessWidget {
  const ShieldLockIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68.dp,
      height: 52.dp,
      child: CustomPaint(
        painter: _ShieldLockPainter(),
      ),
    );
  }
}

class _ShieldLockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft mint organic glow background
    final glowPaint = Paint()
      ..color = const Color(0xFFDFF9E7).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.52),
        width: w * 0.85,
        height: h * 0.85,
      ),
      glowPaint,
    );

    // 2. Shield Path
    final shieldPaint = Paint()
      ..color = const Color(0xFF087A42)
      ..strokeWidth = 2.4.dp
      ..style = PaintingStyle.stroke;

    final cx = w * 0.54;
    final cy = h * 0.48;
    final sw = w * 0.32;
    final sh = h * 0.38;

    final shieldPath = Path();
    shieldPath.moveTo(cx - sw, cy - sh * 0.65);
    shieldPath.quadraticBezierTo(cx, cy - sh * 0.95, cx + sw, cy - sh * 0.65);
    shieldPath.quadraticBezierTo(cx + sw * 0.95, cy + sh * 0.4, cx, cy + sh);
    shieldPath.quadraticBezierTo(cx - sw * 0.95, cy + sh * 0.4, cx - sw, cy - sh * 0.65);
    shieldPath.close();
    canvas.drawPath(shieldPath, shieldPaint);

    // 3. Lock icon inside shield
    final lockBodyPaint = Paint()
      ..color = const Color(0xFF087A42)
      ..style = PaintingStyle.fill;

    // Lock body
    final lbRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + sh * 0.18),
        width: sw * 0.72,
        height: sh * 0.48,
      ),
      Radius.circular(2.dp),
    );
    canvas.drawRRect(lbRect, lockBodyPaint);

    // Keyhole white dot
    final keyholePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + sh * 0.14), 1.6.dp, keyholePaint);

    // Lock shackle (loop)
    final shacklePaint = Paint()
      ..color = const Color(0xFF087A42)
      ..strokeWidth = 2.0.dp
      ..style = PaintingStyle.stroke;

    final shacklePath = Path();
    shacklePath.moveTo(cx - sw * 0.24, cy - sh * 0.05);
    shacklePath.quadraticBezierTo(cx - sw * 0.24, cy - sh * 0.35, cx, cy - sh * 0.35);
    shacklePath.quadraticBezierTo(cx + sw * 0.24, cy - sh * 0.35, cx + sw * 0.24, cy - sh * 0.05);
    canvas.drawPath(shacklePath, shacklePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
