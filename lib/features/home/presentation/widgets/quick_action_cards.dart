import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Two side-by-side Quick Action cards for Home Screen:
/// 1. "Browse Products" -> explores catalog
/// 2. "My Orders" -> tracks client orders
class QuickActionCards extends StatelessWidget {
  const QuickActionCards({
    super.key,
    this.onBrowseTap,
    this.onOrdersTap,
  });

  final VoidCallback? onBrowseTap;
  final VoidCallback? onOrdersTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.dp),
      child: Row(
        children: [
          // 1. Browse Products Card
          Expanded(
            child: _QuickCard(
              title: 'Browse Products',
              subtitle: 'Explore our product\ncollection',
              icon: Icons.grid_view_outlined,
              onTap: onBrowseTap,
            ),
          ),
          SizedBox(width: 14.dp),
          // 2. My Orders Card
          Expanded(
            child: _QuickCard(
              title: 'My Orders',
              subtitle: 'View and track\nyour orders',
              icon: Icons.shopping_bag_outlined,
              onTap: onOrdersTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.dp),
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
        borderRadius: BorderRadius.circular(24.dp),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.dp),
          child: Padding(
            padding: EdgeInsets.all(16.dp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Green Icon container
                Container(
                  width: 44.dp,
                  height: 44.dp,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(14.dp),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryDarkGreen,
                    size: 22.dp,
                  ),
                ),

                SizedBox(height: 14.dp),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: -0.2,
                  ),
                ),

                SizedBox(height: 4.dp),

                // Subtitle + Chevron Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.8.sp,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Container(
                      width: 24.dp,
                      height: 24.dp,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5EE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: AppColors.primaryDarkGreen,
                        size: 16.dp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
