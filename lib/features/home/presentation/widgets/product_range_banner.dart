import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Promotional banner matching the Home Screen reference:
/// - Text: "Explore Our Product Range" with "Product Range" in dark green
/// - Subtitle: "Wide variety of products available for your business"
/// - 4-dot carousel indicator at bottom-left
/// - Cardboard package boxes with Amarnath logo & botanical leaves on right
/// - Tapping navigates to Browse Products
class ProductRangeBanner extends StatelessWidget {
  const ProductRangeBanner({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.dp),
      child: Container(
        height: 148.dp,
        decoration: BoxDecoration(
          color: const Color(0xFFFDF8F3),
          borderRadius: BorderRadius.circular(24.dp),
          border: Border.all(
            color: const Color(0xFFF3EAE0),
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24.dp),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24.dp),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.dp),
              child: Stack(
                children: [
                  // Right side decorative stacked boxes artwork
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 48.w,
                    child: const _BannerArtwork(),
                  ),

                  // Left side Content
                  Padding(
                    padding: EdgeInsets.all(16.dp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: 'Explore Our\n',
                                style: TextStyle(
                                  fontSize: 17.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  height: 1.2,
                                  letterSpacing: -0.3,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Product Range',
                                    style: TextStyle(
                                      color: AppColors.primaryDarkGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 6.dp),
                            Text(
                              'Wide variety of products\navailable for your business',
                              style: TextStyle(
                                fontSize: 11.2.sp,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),

                        // Carousel Dots Indicator (4 dots)
                        Row(
                          children: [
                            Container(
                              width: 16.dp,
                              height: 6.dp,
                              decoration: BoxDecoration(
                                color: AppColors.primaryDarkGreen,
                                borderRadius: BorderRadius.circular(3.dp),
                              ),
                            ),
                            SizedBox(width: 5.dp),
                            for (int i = 0; i < 3; i++) ...[
                              Container(
                                width: 6.dp,
                                height: 6.dp,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD9D9D9),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (i < 2) SizedBox(width: 5.dp),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerArtwork extends StatelessWidget {
  const _BannerArtwork();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BannerArtworkPainter(),
        );
      },
    );
  }
}

class _BannerArtworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw botanical sage leaves in background on the top-right
    final leafPaint = Paint()
      ..color = const Color(0xFF3F7753).withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;

    final leafStemPaint = Paint()
      ..color = const Color(0xFF356546)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Stem path curving from bottom right up
    final stemPath = Path()
      ..moveTo(w * 0.96, h * 0.8)
      ..quadraticBezierTo(w * 0.88, h * 0.35, w * 0.92, h * 0.08);
    canvas.drawPath(stemPath, leafStemPaint);

    // Leaves on stem
    void drawLeaf(double cx, double cy, double rx, double ry, double angleRad) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angleRad);
      final leaf = Path()
        ..moveTo(0, -ry)
        ..quadraticBezierTo(rx, 0, 0, ry)
        ..quadraticBezierTo(-rx, 0, 0, -ry)
        ..close();
      canvas.drawPath(leaf, leafPaint);
      canvas.restore();
    }

    drawLeaf(w * 0.92, h * 0.12, 8, 18, -0.3);
    drawLeaf(w * 0.85, h * 0.24, 7, 16, -0.8);
    drawLeaf(w * 0.96, h * 0.32, 7, 16, 0.6);
    drawLeaf(w * 0.88, h * 0.44, 7, 16, -0.6);

    // 2. Cardboard package boxes
    // Colors for cardboard surfaces
    final frontPaint = Paint()..color = const Color(0xFFE5B982);
    final topPaint = Paint()..color = const Color(0xFFF0CE9E);
    final sidePaint = Paint()..color = const Color(0xFFCE9E68);
    final borderPaint = Paint()
      ..color = const Color(0xFFB58450)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final logoPaint = Paint()
      ..color = const Color(0xFF075C3F)
      ..style = PaintingStyle.fill;

    void drawBox({
      required double x,
      required double y,
      required double boxW,
      required double boxH,
      required double depthX,
      required double depthY,
      bool drawLogo = true,
    }) {
      // Front face
      final frontRect = Rect.fromLTWH(x, y, boxW, boxH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(frontRect, const Radius.circular(3)),
        frontPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(frontRect, const Radius.circular(3)),
        borderPaint,
      );

      // Top face
      final topPath = Path()
        ..moveTo(x, y)
        ..lineTo(x + depthX, y - depthY)
        ..lineTo(x + boxW + depthX, y - depthY)
        ..lineTo(x + boxW, y)
        ..close();
      canvas.drawPath(topPath, topPaint);
      canvas.drawPath(topPath, borderPaint);

      // Right side face
      final sidePath = Path()
        ..moveTo(x + boxW, y)
        ..lineTo(x + boxW + depthX, y - depthY)
        ..lineTo(x + boxW + depthX, y + boxH - depthY)
        ..lineTo(x + boxW, y + boxH)
        ..close();
      canvas.drawPath(sidePath, sidePaint);
      canvas.drawPath(sidePath, borderPaint);

      // Centered mini "A" leaf logo on front face
      if (drawLogo) {
        final lX = x + (boxW / 2);
        final lY = y + (boxH / 2);
        final aPath = Path()
          ..moveTo(lX, lY - 6)
          ..lineTo(lX + 4.5, lY + 5)
          ..lineTo(lX + 2, lY + 5)
          ..lineTo(lX + 0.8, lY + 1.5)
          ..lineTo(lX - 0.8, lY + 1.5)
          ..lineTo(lX - 2, lY + 5)
          ..lineTo(lX - 4.5, lY + 5)
          ..close();
        canvas.drawPath(aPath, logoPaint);

        // Leaf accent on A
        final leafAccent = Path()
          ..moveTo(lX + 1.5, lY - 3)
          ..quadraticBezierTo(lX + 6, lY - 6, lX + 6, lY - 1)
          ..quadraticBezierTo(lX + 3.5, lY, lX + 1.5, lY - 3)
          ..close();
        canvas.drawPath(leafAccent, logoPaint);
      }
    }

    // Stacked boxes arrangement:
    // Bottom-Left Box
    drawBox(
      x: w * 0.15,
      y: h * 0.52,
      boxW: w * 0.38,
      boxH: h * 0.38,
      depthX: 14,
      depthY: 10,
    );

    // Bottom-Right Box
    drawBox(
      x: w * 0.54,
      y: h * 0.55,
      boxW: w * 0.38,
      boxH: h * 0.36,
      depthX: 14,
      depthY: 10,
    );

    // Top Centered Box (stacked on top)
    drawBox(
      x: w * 0.38,
      y: h * 0.22,
      boxW: w * 0.40,
      boxH: h * 0.35,
      depthX: 14,
      depthY: 10,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
