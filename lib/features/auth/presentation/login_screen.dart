import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/widgets/custom_auth_text_field.dart';

/// Amarnath Enterprise Client App Login Screen.
/// Replicates the botanical reference design featuring full-screen mint background,
/// centered brand logo, Welcome Back header, rounded form card, dark green input fields,
/// Remember Me / Forgot Password options, gradient Login button, OR divider, and Sign Up action.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authRepository,
    this.onLoginSuccess,
    this.onForgotPassword,
    this.onSignUp,
  });

  /// Injected repository (defaults to [AuthRepositoryImpl]).
  final AuthRepository? authRepository;

  /// Optional navigation callback on successful client authentication.
  final VoidCallback? onLoginSuccess;

  /// Optional callback when "Forgot Password?" is tapped.
  final VoidCallback? onForgotPassword;

  /// Optional callback when "Sign Up" is tapped.
  final VoidCallback? onSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthRepository _authRepository;

  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  String? _mobileError;
  String? _passwordError;

  static const String _backgroundImage = 'assets/images/img_splash_bg.png';
  static const String _logoImage =
      'assets/images/amarnath_enterprise_client_app_logo.png';

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final saved = await _authRepository.getRememberMe();
      if (mounted && saved.remember && saved.mobile.isNotEmpty) {
        setState(() {
          _rememberMe = true;
          _mobileController.text = saved.mobile;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    // Reset previous inline errors
    setState(() {
      _mobileError = null;
      _passwordError = null;
    });

    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;

    final mobileValidation = MobileNumberUtils.validateMobile(mobile);
    if (mobileValidation != null) {
      setState(() => _mobileError = mobileValidation);
      return;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepository.loginWithMobileAndPassword(
        mobile: mobile,
        password: password,
      );

      // Persist remember me preferences
      await _authRepository.saveRememberMe(
        remember: _rememberMe,
        mobile: mobile,
      );

      if (!mounted) return;

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        // Default navigation: replace with dashboard / home
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  void _handleForgotPassword() {
    if (widget.onForgotPassword != null) {
      widget.onForgotPassword!();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Password reset service: Please contact Amarnath Enterprise support.',
        ),
        backgroundColor: AppColors.primaryDarkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16.dp),
      ),
    );
  }

  void _handleSignUp() {
    if (widget.onSignUp != null) {
      widget.onSignUp!();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Client Registration: Sign up request module will open.',
        ),
        backgroundColor: AppColors.primaryDarkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16.dp),
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

            // 2. Scrollable Content Layer
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
                      SizedBox(height: 2.h),

                      // Upper Centered Brand Logo
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

                      // Welcome Back Heading
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'Welcome ',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Back',
                              style: TextStyle(
                                color: AppColors.primaryDarkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 0.8.h),

                      // Subtitle
                      Text(
                        'Login to your account to manage\nyour orders and rentals',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: AppColors.textSecondary,
                          height: 1.35,
                          fontWeight: FontWeight.normal,
                        ),
                      ),

                      SizedBox(height: 2.6.h),

                      // 3. Login Form Container (White Rounded Card)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground.withValues(alpha: 0.96),
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
                        padding: EdgeInsets.all(20.dp),
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
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (_mobileError != null) {
                                  setState(() => _mobileError = null);
                                }
                              },
                            ),

                            SizedBox(height: 1.8.h),

                            // Password Input Field
                            CustomAuthTextField(
                              label: 'Password',
                              hintText: 'Enter your password',
                              leadingIcon: Icons.lock_outline,
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              errorText: _passwordError,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              onChanged: (_) {
                                if (_passwordError != null) {
                                  setState(() => _passwordError = null);
                                }
                              },
                              trailing: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: EdgeInsets.all(4.dp),
                                  child: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20.dp,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 1.4.h),

                            // Remember Me & Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Remember Me Option
                                Flexible(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6.dp),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20.dp,
                                          height: 20.dp,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (val) {
                                              setState(() {
                                                _rememberMe = val ?? false;
                                              });
                                            },
                                            activeColor:
                                                AppColors.primaryDarkGreen,
                                            checkColor: Colors.white,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4.dp),
                                            ),
                                            side: const BorderSide(
                                              color: AppColors.primaryDarkGreen,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 6.dp),
                                        Flexible(
                                          child: Text(
                                            'Remember me',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5.sp,
                                              color: AppColors.textDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.dp),
                                // Forgot Password Action
                                GestureDetector(
                                  onTap: _handleForgotPassword,
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 6.dp,
                                      horizontal: 2.dp,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        color: AppColors.primaryDarkGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 2.4.h),

                            // Full-Width Gradient Login Button
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
                                  onPressed: _isLoading ? null : _handleLogin,
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
                                          child: const CircularProgressIndicator(
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
                                              'Login',
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

                            SizedBox(height: 2.4.h),

                            // OR Divider
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color: AppColors.dividerColor,
                                    thickness: 1.0,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 14.dp),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                    color: AppColors.dividerColor,
                                    thickness: 1.0,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 2.2.h),

                            // Sign Up Section Box
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _handleSignUp,
                                borderRadius: BorderRadius.circular(16.dp),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.signUpBoxBackground,
                                    borderRadius:
                                        BorderRadius.circular(16.dp),
                                    border: Border.all(
                                      color: AppColors.signUpBoxBorder,
                                      width: 1.0,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14.dp,
                                    horizontal: 16.dp,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'New to Amarnath Enterprise?',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 6.dp),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              fontSize: 13.5.sp,
                                              color:
                                                  AppColors.primaryDarkGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 6.dp),
                                          Icon(
                                            Icons.arrow_forward,
                                            color:
                                                AppColors.primaryDarkGreen,
                                            size: 15.dp,
                                          ),
                                        ],
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
