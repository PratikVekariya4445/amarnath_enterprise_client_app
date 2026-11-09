import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Reusable Option Card for "My Details" and "Change Password" matching reference design.
class ProfileOptionCard extends StatelessWidget {
  const ProfileOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget illustration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 7.dp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.dp),
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.dp),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 16.dp),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ==========================================
                // 1. Left Mint Icon Container
                // ==========================================
                Container(
                  width: 46.dp,
                  height: 46.dp,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF9E7),
                    borderRadius: BorderRadius.circular(14.dp),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 26.dp,
                      color: const Color(0xFF087A42),
                    ),
                  ),
                ),

                SizedBox(width: 14.dp),

                // ==========================================
                // 2. Center Content (Title & Subtitle)
                // ==========================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111111),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3.dp),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: const Color(0xFF454545),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 6.dp),

                // ==========================================
                // 3. Right Subtle Green Illustration
                // ==========================================
                illustration,

                SizedBox(width: 4.dp),

                // ==========================================
                // 4. Trailing Chevron
                // ==========================================
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22.dp,
                  color: const Color(0xFF333333),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
