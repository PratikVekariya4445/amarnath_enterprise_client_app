import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Persistent Bottom Navigation Bar for the Client App matching reference design.
///
/// 4 Navigation items in exact order:
/// 1. Home
/// 2. Products
/// 3. My Orders
/// 4. Profile
///
/// Selected tab features:
/// - Pale green rounded pill background (`#E0F8E8`) wrapping icon and label.
/// - Dark green icon and label (`#00864D`).
/// - Inactive tabs styled with muted grey (`#555555`).
/// - Thin top border (`#D9DDE0`).
class ClientBottomNavigationBar extends StatelessWidget {
  const ClientBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD9DDE0),
            width: 1.dp,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64.dp,
          padding: EdgeInsets.symmetric(horizontal: 8.dp, vertical: 4.dp),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(
                index: 0,
                label: 'Home',
                unselectedIcon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
              ),
              _buildTabItem(
                index: 1,
                label: 'Products',
                unselectedIcon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view_rounded,
              ),
              _buildTabItem(
                index: 2,
                label: 'My Orders',
                unselectedIcon: Icons.shopping_cart_outlined,
                selectedIcon: Icons.shopping_cart,
              ),
              _buildTabItem(
                index: 3,
                label: 'Profile',
                unselectedIcon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required IconData unselectedIcon,
    required IconData selectedIcon,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: Center(
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(16.dp),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12.dp : 8.dp,
              vertical: 4.dp,
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE0F8E8) : Colors.transparent,
              borderRadius: BorderRadius.circular(16.dp),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  color: isSelected
                      ? const Color(0xFF00864D)
                      : const Color(0xFF555555),
                  size: 22.dp,
                ),
                SizedBox(height: 2.dp),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF00864D)
                        : const Color(0xFF555555),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
