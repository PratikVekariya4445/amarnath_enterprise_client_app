import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Full-width rounded Product Search Bar.
///
/// Features:
/// - Rounded corners (`24.dp`)
/// - Dark-green leading search icon
/// - Hint: `Search by product name or item number...`
/// - When [readOnly] is true, acts as a button invoking [onTap].
class ProductSearchBar extends StatelessWidget {
  const ProductSearchBar({
    super.key,
    this.onTap,
    this.controller,
    this.onChanged,
    this.readOnly = true,
    this.autofocus = false,
  });

  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.dp),
      child: Container(
        height: 50.dp,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.dp),
          border: Border.all(
            color: const Color(0xFFE1EAE4),
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 14,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24.dp),
          child: InkWell(
            onTap: readOnly ? onTap : null,
            borderRadius: BorderRadius.circular(24.dp),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.dp),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: AppColors.primaryDarkGreen,
                    size: 22.dp,
                  ),
                  SizedBox(width: 10.dp),
                  Expanded(
                    child: readOnly
                        ? Text(
                            'Search by product name or item number...',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.85,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : TextField(
                            controller: controller,
                            onChanged: onChanged,
                            autofocus: autofocus,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search by product name or item number...',
                              hintStyle: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
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
