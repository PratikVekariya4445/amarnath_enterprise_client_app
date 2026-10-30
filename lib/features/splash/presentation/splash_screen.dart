import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/login_screen.dart';

/// Splash Screen for Amarnath Enterprise Client App.
///
/// Displays a full-screen botanical mint background with the centered brand logo
/// and a delicate dark-green circular loading indicator below.
class SplashScreen extends StatefulWidget {
  /// The next screen to navigate to after the splash duration completes.
  /// If null, navigates to a default placeholder screen.
  final Widget? nextScreen;

  /// Duration to display the splash screen before navigating.
  /// Defaults to 2.5 seconds (within the 2–3s requirement).
  final Duration duration;

  const SplashScreen({
    super.key,
    this.nextScreen,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _hasNavigated = false;

  static const String _backgroundImage = 'assets/images/img_splash_bg.png';
  static const String _logoImage =
      'assets/images/amarnath_enterprise_client_app_logo.png';
  static const Color _brandDarkGreen = Color(0xFF015734);
  static const Color _brandTrackColor = Color(0x26015734);

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache splash assets for instant and smooth rendering without pop-in.
    precacheImage(const AssetImage(_backgroundImage), context);
    precacheImage(const AssetImage(_logoImage), context);
  }

  void _startSplashTimer() {
    _timer = Timer(widget.duration, _handleNavigation);
  }

  Future<void> _handleNavigation() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Widget destination;
    if (widget.nextScreen != null) {
      destination = widget.nextScreen!;
    } else {
      // Check existing authenticated client session
      final client = await AuthRepositoryImpl().getCurrentApprovedClient();
      if (client != null) {
        destination = const _DefaultPlaceholderScreen();
      } else {
        destination = const LoginScreen();
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen background image matching reference design
            Image.asset(
              _backgroundImage,
              width: 100.w,
              height: 100.h,
              fit: BoxFit.cover,
            ),

            // Content layer: horizontally centered logo and loader
            SafeArea(
              child: Column(
                children: [
                  // Upper spacer to place the logo slightly above the exact midpoint
                  const Spacer(flex: 30),

                  // Amarnath Enterprise Brand Logo
                  Center(
                    child: SizedBox(
                      width: 62.w,
                      child: Image.asset(
                        _logoImage,
                        fit: BoxFit.contain,
                        semanticLabel: 'Amarnath Enterprise Logo',
                      ),
                    ),
                  ),

                  // Middle spacer matching the reference distance between logo and loader
                  const Spacer(flex: 18),

                  // Dark-green circular loading indicator
                  SizedBox(
                    width: 7.5.w,
                    height: 7.5.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_brandDarkGreen),
                      backgroundColor: _brandTrackColor,
                    ),
                  ),

                  // Lower spacer balancing bottom area
                  const Spacer(flex: 26),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback placeholder screen if no nextScreen is supplied and no existing
/// authentication/home route is hooked up yet.
class _DefaultPlaceholderScreen extends StatelessWidget {
  const _DefaultPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amarnath Enterprise Client'),
        backgroundColor: const Color(0xFF015734),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Amarnath Enterprise Client App',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
