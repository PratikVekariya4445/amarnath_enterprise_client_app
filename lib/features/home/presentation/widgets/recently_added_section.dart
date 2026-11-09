import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/product_grid_card.dart';

/// "Recently Added" section for Home Screen:
/// - Header with "Recently Added" and "View All →"
/// - 2-column product grid with actual Firebase products
/// - Empty state: "No products available yet"
class RecentlyAddedSection extends StatelessWidget {
  const RecentlyAddedSection({
    super.key,
    required this.products,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    this.onViewAll,
    this.onProductTap,
  });

  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onViewAll;
  final ValueChanged<Product>? onProductTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Recently Added',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(8.dp),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.dp,
                    vertical: 2.dp,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                      SizedBox(width: 4.dp),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primaryDarkGreen,
                        size: 16.dp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 14.dp),

          // 2. Grid / Loading / Error / Empty Content
          if (isLoading)
            _buildLoadingState()
          else if (errorMessage != null && errorMessage!.isNotEmpty)
            _buildErrorState()
          else if (products.isEmpty)
            _buildEmptyState()
          else
            _buildProductGrid(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.dp, horizontal: 16.dp),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20.dp),
        border: Border.all(
          color: const Color(0xFFFFCDD2),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: Colors.redAccent.withValues(alpha: 0.7),
            size: 36.dp,
          ),
          SizedBox(height: 8.dp),
          Text(
            'Unable to load products',
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(height: 10.dp),
            TextButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 36.dp),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24.dp,
        height: 24.dp,
        child: const CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.primaryDarkGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.dp, horizontal: 16.dp),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20.dp),
        border: Border.all(
          color: const Color(0xFFEBF1EC),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            size: 40.dp,
          ),
          SizedBox(height: 10.dp),
          Text(
            'No products available yet',
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4.dp),
          Text(
            'New catalog items will appear here once added.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14.dp,
        mainAxisSpacing: 14.dp,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductGridCard(
          product: product,
          onTap: () {
            if (onProductTap != null) {
              onProductTap!(product);
            }
          },
        );
      },
    );
  }
}
