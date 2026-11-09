import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Large elevated profile information card overlapping the green wave header.
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.name,
    required this.shopName,
    required this.mobile,
    this.onEditProfile,
    this.onAvatarTap,
  });

  final String name;
  final String shopName;
  final String mobile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.dp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.dp),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1400864D),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.dp, vertical: 16.dp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ==========================================
          // A. Profile / Shop Icon + Camera Badge
          // ==========================================
          GestureDetector(
            onTap: onAvatarTap ?? onEditProfile,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70.dp,
                  height: 70.dp,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDFF9E7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 38.dp,
                      color: const Color(0xFF087A42),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24.dp,
                    height: 24.dp,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00864D),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.dp),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 12.dp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12.dp),

          // Vertical divider
          Container(
            width: 1.dp,
            height: 44.dp,
            color: const Color(0xFFE5E7EB),
          ),

          SizedBox(width: 12.dp),

          // ==========================================
          // B. Profile Details (Name, Shop, Mobile)
          // ==========================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Client',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111111),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.dp),
                Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 13.5.dp,
                      color: const Color(0xFF087A42),
                    ),
                    SizedBox(width: 4.dp),
                    Expanded(
                      child: Text(
                        shopName.isNotEmpty ? shopName : 'Business Shop',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF454545),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.dp),
                Row(
                  children: [
                    Icon(
                      Icons.call_outlined,
                      size: 13.5.dp,
                      color: const Color(0xFF087A42),
                    ),
                    SizedBox(width: 4.dp),
                    Text(
                      mobile.isNotEmpty ? mobile : '—',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 6.dp),

          // ==========================================
          // C. Edit Profile Button
          // ==========================================
          InkWell(
            onTap: onEditProfile,
            borderRadius: BorderRadius.circular(20.dp),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.dp, vertical: 6.dp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.dp),
                border: Border.all(
                  color: const Color(0xFF24B875),
                  width: 1.2.dp,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 13.dp,
                    color: const Color(0xFF087A42),
                  ),
                  SizedBox(width: 3.dp),
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF087A42),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
