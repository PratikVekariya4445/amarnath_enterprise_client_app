import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Decorative Security Shield & Lock illustration matching the Change Password design reference.
///
/// Features:
/// - Soft mint background oval/blob (#DDF8E8).
/// - Radiating decorative green ticks.
/// - Heraldic shield with green gradient stroke and soft mint interior fill.
/// - Centered dark green padlock (#00864D) with shackle and keyhole cutout.
/// - Overlapping horizontal white password pill with 6 green asterisks (* * * * * *).
class SecurityShieldIllustration extends StatelessWidget {
  const SecurityShieldIllustration({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final w = width ?? 150.dp;
    final h = height ?? 120.dp;

    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: _SecurityShieldPainter(),
      ),
    );
  }
}

class _SecurityShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.46;

    // 1. Soft mint background blob/oval (#DDF8E8)
    final glowPaint = Paint()
      ..color = const Color(0xFFDDF8E8)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: w * 0.82,
        height: h * 0.76,
      ),
      glowPaint,
    );

    // 2. Radiating decorative green ticks (#16A765)
    final tickPaint = Paint()
      ..color = const Color(0xFF16A765)
      ..strokeWidth = 2.4.dp
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left ticks
    canvas.drawLine(
      Offset(cx - w * 0.28, cy - h * 0.26),
      Offset(cx - w * 0.36, cy - h * 0.38),
      tickPaint,
    );
    canvas.drawLine(
      Offset(cx - w * 0.35, cy - h * 0.12),
      Offset(cx - w * 0.44, cy - h * 0.15),
      tickPaint,
    );

    // Top-right ticks
    canvas.drawLine(
      Offset(cx + w * 0.28, cy - h * 0.26),
      Offset(cx + w * 0.36, cy - h * 0.38),
      tickPaint,
    );
    canvas.drawLine(
      Offset(cx + w * 0.35, cy - h * 0.12),
      Offset(cx + w * 0.44, cy - h * 0.15),
      tickPaint,
    );

    // Bottom-right ticks
    canvas.drawLine(
      Offset(cx + w * 0.32, cy + h * 0.24),
      Offset(cx + w * 0.41, cy + h * 0.34),
      tickPaint,
    );
    canvas.drawLine(
      Offset(cx + w * 0.23, cy + h * 0.32),
      Offset(cx + w * 0.29, cy + h * 0.43),
      tickPaint,
    );

    // 3. Shield dimensions & path
    final sw = w * 0.52; // Shield width
    final sh = h * 0.74; // Shield height
    final top = cy - sh * 0.52;
    final bottom = top + sh;

    final shieldPath = Path();
    shieldPath.moveTo(cx, top);
    // Crest to right shoulder
    shieldPath.quadraticBezierTo(
      cx + sw * 0.26,
      top - sh * 0.02,
      cx + sw / 2,
      top + sh * 0.10,
    );
    // Right side down towards bottom tip
    shieldPath.quadraticBezierTo(
      cx + sw * 0.52,
      top + sh * 0.60,
      cx,
      bottom,
    );
    // Bottom tip up to left shoulder
    shieldPath.quadraticBezierTo(
      cx - sw * 0.52,
      top + sh * 0.60,
      cx - sw / 2,
      top + sh * 0.10,
    );
    // Left shoulder back to crest
    shieldPath.quadraticBezierTo(
      cx - sw * 0.26,
      top - sh * 0.02,
      cx,
      top,
    );
    shieldPath.close();

    // Shield fill gradient (#E8F9F0 -> #D6F6E3)
    final shieldFillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8F9F0), Color(0xFFD6F6E3)],
      ).createShader(Rect.fromLTWH(cx - sw / 2, top, sw, sh))
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldFillPaint);

    // Shield stroke gradient (#16A765 -> #00864D)
    final shieldStrokePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF16A765), Color(0xFF00864D)],
      ).createShader(Rect.fromLTWH(cx - sw / 2, top, sw, sh))
      ..strokeWidth = 3.2.dp
      ..style = PaintingStyle.stroke;
    canvas.drawPath(shieldPath, shieldStrokePaint);

    // 4. Padlock icon centered inside shield
    final lockCenter = Offset(cx, top + sh * 0.38);
    final bodyW = sw * 0.44;
    final bodyH = sh * 0.26;

    // Padlock body
    final bodyPaint = Paint()
      ..color = const Color(0xFF00864D)
      ..style = PaintingStyle.fill;

    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: lockCenter, width: bodyW, height: bodyH),
      Radius.circular(3.5.dp),
    );

    // Padlock shackle loop
    final shacklePaint = Paint()
      ..color = const Color(0xFF00864D)
      ..strokeWidth = 3.6.dp
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shackleW = bodyW * 0.58;
    final shackleH = bodyH * 0.82;
    final shackleBottom = lockCenter.dy - bodyH / 2 + 1.dp;
    final shackleTop = shackleBottom - shackleH;

    final shacklePath = Path()
      ..moveTo(cx - shackleW / 2, shackleBottom)
      ..lineTo(cx - shackleW / 2, shackleTop + shackleW / 2)
      ..arcToPoint(
        Offset(cx + shackleW / 2, shackleTop + shackleW / 2),
        radius: Radius.circular(shackleW / 2),
      )
      ..lineTo(cx + shackleW / 2, shackleBottom);

    canvas.drawPath(shacklePath, shacklePaint);
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Padlock keyhole cutout (white)
    final keyholePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, lockCenter.dy - 1.2.dp), 2.2.dp, keyholePaint);
    final keyholeSlot = Path()
      ..moveTo(cx - 1.1.dp, lockCenter.dy - 1.0.dp)
      ..lineTo(cx + 1.1.dp, lockCenter.dy - 1.0.dp)
      ..lineTo(cx + 1.6.dp, lockCenter.dy + 3.2.dp)
      ..lineTo(cx - 1.6.dp, lockCenter.dy + 3.2.dp)
      ..close();
    canvas.drawPath(keyholeSlot, keyholePaint);

    // 5. Password Pill element overlapping the lower portion of the shield
    final pillCenter = Offset(cx, top + sh * 0.72);
    final pillW = sw * 1.14;
    final pillH = sh * 0.28;
    final pillRect = Rect.fromCenter(center: pillCenter, width: pillW, height: pillH);
    final pillRRect = RRect.fromRectAndRadius(pillRect, Radius.circular(pillH / 2));

    // Pill soft shadow
    final shadowPaint = Paint()
      ..color = const Color(0x18000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawRRect(pillRRect.shift(Offset(0, 1.5.dp)), shadowPaint);

    // Pill white fill
    final pillFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pillRRect, pillFillPaint);

    // Pill green stroke (#00864D)
    final pillStrokePaint = Paint()
      ..color = const Color(0xFF00864D)
      ..strokeWidth = 2.0.dp
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(pillRRect, pillStrokePaint);

    // 6. Six green asterisks (* * * * * *) inside the pill
    final asteriskPaint = Paint()
      ..color = const Color(0xFF00864D)
      ..strokeWidth = 1.7.dp
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final startX = pillCenter.dx - pillW * 0.35;
    final stepX = (pillW * 0.70) / 5;
    final armLength = 2.7.dp;

    for (int i = 0; i < 6; i++) {
      final ax = startX + i * stepX;
      final ay = pillCenter.dy;

      // Draw 3 crossing lines for a symmetrical 6-pointed star asterisk
      for (int angleDeg in [0, 60, 120]) {
        final rad = angleDeg * math.pi / 180;
        final dx = armLength * math.cos(rad);
        final dy = armLength * math.sin(rad);
        canvas.drawLine(
          Offset(ax - dx, ay - dy),
          Offset(ax + dx, ay + dy),
          asteriskPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
