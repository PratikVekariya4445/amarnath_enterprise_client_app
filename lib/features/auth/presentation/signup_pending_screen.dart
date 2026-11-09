import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:amarnath_enterprise_client_app/core/constants/app_constants.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';

/// Screen displayed after a Client successfully submits their registration request.
///
/// Features:
/// - Informs user that account is awaiting Owner verification
/// - Status indicator badge: "Approval Pending"
/// - Contact Owner actions: Call Owner & WhatsApp inquiry
/// - "Back to Login" action clearing navigation stack and signing out
class SignupPendingScreen extends StatefulWidget {
  const SignupPendingScreen({
    super.key,
    this.authRepository,
    this.ownerContactNumber,
    this.onCallOwner,
    this.onWhatsApp,
    this.onBackToLogin,
  });

  final AuthRepository? authRepository;
  final String? ownerContactNumber;
  final VoidCallback? onCallOwner;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onBackToLogin;

  @override
  State<SignupPendingScreen> createState() => _SignupPendingScreenState();
}

class _SignupPendingScreenState extends State<SignupPendingScreen> {
  late final AuthRepository _authRepository;
  String _ownerNumber = AppConstants.ownerContactNumber;

  static const String _backgroundImage = 'assets/images/img_splash_bg.png';
  static const String _logoImage =
      'assets/images/amarnath_enterprise_client_app_logo.png';

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
    if (widget.ownerContactNumber != null &&
        widget.ownerContactNumber!.isNotEmpty) {
      _ownerNumber = widget.ownerContactNumber!;
    } else {
      _loadOwnerNumber();
    }
  }

  Future<void> _loadOwnerNumber() async {
    try {
      final number = await _authRepository.getOwnerContactNumber();
      if (mounted && number.isNotEmpty) {
        setState(() => _ownerNumber = number);
      }
    } catch (_) {}
  }

  Future<void> _handleCallOwner() async {
    if (widget.onCallOwner != null) {
      widget.onCallOwner!();
      return;
    }

    final clean = _ownerNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: clean);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        _showSnackBar('Could not launch phone dialer for $_ownerNumber');
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Could not launch phone dialer for $_ownerNumber');
    }
  }

  Future<void> _handleWhatsApp() async {
    if (widget.onWhatsApp != null) {
      widget.onWhatsApp!();
      return;
    }

    final digits = _ownerNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMessage =
        Uri.encodeComponent(AppConstants.registrationInquiryMessage);
    final uri = Uri.parse('https://wa.me/$digits?text=$encodedMessage');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        _showSnackBar('Could not launch WhatsApp for $_ownerNumber');
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Could not launch WhatsApp for $_ownerNumber');
    }
  }

  Future<void> _handleBackToLogin() async {
    if (widget.onBackToLogin != null) {
      widget.onBackToLogin!();
      return;
    }

    // Ensure session is signed out
    await _authRepository.signOut();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
            // Full-screen botanical mint background
            Image.asset(
              _backgroundImage,
              width: 100.w,
              height: 100.h,
              fit: BoxFit.cover,
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.dp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 2.h),

                    // Centered Brand Logo
                    Center(
                      child: SizedBox(
                        width: 48.w,
                        child: Image.asset(
                          _logoImage,
                          fit: BoxFit.contain,
                          semanticLabel: 'Amarnath Enterprise Logo',
                        ),
                      ),
                    ),

                    SizedBox(height: 2.5.h),

                    // Main Status Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(28.dp),
                        border: Border.all(
                          color: const Color(0x44E1EAE4),
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(22.dp),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Pending / Clock Icon in soft green circle
                          Container(
                            width: 68.dp,
                            height: 68.dp,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5EE),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.schedule_rounded,
                              color: AppColors.primaryDarkGreen,
                              size: 38.dp,
                            ),
                          ),

                          SizedBox(height: 16.dp),

                          // Heading
                          Text(
                            'Registration Submitted!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 19.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),

                          SizedBox(height: 8.dp),

                          // Description
                          Text(
                            'Your registration request has been successfully submitted to Amarnath Enterprise.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),

                          SizedBox(height: 10.dp),

                          // Supporting message
                          Text(
                            'Our owner will review your details. Once your account is approved, you can log in and start exploring our products.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),

                          SizedBox(height: 16.dp),

                          // Approval Pending status pill
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.dp,
                              vertical: 6.dp,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF7F1),
                              borderRadius: BorderRadius.circular(20.dp),
                              border: Border.all(
                                color: const Color(0xFFD6EADA),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: AppColors.primaryDarkGreen,
                                  size: 16.dp,
                                ),
                                SizedBox(width: 6.dp),
                                Flexible(
                                  child: Text(
                                    'Approval Pending',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDarkGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 18.dp),

                    // Contact Owner Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(24.dp),
                        border: Border.all(
                          color: const Color(0x44E1EAE4),
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(18.dp),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Help? Contact Us',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 4.dp),
                          Text(
                            'Have questions about your registration? Get in touch with our team.',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 14.dp),

                          // Two Buttons: Call Owner & WhatsApp Us
                          Row(
                            children: [
                              // 1. Call Owner Button
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _handleCallOwner,
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.dp,
                                      vertical: 12.dp,
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.primaryDarkGreen,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16.dp),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.call_rounded,
                                        size: 16.dp,
                                        color: AppColors.primaryDarkGreen,
                                      ),
                                      SizedBox(width: 4.dp),
                                      Flexible(
                                        child: Text(
                                          'Call Owner',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDarkGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.dp),

                              // 2. WhatsApp Button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _handleWhatsApp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.dp,
                                      vertical: 12.dp,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16.dp),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 16.dp,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4.dp),
                                      Flexible(
                                        child: Text(
                                          'WhatsApp Us',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.dp),

                    // Back to Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.dp,
                      child: ElevatedButton(
                        onPressed: _handleBackToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDarkGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.dp),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Back to Login',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
