import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Personalized greeting section for the authenticated Client.
///
/// Example: `Hello, Monika! 👋`
/// Subtitle: `Find products, check availability and place your order.`
class WelcomeSection extends StatelessWidget {
  const WelcomeSection({
    super.key,
    required this.clientName,
  });

  /// The authenticated client's display name.
  final String clientName;

  @override
  Widget build(BuildContext context) {
    final displayName =
        clientName.trim().isNotEmpty ? clientName.trim() : 'Client';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.dp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Hello, ',
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(
                  text: '$displayName!',
                  style: const TextStyle(
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
                TextSpan(
                  text: ' 👋',
                  style: TextStyle(
                    fontSize: 20.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5.dp),
          Text(
            'Find products, check availability and place your order.',
            style: TextStyle(
              fontSize: 12.5.sp,
              color: AppColors.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
