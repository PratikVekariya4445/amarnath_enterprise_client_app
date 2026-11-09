import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';

/// Full-screen blocking progress overlay displayed when a user logs out.
///
/// Features:
/// - Semi-transparent white background (~90% opacity) covering the entire screen
///   including status bar and navigation bar areas.
/// - Centered circular progress indicator in brand primary green (`#00864D`) of ~58 logical pixels.
/// - "Logging out..." status text in semi-bold 18sp green (`#00864D`), 16dp below the indicator.
/// - Disables back navigation (`PopScope(canPop: false)`) and blocks all touch interactions.
class LogoutProgressDialog extends StatelessWidget {
  const LogoutProgressDialog({super.key});

  /// Primary green color matching the Amarnath Enterprise client theme.
  static const Color primaryGreen = Color(0xFF00864D);

  /// 90% opacity white background covering the full screen (`0xE6FFFFFF`).
  static const Color overlayBackgroundColor = Color(0xE6FFFFFF);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: overlayBackgroundColor,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 58.dp,
                  height: 58.dp,
                  child: CircularProgressIndicator(
                    strokeWidth: 4.5.dp,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(primaryGreen),
                    backgroundColor: const Color(0x2400864D),
                  ),
                ),
                SizedBox(height: 16.dp),
                Text(
                  'Logging out...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryGreen,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
