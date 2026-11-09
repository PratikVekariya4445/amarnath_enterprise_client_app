import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Top App Header for Home Screen.
///
/// Features:
/// - Left: Hamburger menu icon button.
/// - Center: Amarnath Enterprise company logo.
/// - Right: Notification bell icon with unread indicator badge.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.onMenuPressed,
    this.onNotificationPressed,
    this.hasUnreadNotifications = true,
  });

  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationPressed;
  final bool hasUnreadNotifications;

  static const String _logoPath =
      'assets/images/amarnath_enterprise_client_app_logo.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54.dp,
      padding: EdgeInsets.symmetric(horizontal: 16.dp),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Left Hamburger Menu
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onMenuPressed,
              borderRadius: BorderRadius.circular(12.dp),
              child: Container(
                width: 42.dp,
                height: 42.dp,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12.dp),
                  border: Border.all(
                    color: const Color(0x33E1EAE4),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: AppColors.primaryDarkGreen,
                  size: 24.dp,
                ),
              ),
            ),
          ),

          // 2. Center Brand Logo
          Flexible(
            child: SizedBox(
              height: 38.dp,
              child: Image.asset(
                _logoPath,
                fit: BoxFit.contain,
                semanticLabel: 'Amarnath Enterprise Logo',
              ),
            ),
          ),

          // 3. Right Notification Bell with Unread Badge
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNotificationPressed,
              borderRadius: BorderRadius.circular(12.dp),
              child: Container(
                width: 42.dp,
                height: 42.dp,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12.dp),
                  border: Border.all(
                    color: const Color(0x33E1EAE4),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textDark,
                      size: 23.dp,
                    ),
                    if (hasUnreadNotifications)
                      Positioned(
                        top: -1,
                        right: 1,
                        child: Container(
                          width: 8.dp,
                          height: 8.dp,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
