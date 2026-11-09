import 'package:equatable/equatable.dart';

/// Distinct UI steps in the Change Password and OTP Reset flow.
enum ChangePasswordStep {
  initial,
  confirmMobile,
  verifyOtp,
  createNewPassword,
}

/// Base class for all Change Password BLoC states.
abstract class ChangePasswordState extends Equatable {
  const ChangePasswordState();

  @override
  List<Object?> get props => [];
}

/// 1. Initial change password state displaying Current, New, and Confirm New fields.
class ChangePasswordInitial extends ChangePasswordState {
  const ChangePasswordInitial({this.registeredMobile});

  final String? registeredMobile;

  @override
  List<Object?> get props => [registeredMobile];
}

/// 2. Validating current password via Firebase reauthentication.
class ChangePasswordValidatingCurrent extends ChangePasswordState {
  const ChangePasswordValidatingCurrent();
}

/// 3. Emitted when current password reauthentication fails due to incorrect credentials.
class ChangePasswordIncorrectCurrent extends ChangePasswordState {
  const ChangePasswordIncorrectCurrent({
    required this.registeredMobile,
  });

  final String registeredMobile;

  @override
  List<Object?> get props => [registeredMobile];
}

/// 4. Emitted when user initiates OTP reset and confirms registered mobile.
class ChangePasswordMobileConfirmed extends ChangePasswordState {
  const ChangePasswordMobileConfirmed({
    required this.registeredMobile,
  });

  final String registeredMobile;

  @override
  List<Object?> get props => [registeredMobile];
}

/// 5. Emitted while Firebase Phone Auth is dispatching the SMS OTP.
class ChangePasswordSendingOtp extends ChangePasswordState {
  const ChangePasswordSendingOtp({
    required this.registeredMobile,
  });

  final String registeredMobile;

  @override
  List<Object?> get props => [registeredMobile];
}

/// 6. Emitted when SMS OTP is sent; prompts user to enter 6-digit OTP code.
class ChangePasswordOtpSent extends ChangePasswordState {
  const ChangePasswordOtpSent({
    required this.registeredMobile,
    required this.verificationId,
    this.resendToken,
    this.isResending = false,
  });

  final String registeredMobile;
  final String verificationId;
  final int? resendToken;
  final bool isResending;

  ChangePasswordOtpSent copyWith({
    String? registeredMobile,
    String? verificationId,
    int? resendToken,
    bool? isResending,
  }) {
    return ChangePasswordOtpSent(
      registeredMobile: registeredMobile ?? this.registeredMobile,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      isResending: isResending ?? this.isResending,
    );
  }

  @override
  List<Object?> get props =>
      [registeredMobile, verificationId, resendToken, isResending];
}

/// 7. Emitted while the entered OTP is being verified against Firebase Phone Auth.
class ChangePasswordVerifyingOtp extends ChangePasswordState {
  const ChangePasswordVerifyingOtp({
    required this.registeredMobile,
    required this.verificationId,
  });

  final String registeredMobile;
  final String verificationId;

  @override
  List<Object?> get props => [registeredMobile, verificationId];
}

/// 8. Emitted when OTP verification succeeded; user can now enter New Password & Confirm Password.
class ChangePasswordOtpVerified extends ChangePasswordState {
  const ChangePasswordOtpVerified({
    required this.registeredMobile,
    required this.verificationId,
  });

  final String registeredMobile;
  final String verificationId;

  @override
  List<Object?> get props => [registeredMobile, verificationId];
}

/// 9. Emitted while password is being updated via Cloud Function & session is being restored.
class ChangePasswordUpdatingPassword extends ChangePasswordState {
  const ChangePasswordUpdatingPassword({
    required this.registeredMobile,
  });

  final String registeredMobile;

  @override
  List<Object?> get props => [registeredMobile];
}

/// 10. Emitted on successful password update and session restoration.
class ChangePasswordSuccess extends ChangePasswordState {
  const ChangePasswordSuccess([
    this.message = 'Password updated successfully.',
  ]);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// 11. Emitted on operation errors.
class ChangePasswordFailure extends ChangePasswordState {
  const ChangePasswordFailure({
    required this.errorMessage,
    required this.step,
    this.registeredMobile,
    this.verificationId,
  });

  final String errorMessage;
  final ChangePasswordStep step;
  final String? registeredMobile;
  final String? verificationId;

  @override
  List<Object?> get props =>
      [errorMessage, step, registeredMobile, verificationId];
}

/// 12. Emitted if the Cloud Function succeeded but the Client session could not be restored automatically.
class ChangePasswordSessionRestorationFailure extends ChangePasswordState {
  const ChangePasswordSessionRestorationFailure([
    this.message =
        'Password was updated successfully, but session could not be restored automatically. Please log in with your new password.',
  ]);

  final String message;

  @override
  List<Object?> get props => [message];
}
