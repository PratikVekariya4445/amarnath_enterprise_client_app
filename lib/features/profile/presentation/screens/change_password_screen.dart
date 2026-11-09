import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/bloc/change_password_bloc.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/bloc/change_password_event.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/bloc/change_password_state.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/change_password_bottom_waves.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/security_shield_illustration.dart';

/// Screen managing both normal password updates and OTP-verified password resets
/// matching the exact visual design from the reference screenshot.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    this.authRepository,
    this.changePasswordBloc,
  });

  final AuthRepository? authRepository;
  final ChangePasswordBloc? changePasswordBloc;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final ChangePasswordBloc _bloc;

  // Controllers for initial 3-field form
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controllers for OTP reset flow
  final _otpController = TextEditingController();
  final _otpNewPasswordController = TextEditingController();
  final _otpConfirmPasswordController = TextEditingController();

  // Visibility toggles
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _obscureOtpNew = true;
  bool _obscureOtpConfirm = true;

  // Resend OTP countdown
  Timer? _countdownTimer;
  int _resendCountdown = 60;
  bool _canResendOtp = false;

  @override
  void initState() {
    super.initState();
    _bloc = widget.changePasswordBloc ??
        ChangePasswordBloc(
          authRepository: widget.authRepository ?? AuthRepositoryImpl(),
        );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _otpNewPasswordController.dispose();
    _otpConfirmPasswordController.dispose();
    if (widget.changePasswordBloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
      _canResendOtp = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() {
          _resendCountdown = 0;
          _canResendOtp = true;
        });
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  void _showIncorrectPasswordDialog(String mobile) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.dp),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Incorrect Password',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111111),
            ),
          ),
          content: Text(
            'Your current password is incorrect. Would you like to reset your password using OTP verification?',
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          actionsPadding:
              EdgeInsets.only(left: 16.dp, right: 16.dp, bottom: 16.dp),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _bloc.add(const DismissIncorrectPasswordDialog());
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.dp),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.dp),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.dp),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _bloc.add(const StartOtpResetFlow());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00864D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.dp),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.dp),
                      elevation: 0,
                    ),
                    child: Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showSessionRestorationFailedDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.dp),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Password Updated',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111111),
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          actionsPadding:
              EdgeInsets.only(left: 16.dp, right: 16.dp, bottom: 16.dp),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 46.dp,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00864D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.dp),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Go to Login',
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
          style: TextStyle(fontSize: 13.sp, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.dp),
        ),
        margin: EdgeInsets.all(16.dp),
      ),
    );
  }

  void _handleBackTap(ChangePasswordState state) {
    if (state is ChangePasswordMobileConfirmed ||
        state is ChangePasswordOtpSent ||
        state is ChangePasswordOtpVerified) {
      _bloc.add(const ResetToInitialState());
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
        listener: (context, state) {
          if (state is ChangePasswordIncorrectCurrent) {
            _showIncorrectPasswordDialog(state.registeredMobile);
          } else if (state is ChangePasswordOtpSent) {
            _startResendCountdown();
          } else if (state is ChangePasswordSuccess) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF00864D),
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is ChangePasswordSessionRestorationFailure) {
            _showSessionRestorationFailedDialog(state.message);
          } else if (state is ChangePasswordFailure) {
            _showErrorSnackBar(state.errorMessage);
          }
        },
        builder: (context, state) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Color(0xFF00864D),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: Scaffold(
              backgroundColor: const Color(0xFFF8FBFA),
              appBar: AppBar(
                backgroundColor: const Color(0xFF00864D),
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => _handleBackTap(state),
                ),
                titleSpacing: 0,
                title: Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: false,
              ),
              body: Stack(
                children: [
                  // Decorative green waves at the bottom (behind content)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: ChangePasswordBottomWaves(),
                    ),
                  ),

                  // Scrollable form content
                  SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(bottom: 28.dp),
                      child: Column(
                        children: [
                          SizedBox(height: 14.dp),

                          // 2. Security shield and lock illustration
                          const SecurityShieldIllustration(),

                          SizedBox(height: 14.dp),

                          // 3. Main white rounded password form card
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 16.dp),
                            padding: EdgeInsets.all(20.dp),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.dp),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF000000)
                                      .withValues(alpha: 0.05),
                                  blurRadius: 18.dp,
                                  offset: Offset(0, 6.dp),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF00864D)
                                      .withValues(alpha: 0.03),
                                  blurRadius: 10.dp,
                                  offset: Offset(0, 2.dp),
                                ),
                              ],
                            ),
                            child: _buildCardContent(state),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds appropriate card content based on current BLoC state.
  Widget _buildCardContent(ChangePasswordState state) {
    if (state is ChangePasswordMobileConfirmed ||
        state is ChangePasswordSendingOtp ||
        (state is ChangePasswordFailure &&
            state.step == ChangePasswordStep.confirmMobile)) {
      return _buildConfirmMobileView(state);
    } else if (state is ChangePasswordOtpSent ||
        state is ChangePasswordVerifyingOtp ||
        (state is ChangePasswordFailure &&
            state.step == ChangePasswordStep.verifyOtp)) {
      return _buildVerifyOtpView(state);
    } else if (state is ChangePasswordOtpVerified ||
        state is ChangePasswordUpdatingPassword ||
        (state is ChangePasswordFailure &&
            state.step == ChangePasswordStep.createNewPassword)) {
      return _buildOtpNewPasswordView(state);
    }

    // Default: Initial 3-field normal Change Password view
    return _buildInitialFormView(state);
  }

  /// 1. Initial 3-field form (Current, New, Confirm New).
  Widget _buildInitialFormView(ChangePasswordState state) {
    final isValidating = state is ChangePasswordValidatingCurrent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Current Password Field
        _buildFieldLabel('Current Password'),
        TextFormField(
          controller: _currentPasswordController,
          obscureText: _obscureCurrent,
          style: TextStyle(
            fontSize: 13.5.sp,
            color: const Color(0xFF111111),
          ),
          decoration: _buildInputDecoration(
            hint: 'Enter current password',
            isObscured: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
        ),

        SizedBox(height: 16.dp),

        // New Password Field
        _buildFieldLabel('New Password'),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          style: TextStyle(
            fontSize: 13.5.sp,
            color: const Color(0xFF111111),
          ),
          decoration: _buildInputDecoration(
            hint: 'Enter new password',
            isObscured: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),

        SizedBox(height: 16.dp),

        // Confirm New Password Field
        _buildFieldLabel('Confirm New Password'),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          style: TextStyle(
            fontSize: 13.5.sp,
            color: const Color(0xFF111111),
          ),
          decoration: _buildInputDecoration(
            hint: 'Confirm new password',
            isObscured: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),

        SizedBox(height: 16.dp),

        // Information banner
        _buildInfoBanner('Password must be at least 6 characters long.'),

        SizedBox(height: 20.dp),

        // Update Password Button
        _buildPrimaryButton(
          text: 'Update Password',
          isLoading: isValidating,
          onPressed: () {
            FocusScope.of(context).unfocus();
            _bloc.add(SubmitNormalChangePassword(
              currentPassword: _currentPasswordController.text,
              newPassword: _newPasswordController.text,
              confirmPassword: _confirmPasswordController.text,
            ));
          },
        ),
      ],
    );
  }

  /// 2. OTP Reset: Registered Mobile Number view.
  Widget _buildConfirmMobileView(ChangePasswordState state) {
    final isSending = state is ChangePasswordSendingOtp;
    final mobile = state is ChangePasswordMobileConfirmed
        ? state.registeredMobile
        : state is ChangePasswordSendingOtp
            ? state.registeredMobile
            : state is ChangePasswordFailure
                ? (state.registeredMobile ?? '')
                : '';

    final formattedMobile = mobile.isNotEmpty
        ? MobileNumberUtils.formatForDisplay(mobile)
        : 'Loading registered number...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Reset Password via OTP',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111111),
          ),
        ),
        SizedBox(height: 6.dp),
        Text(
          'A 6-digit verification code will be sent to your registered mobile number.',
          style: TextStyle(
            fontSize: 12.5.sp,
            color: const Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
        SizedBox(height: 18.dp),

        _buildFieldLabel('Registered Mobile Number'),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.dp, vertical: 14.dp),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFA),
            borderRadius: BorderRadius.circular(14.dp),
            border: Border.all(color: const Color(0xFFCED3D8)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.phone_android_rounded,
                color: const Color(0xFF00864D),
                size: 21.dp,
              ),
              SizedBox(width: 12.dp),
              Text(
                formattedMobile,
                style: TextStyle(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111111),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.dp),
        _buildInfoBanner(
            'Ensure your device is ready to receive the SMS verification code.'),

        SizedBox(height: 20.dp),
        _buildPrimaryButton(
          text: 'Send OTP',
          isLoading: isSending,
          onPressed: () {
            FocusScope.of(context).unfocus();
            _bloc.add(const SendOtpRequested());
          },
        ),

        SizedBox(height: 12.dp),
        Center(
          child: TextButton(
            onPressed: () => _bloc.add(const ResetToInitialState()),
            child: Text(
              'Back to Current Password',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00864D),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 3. OTP Verification view.
  Widget _buildVerifyOtpView(ChangePasswordState state) {
    final isVerifying = state is ChangePasswordVerifyingOtp;
    String verificationId = '';
    String mobile = '';

    if (state is ChangePasswordOtpSent) {
      verificationId = state.verificationId;
      mobile = state.registeredMobile;
    } else if (state is ChangePasswordVerifyingOtp) {
      verificationId = state.verificationId;
      mobile = state.registeredMobile;
    } else if (state is ChangePasswordFailure) {
      verificationId = state.verificationId ?? '';
      mobile = state.registeredMobile ?? '';
    }

    final maskedMobile = mobile.length == 10
        ? '+91 ${mobile.substring(0, 2)}••••••${mobile.substring(8)}'
        : mobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111111),
          ),
        ),
        SizedBox(height: 6.dp),
        Text(
          'Please enter the 6-digit OTP code sent to $maskedMobile',
          style: TextStyle(
            fontSize: 12.5.sp,
            color: const Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
        SizedBox(height: 18.dp),

        _buildFieldLabel('6-Digit OTP'),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 6.dp,
            color: const Color(0xFF111111),
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 4.dp,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 14.dp, right: 10.dp),
              child: Icon(
                Icons.sms_outlined,
                color: const Color(0xFF555B60),
                size: 21.dp,
              ),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: 46.dp,
              minHeight: 46.dp,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.dp, vertical: 14.dp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.dp),
              borderSide:
                  const BorderSide(color: Color(0xFFCED3D8), width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.dp),
              borderSide:
                  const BorderSide(color: Color(0xFFCED3D8), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.dp),
              borderSide:
                  const BorderSide(color: Color(0xFF00864D), width: 1.4),
            ),
          ),
        ),

        SizedBox(height: 14.dp),

        // Resend OTP countdown row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _canResendOtp
                  ? "Didn't receive code?"
                  : 'Resend code in ${_resendCountdown}s',
              style: TextStyle(
                fontSize: 12.5.sp,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_canResendOtp)
              TextButton(
                onPressed: () {
                  _bloc.add(const SendOtpRequested());
                },
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00864D),
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: 16.dp),

        _buildPrimaryButton(
          text: 'Verify OTP',
          isLoading: isVerifying,
          onPressed: () {
            FocusScope.of(context).unfocus();
            _bloc.add(VerifyOtpRequested(
              verificationId: verificationId,
              smsCode: _otpController.text,
            ));
          },
        ),

        SizedBox(height: 10.dp),
        Center(
          child: TextButton(
            onPressed: () => _bloc.add(const ResetToInitialState()),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 4. New Password view after OTP verification (Current Password field is omitted).
  Widget _buildOtpNewPasswordView(ChangePasswordState state) {
    final isUpdating = state is ChangePasswordUpdatingPassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set New Password',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111111),
          ),
        ),
        SizedBox(height: 4.dp),
        Text(
          'Your mobile number has been verified. Enter your new password below.',
          style: TextStyle(
            fontSize: 12.5.sp,
            color: const Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
        SizedBox(height: 18.dp),

        // New Password Field
        _buildFieldLabel('New Password'),
        TextFormField(
          controller: _otpNewPasswordController,
          obscureText: _obscureOtpNew,
          style: TextStyle(
            fontSize: 13.5.sp,
            color: const Color(0xFF111111),
          ),
          decoration: _buildInputDecoration(
            hint: 'Enter new password',
            isObscured: _obscureOtpNew,
            onToggle: () => setState(() => _obscureOtpNew = !_obscureOtpNew),
          ),
        ),

        SizedBox(height: 16.dp),

        // Confirm New Password Field
        _buildFieldLabel('Confirm New Password'),
        TextFormField(
          controller: _otpConfirmPasswordController,
          obscureText: _obscureOtpConfirm,
          style: TextStyle(
            fontSize: 13.5.sp,
            color: const Color(0xFF111111),
          ),
          decoration: _buildInputDecoration(
            hint: 'Confirm new password',
            isObscured: _obscureOtpConfirm,
            onToggle: () =>
                setState(() => _obscureOtpConfirm = !_obscureOtpConfirm),
          ),
        ),

        SizedBox(height: 16.dp),

        // Requirement banner
        _buildInfoBanner('Password must be at least 6 characters long.'),

        SizedBox(height: 20.dp),

        // Update Password Button
        _buildPrimaryButton(
          text: 'Update Password',
          isLoading: isUpdating,
          onPressed: () {
            FocusScope.of(context).unfocus();
            _bloc.add(SubmitOtpNewPassword(
              newPassword: _otpNewPasswordController.text,
              confirmPassword: _otpConfirmPasswordController.text,
            ));
          },
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.dp),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.5.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF111111),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.dp, vertical: 12.dp),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F8EA),
        borderRadius: BorderRadius.circular(13.dp),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: const Color(0xFF087A42),
            size: 22.dp,
          ),
          SizedBox(width: 10.dp),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF075C29),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50.dp,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00864D), Color(0xFF007C46)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14.dp),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.dp),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20.dp,
                  height: 20.dp,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13.5.sp,
        color: const Color(0xFF62676C),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: 14.dp, right: 10.dp),
        child: Icon(
          Icons.lock_outline_rounded,
          color: const Color(0xFF555B60),
          size: 21.dp,
        ),
      ),
      prefixIconConstraints: BoxConstraints(
        minWidth: 46.dp,
        minHeight: 46.dp,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: const Color(0xFF555B60),
          size: 21.dp,
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 14.dp),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.dp),
        borderSide: const BorderSide(color: Color(0xFFCED3D8), width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.dp),
        borderSide: const BorderSide(color: Color(0xFFCED3D8), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.dp),
        borderSide: const BorderSide(color: Color(0xFF00864D), width: 1.4),
      ),
    );
  }
}
