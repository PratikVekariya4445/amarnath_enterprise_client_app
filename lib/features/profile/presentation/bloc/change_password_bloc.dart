import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amarnath_enterprise_client_app/core/errors/auth_error_mapper.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/bloc/change_password_event.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/bloc/change_password_state.dart';

/// Business Logic Component managing both the normal password update flow
/// and the OTP-verified password reset flow for authenticated clients.
class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc({
    required this.authRepository,
    String? initialMobile,
  })  : _registeredMobile = initialMobile ?? '',
        super(ChangePasswordInitial(registeredMobile: initialMobile)) {
    on<SubmitNormalChangePassword>(_onSubmitNormalChangePassword);
    on<DismissIncorrectPasswordDialog>(_onDismissIncorrectPasswordDialog);
    on<StartOtpResetFlow>(_onStartOtpResetFlow);
    on<SendOtpRequested>(_onSendOtpRequested);
    on<OtpCodeSent>(_onOtpCodeSent);
    on<OtpVerificationFailedEvent>(_onOtpVerificationFailedEvent);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<SubmitOtpNewPassword>(_onSubmitOtpNewPassword);
    on<ResetToInitialState>(_onResetToInitialState);

    if (_registeredMobile.isEmpty) {
      _loadRegisteredMobile();
    }
  }

  final AuthRepository authRepository;
  String _registeredMobile;
  String _currentVerificationId = '';
  int? _currentResendToken;

  Future<void> _loadRegisteredMobile() async {
    try {
      final profile = await authRepository.getCurrentClientProfile();
      if (profile != null && profile.mobile.isNotEmpty) {
        _registeredMobile = profile.mobile;
      }
    } catch (_) {}
  }

  Future<void> _onSubmitNormalChangePassword(
    SubmitNormalChangePassword event,
    Emitter<ChangePasswordState> emit,
  ) async {
    if (state is ChangePasswordValidatingCurrent ||
        state is ChangePasswordUpdatingPassword) {
      return;
    }

    final currentPass = event.currentPassword.trim();
    final newPass = event.newPassword.trim();
    final confirmPass = event.confirmPassword.trim();

    if (currentPass.isEmpty) {
      emit(const ChangePasswordFailure(
        errorMessage: 'Please enter current password',
        step: ChangePasswordStep.initial,
      ));
      return;
    }
    if (newPass.isEmpty) {
      emit(const ChangePasswordFailure(
        errorMessage: 'Please enter new password',
        step: ChangePasswordStep.initial,
      ));
      return;
    }
    if (newPass.length < 6) {
      emit(const ChangePasswordFailure(
        errorMessage: 'Password must be at least 6 characters long.',
        step: ChangePasswordStep.initial,
      ));
      return;
    }
    if (confirmPass.isEmpty) {
      emit(const ChangePasswordFailure(
        errorMessage: 'Please confirm new password',
        step: ChangePasswordStep.initial,
      ));
      return;
    }
    if (newPass != confirmPass) {
      emit(const ChangePasswordFailure(
        errorMessage: 'Passwords do not match',
        step: ChangePasswordStep.initial,
      ));
      return;
    }

    emit(const ChangePasswordValidatingCurrent());

    try {
      await authRepository.updatePassword(
        currentPassword: currentPass,
        newPassword: newPass,
      );
      emit(const ChangePasswordSuccess('Password updated successfully.'));
    } on AuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.message.toLowerCase().contains('incorrect password')) {
        if (_registeredMobile.isEmpty) {
          await _loadRegisteredMobile();
        }
        emit(ChangePasswordIncorrectCurrent(
          registeredMobile: _registeredMobile,
        ));
      } else {
        emit(ChangePasswordFailure(
          errorMessage: e.message,
          step: ChangePasswordStep.initial,
          registeredMobile: _registeredMobile,
        ));
      }
    } catch (e) {
      emit(ChangePasswordFailure(
        errorMessage: AuthErrorMapper.mapCustomAuthError(e),
        step: ChangePasswordStep.initial,
        registeredMobile: _registeredMobile,
      ));
    }
  }

  void _onDismissIncorrectPasswordDialog(
    DismissIncorrectPasswordDialog event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(ChangePasswordInitial(registeredMobile: _registeredMobile));
  }

  Future<void> _onStartOtpResetFlow(
    StartOtpResetFlow event,
    Emitter<ChangePasswordState> emit,
  ) async {
    if (_registeredMobile.isEmpty) {
      await _loadRegisteredMobile();
    }
    emit(ChangePasswordMobileConfirmed(registeredMobile: _registeredMobile));
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<ChangePasswordState> emit,
  ) async {
    if (state is ChangePasswordSendingOtp) return;

    if (_registeredMobile.isEmpty) {
      await _loadRegisteredMobile();
    }

    if (_registeredMobile.isEmpty) {
      emit(const ChangePasswordFailure(
        errorMessage:
            'Registered mobile number could not be resolved from your profile.',
        step: ChangePasswordStep.confirmMobile,
      ));
      return;
    }

    emit(ChangePasswordSendingOtp(registeredMobile: _registeredMobile));

    try {
      final normalized =
          MobileNumberUtils.normalizeMobileNumber(_registeredMobile);

      await authRepository.sendPasswordResetOtp(
        mobile: normalized,
        forceResendingToken: event.forceResendingToken ?? _currentResendToken,
        onCodeSent: (verificationId, resendToken) {
          add(OtpCodeSent(
            verificationId: verificationId,
            resendToken: resendToken,
          ));
        },
        onVerificationFailed: (errorMessage) {
          add(OtpVerificationFailedEvent(errorMessage));
        },
        onVerificationCompleted: (_) {},
      );
    } catch (e) {
      emit(ChangePasswordFailure(
        errorMessage: e is AuthException
            ? e.message
            : AuthErrorMapper.mapCustomAuthError(e),
        step: ChangePasswordStep.confirmMobile,
        registeredMobile: _registeredMobile,
      ));
    }
  }

  void _onOtpCodeSent(
    OtpCodeSent event,
    Emitter<ChangePasswordState> emit,
  ) {
    _currentVerificationId = event.verificationId;
    _currentResendToken = event.resendToken;

    emit(ChangePasswordOtpSent(
      registeredMobile: _registeredMobile,
      verificationId: event.verificationId,
      resendToken: event.resendToken,
    ));
  }

  void _onOtpVerificationFailedEvent(
    OtpVerificationFailedEvent event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(ChangePasswordFailure(
      errorMessage: event.errorMessage,
      step: ChangePasswordStep.confirmMobile,
      registeredMobile: _registeredMobile,
    ));
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<ChangePasswordState> emit,
  ) async {
    if (state is ChangePasswordVerifyingOtp) return;

    final trimmedCode = event.smsCode.trim();
    if (trimmedCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      emit(ChangePasswordFailure(
        errorMessage: 'Please enter a valid 6-digit OTP code.',
        step: ChangePasswordStep.verifyOtp,
        registeredMobile: _registeredMobile,
        verificationId: event.verificationId,
      ));
      return;
    }

    emit(ChangePasswordVerifyingOtp(
      registeredMobile: _registeredMobile,
      verificationId: event.verificationId,
    ));

    try {
      await authRepository.verifyPasswordResetOtp(
        verificationId: event.verificationId,
        smsCode: trimmedCode,
      );

      _currentVerificationId = event.verificationId;

      emit(ChangePasswordOtpVerified(
        registeredMobile: _registeredMobile,
        verificationId: event.verificationId,
      ));
    } on AuthException catch (e) {
      emit(ChangePasswordFailure(
        errorMessage: e.message,
        step: ChangePasswordStep.verifyOtp,
        registeredMobile: _registeredMobile,
        verificationId: event.verificationId,
      ));
    } catch (e) {
      emit(ChangePasswordFailure(
        errorMessage: AuthErrorMapper.mapCustomAuthError(e),
        step: ChangePasswordStep.verifyOtp,
        registeredMobile: _registeredMobile,
        verificationId: event.verificationId,
      ));
    }
  }

  Future<void> _onSubmitOtpNewPassword(
    SubmitOtpNewPassword event,
    Emitter<ChangePasswordState> emit,
  ) async {
    if (state is ChangePasswordUpdatingPassword) return;

    final newPass = event.newPassword.trim();
    final confirmPass = event.confirmPassword.trim();

    if (newPass.isEmpty) {
      emit(ChangePasswordFailure(
        errorMessage: 'Please enter new password',
        step: ChangePasswordStep.createNewPassword,
        registeredMobile: _registeredMobile,
        verificationId: _currentVerificationId,
      ));
      return;
    }
    if (newPass.length < 6) {
      emit(ChangePasswordFailure(
        errorMessage: 'Password must be at least 6 characters long.',
        step: ChangePasswordStep.createNewPassword,
        registeredMobile: _registeredMobile,
        verificationId: _currentVerificationId,
      ));
      return;
    }
    if (confirmPass.isEmpty) {
      emit(ChangePasswordFailure(
        errorMessage: 'Please confirm new password',
        step: ChangePasswordStep.createNewPassword,
        registeredMobile: _registeredMobile,
        verificationId: _currentVerificationId,
      ));
      return;
    }
    if (newPass != confirmPass) {
      emit(ChangePasswordFailure(
        errorMessage: 'Passwords do not match',
        step: ChangePasswordStep.createNewPassword,
        registeredMobile: _registeredMobile,
        verificationId: _currentVerificationId,
      ));
      return;
    }

    emit(ChangePasswordUpdatingPassword(
      registeredMobile: _registeredMobile,
    ));

    try {
      await authRepository.resetClientPasswordWithVerifiedPhone(
        mobile: _registeredMobile,
        newPassword: newPass,
      );

      emit(const ChangePasswordSuccess('Password updated successfully.'));
    } on ClientSessionRestorationException catch (e) {
      emit(ChangePasswordSessionRestorationFailure(e.message));
    } on AuthException catch (e) {
      emit(ChangePasswordFailure(
        errorMessage: e.message,
        step: ChangePasswordStep.createNewPassword,
        registeredMobile: _registeredMobile,
        verificationId: _currentVerificationId,
      ));
    } catch (e) {
      emit(ChangePasswordFailure(
        errorMessage: AuthErrorMapper.mapCustomAuthError(e),
        step: ChangePasswordStep.createNewPassword,
        registeredMobile: _registeredMobile,
        verificationId: _currentVerificationId,
      ));
    }
  }

  void _onResetToInitialState(
    ResetToInitialState event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(ChangePasswordInitial(registeredMobile: _registeredMobile));
  }
}
