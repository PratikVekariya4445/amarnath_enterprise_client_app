import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/widgets/custom_auth_text_field.dart';

/// Amarnath Enterprise Client App Forgot Password Screen.
///
/// Reproduces the reference layout:
/// - Full-screen botanical mint background
/// - Top-left white rounded back button with dark-green arrow
/// - Centered company logo
/// - "Forgot Password?" header with "Password?" in brand dark green
/// - Explanatory subtitle in muted grey
/// - Rounded white form card with Mobile Number field
/// - Full-width dark-green gradient "Send OTP" button
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.authRepository,
    this.onSendOtp,
    this.onBack,
    this.onOtpSent,
  });

  /// Injected repository (defaults to [AuthRepositoryImpl]).
  final AuthRepository? authRepository;

  /// Optional callback invoked when Send OTP is initiated with the normalized mobile number.
  final ValueChanged<String>? onSendOtp;

  /// Optional back navigation callback.
  final VoidCallback? onBack;

  /// Optional callback when OTP has been successfully dispatched.
  final void Function(String verificationId, String mobile)? onOtpSent;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final AuthRepository _authRepository;

  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  bool _isLoading = false;
  String? _mobileError;

  static const String _backgroundImage = 'assets/images/img_splash_bg.png';
  static const String _logoImage =
      'assets/images/amarnath_enterprise_client_app_logo.png';

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _handleSendOtp() async {
    if (_isLoading) return;

    setState(() => _mobileError = null);

    final mobile = _mobileController.text.trim();
    final validationError = MobileNumberUtils.validateMobile(mobile);
    if (validationError != null) {
      setState(() => _mobileError = validationError);
      return;
    }

    final normalized = MobileNumberUtils.normalizeMobileNumber(mobile);

    if (widget.onSendOtp != null) {
      widget.onSendOtp!(normalized);
    }

    setState(() => _isLoading = true);

    try {
      await _authRepository.sendPasswordResetOtp(
        mobile: normalized,
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() => _isLoading = false);

          if (widget.onOtpSent != null) {
            widget.onOtpSent!(verificationId, normalized);
          } else {
            _showSuccessDialog(normalized);
          }
        },
        onVerificationFailed: (errorMessage) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showErrorSnackBar(errorMessage);
        },
        onVerificationCompleted: (_) {
          if (!mounted) return;
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _showSuccessDialog(String mobile) async {
    final masked = mobile.length == 10
        ? '+91 ${mobile.substring(0, 2)}••••••${mobile.substring(8)}'
        : mobile;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.dp),
          ),
          icon: Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.primaryDarkGreen,
            size: 50.dp,
          ),
          title: Text(
            'OTP Sent',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          content: Text(
            'A 6-digit verification code has been sent to $masked. Please check your messages to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actionsPadding: EdgeInsets.only(
            left: 20.dp,
            right: 20.dp,
            bottom: 20.dp,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48.dp,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.dp),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.statusRejected,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16.dp),
        duration: const Duration(seconds: 4),
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
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-Screen Botanical Background
            Image.asset(
              _backgroundImage,
              width: 100.w,
              height: 100.h,
              fit: BoxFit.cover,
            ),

            // 2. Scrollable Foreground Layer
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: 20.dp),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 1.h),

                      // Top-Left Back Button Row
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleBack,
                            borderRadius: BorderRadius.circular(16.dp),
                            child: Container(
                              width: 44.dp,
                              height: 44.dp,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.dp),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0E000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: AppColors.primaryDarkGreen,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 1.5.h),

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

                      SizedBox(height: 2.2.h),

                      // Forgot Password? Heading
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'Forgot ',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Password?',
                              style: TextStyle(
                                color: AppColors.primaryDarkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 1.h),

                      // Subtitle
                      Text(
                        'No worries! Enter your mobile number\nand we’ll send you an OTP to reset your password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: AppColors.textSecondary,
                          height: 1.35,
                          fontWeight: FontWeight.normal,
                        ),
                      ),

                      SizedBox(height: 2.8.h),

                      // 3. Form Card Container
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground.withValues(
                            alpha: 0.96,
                          ),
                          borderRadius: BorderRadius.circular(30.dp),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0x44E1EAE4),
                            width: 1.0,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.dp,
                          vertical: 22.dp,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mobile Number Input Field
                            CustomAuthTextField(
                              label: 'Mobile Number',
                              hintText: 'Enter your mobile number',
                              leadingIcon: Icons.phone_android_outlined,
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              errorText: _mobileError,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleSendOtp(),
                              onChanged: (_) {
                                if (_mobileError != null) {
                                  setState(() => _mobileError = null);
                                }
                              },
                            ),

                            SizedBox(height: 2.2.h),

                            // Full-Width Gradient Send OTP Button
                            SizedBox(
                              width: double.infinity,
                              height: 52.dp,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppColors.loginButtonGradient,
                                  borderRadius: BorderRadius.circular(20.dp),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryDarkGreen
                                          .withValues(alpha: 0.28),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20.dp),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 22.dp,
                                          height: 22.dp,
                                          child:
                                              const CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Send OTP',
                                              style: TextStyle(
                                                fontSize: 14.5.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            SizedBox(width: 8.dp),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 18.dp,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
