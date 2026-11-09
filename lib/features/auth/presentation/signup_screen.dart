import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amarnath_enterprise_client_app/core/theme/app_colors.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/widgets/custom_auth_text_field.dart';

/// Amarnath Enterprise Client App Signup Screen.
///
/// Reproduces the reference layout:
/// - Full-screen botanical mint background
/// - Centered company logo
/// - "Create Account" header with highlighted "Account"
/// - Subtitle in muted grey
/// - 6 input fields in exact order (Full Name, Shop Name, Mobile Number, Address, Password, Confirm Password)
/// - Prominent dark-green gradient "Sign Up" button
/// - OR divider
/// - Outlined "Already have an account? / Login" section
class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    this.authRepository,
    this.onSignupSuccess,
    this.onNavigateToLogin,
  });

  /// Injected repository (defaults to [AuthRepositoryImpl]).
  final AuthRepository? authRepository;

  /// Optional callback executed on successful signup request submission.
  final VoidCallback? onSignupSuccess;

  /// Optional callback to navigate back to the Login screen.
  final VoidCallback? onNavigateToLogin;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final AuthRepository _authRepository;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  String? _nameError;
  String? _shopError;
  String? _mobileError;
  String? _addressError;
  String? _passwordError;
  String? _confirmPasswordError;

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
    _fullNameController.dispose();
    _shopNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;

    // Reset previous errors
    setState(() {
      _nameError = null;
      _shopError = null;
      _mobileError = null;
      _addressError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final name = _fullNameController.text.trim();
    final shopName = _shopNameController.text.trim();
    final mobile = _mobileController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasValidationError = false;

    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter your full name');
      hasValidationError = true;
    }

    if (shopName.isEmpty) {
      setState(() => _shopError = 'Please enter your shop name');
      hasValidationError = true;
    }

    final mobileValidation = MobileNumberUtils.validateMobile(mobile);
    if (mobileValidation != null) {
      setState(() => _mobileError = mobileValidation);
      hasValidationError = true;
    }

    if (address.isEmpty) {
      setState(() => _addressError = 'Please enter your shop address');
      hasValidationError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Please create a password');
      hasValidationError = true;
    } else if (password.length < 6) {
      setState(
        () => _passwordError = 'Password must be at least 6 characters',
      );
      hasValidationError = true;
    }

    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please re-enter your password');
      hasValidationError = true;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasValidationError = true;
    }

    if (hasValidationError) return;

    setState(() => _isLoading = true);

    try {
      await _authRepository.registerClient(
        name: name,
        shopName: shopName,
        mobile: mobile,
        address: address,
        password: password,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (widget.onSignupSuccess != null) {
        widget.onSignupSuccess!();
      } else {
        Navigator.of(context).pushReplacementNamed('/signup-pending');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted && _isLoading) {
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

  void _handleNavigateToLogin() {
    if (widget.onNavigateToLogin != null) {
      widget.onNavigateToLogin!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
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

                      // Top Centered Brand Logo
                      Center(
                        child: SizedBox(
                          width: 46.w,
                          child: Image.asset(
                            _logoImage,
                            fit: BoxFit.contain,
                            semanticLabel: 'Amarnath Enterprise Logo',
                          ),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // Create Account Heading
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'Create ',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Account',
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
                        'Sign up to book, manage and track\nyour rentals easily',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: AppColors.textSecondary,
                          height: 1.35,
                          fontWeight: FontWeight.normal,
                        ),
                      ),

                      SizedBox(height: 2.6.h),

                      // 3. Signup Form Container (White Rounded Card)
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
                          vertical: 20.dp,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Full Name
                            CustomAuthTextField(
                              label: 'Full Name',
                              hintText: 'Enter your full name',
                              leadingIcon: Icons.person_outline,
                              controller: _fullNameController,
                              errorText: _nameError,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (_nameError != null) {
                                  setState(() => _nameError = null);
                                }
                              },
                            ),

                            SizedBox(height: 1.6.h),

                            // 2. Shop Name
                            CustomAuthTextField(
                              label: 'Shop Name',
                              hintText: 'Enter your shop name',
                              leadingIcon: Icons.storefront_outlined,
                              controller: _shopNameController,
                              errorText: _shopError,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (_shopError != null) {
                                  setState(() => _shopError = null);
                                }
                              },
                            ),

                            SizedBox(height: 1.6.h),

                            // 3. Mobile Number
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

                            SizedBox(height: 1.6.h),

                            // 4. Address
                            CustomAuthTextField(
                              label: 'Address',
                              hintText: 'Enter your shop address',
                              leadingIcon: Icons.location_on_outlined,
                              controller: _addressController,
                              maxLines: 2,
                              errorText: _addressError,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (_addressError != null) {
                                  setState(() => _addressError = null);
                                }
                              },
                            ),

                            SizedBox(height: 1.6.h),

                            // 5. Password
                            CustomAuthTextField(
                              label: 'Password',
                              hintText: 'Create a password',
                              leadingIcon: Icons.lock_outline,
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              errorText: _passwordError,
                              textInputAction: TextInputAction.next,
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

                            SizedBox(height: 1.6.h),

                            // 6. Confirm Password
                            CustomAuthTextField(
                              label: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              leadingIcon: Icons.lock_outline,
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              errorText: _confirmPasswordError,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleSignUp(),
                              onChanged: (_) {
                                if (_confirmPasswordError != null) {
                                  setState(
                                    () => _confirmPasswordError = null,
                                  );
                                }
                              },
                              trailing: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: EdgeInsets.all(4.dp),
                                  child: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20.dp,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 2.2.h),

                            // Full-Width Gradient Sign Up Button
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
                                  onPressed: _isLoading ? null : _handleSignUp,
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
                                              'Sign Up',
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

                            SizedBox(height: 2.2.h),

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

                            SizedBox(height: 2.h),

                            // Existing Account Section
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _handleNavigateToLogin,
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
                                        'Already have an account?',
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
                                            'Login',
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
