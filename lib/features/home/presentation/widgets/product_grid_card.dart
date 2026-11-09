import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';

/// Product card displayed in the 2-column grid.
///
/// Features:
/// - Rounded white card (`20.dp` radius)
/// - Top product image container with `New` badge
/// - Bold product name
/// - `Item No: {code}` in muted grey
/// - Light-mint pill showing `Sizes: {sizes}`
class ProductGridCard extends StatelessWidget {
  const ProductGridCard({
    super.key,
    required this.product,
    this.onTap,
  });

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final displaySizes = product.displaySizes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.dp),
        border: Border.all(
          color: const Color(0xFFEBF1EC),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.dp),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.dp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Container with "New" Badge
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.dp),
                  ),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFF5F8F6),
                    child: Stack(
                      children: [
                        // Product Image or Industrial Material Placeholder
                        Positioned.fill(
                          child: _buildProductImage(product.imageUrl),
                        ),

                        // "New" Badge in Top-Right
                        if (product.isNew)
                          Positioned(
                            top: 8.dp,
                            right: 8.dp,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.dp,
                                vertical: 3.dp,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2F3E9),
                                borderRadius: BorderRadius.circular(10.dp),
                                border: Border.all(
                                  color: const Color(0xFFC7E6D3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'New',
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDarkGreen,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Info Section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.dp,
                  vertical: 8.dp,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),

                    SizedBox(height: 3.dp),

                    // Item Number
                    Text(
                      'Item No: ${product.code}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    if (displaySizes.isNotEmpty) ...[
                      SizedBox(height: 6.dp),
                      // Light Mint Sizes Pill
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.dp,
                          vertical: 3.dp,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF7F1),
                          borderRadius: BorderRadius.circular(8.dp),
                          border: Border.all(
                            color: const Color(0xFFD6EADA),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Sizes: $displaySizes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C5E45),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      final cleanUrl = imageUrl.trim();
      if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: cleanUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFFF5F8F6),
            alignment: Alignment.center,
            child: SizedBox(
              width: 20.dp,
              height: 20.dp,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryDarkGreen,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildPlaceholderGraphic(),
        );
      } else if (cleanUrl.startsWith('assets/')) {
        return Image.asset(
          cleanUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderGraphic(),
        );
      }
    }
    return _buildPlaceholderGraphic();
  }

  Widget _buildPlaceholderGraphic() {
    return Container(
      color: const Color(0xFFF3F7F4),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primaryDarkGreen.withValues(alpha: 0.4),
        size: 38.dp,
      ),
    );
  }
}
