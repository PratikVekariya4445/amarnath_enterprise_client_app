import 'package:equatable/equatable.dart';

/// Base class for all Change Password events.
abstract class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the user submits the initial 3-field Change Password form.
class SubmitNormalChangePassword extends ChangePasswordEvent {
  const SubmitNormalChangePassword({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}

/// Dispatched when user dismisses the Incorrect Password alert dialog.
class DismissIncorrectPasswordDialog extends ChangePasswordEvent {
  const DismissIncorrectPasswordDialog();
}

/// Dispatched when user elects to reset password using OTP from the alert dialog.
class StartOtpResetFlow extends ChangePasswordEvent {
  const StartOtpResetFlow();
}

/// Dispatched when user taps "Send OTP" to the registered mobile number.
class SendOtpRequested extends ChangePasswordEvent {
  const SendOtpRequested({this.forceResendingToken});

  final int? forceResendingToken;

  @override
  List<Object?> get props => [forceResendingToken];
}

/// Internal callback event when Phone Auth dispatches SMS OTP code.
class OtpCodeSent extends ChangePasswordEvent {
  const OtpCodeSent({
    required this.verificationId,
    this.resendToken,
  });

  final String verificationId;
  final int? resendToken;

  @override
  List<Object?> get props => [verificationId, resendToken];
}

/// Internal callback event when Phone Auth fails.
class OtpVerificationFailedEvent extends ChangePasswordEvent {
  const OtpVerificationFailedEvent(this.errorMessage);

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}

/// Dispatched when user submits the 6-digit OTP code for verification.
class VerifyOtpRequested extends ChangePasswordEvent {
  const VerifyOtpRequested({
    required this.verificationId,
    required this.smsCode,
  });

  final String verificationId;
  final String smsCode;

  @override
  List<Object?> get props => [verificationId, smsCode];
}

/// Dispatched when user submits the new password following successful OTP verification.
class SubmitOtpNewPassword extends ChangePasswordEvent {
  const SubmitOtpNewPassword({
    required this.newPassword,
    required this.confirmPassword,
  });

  final String newPassword;
  final String confirmPassword;

  @override
  List<Object?> get props => [newPassword, confirmPassword];
}

/// Resets the BLoC back to initial change password state.
class ResetToInitialState extends ChangePasswordEvent {
  const ResetToInitialState();
}
