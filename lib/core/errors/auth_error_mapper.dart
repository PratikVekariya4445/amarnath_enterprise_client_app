import 'package:firebase_auth/firebase_auth.dart';

/// Centralized mapper that transforms Firebase Authentication and authorization errors
/// into clear, user-friendly feedback for clients.
class AuthErrorMapper {
  AuthErrorMapper._();

  static String mapFirebaseAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'user-not-found':
        return 'No client account registered with this mobile number.';
      case 'wrong-password':
        return 'Incorrect password. Please verify and try again.';
      case 'invalid-credential':
        return 'Invalid mobile number or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact administrator.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few moments before trying again.';
      case 'network-request-failed':
        return 'Unable to connect. Please check your internet connection.';
      case 'email-already-in-use':
        return 'An account is already registered with this mobile number. Please log in.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid mobile format for authentication.';
      case 'invalid-phone-number':
        return 'Enter a valid 10-digit Indian mobile number.';
      case 'quota-exceeded':
        return 'SMS quota exceeded for today. Please try again later.';
      case 'session-expired':
        return 'The verification session has expired. Please request a new OTP.';
      case 'invalid-verification-code':
        return 'The entered OTP is incorrect. Please verify and try again.';
      default:
        if (exception.message != null && exception.message!.isNotEmpty) {
          return exception.message!;
        }
        return 'Authentication failed. Please try again.';
    }
  }

  static String mapCustomAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      return mapFirebaseAuthException(error);
    }
    if (error is AuthException) {
      return error.message;
    }
    final message = error.toString();
    if (message.contains('network') ||
        message.contains('SocketException') ||
        message.contains('timed out')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Domain authorization exceptions.
class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

class ClientAccessDeniedException extends AuthException {
  const ClientAccessDeniedException()
      : super(
          'Access denied. Owner accounts cannot log in to the Client app.',
          code: 'not-a-client',
        );
}

class ClientNotApprovedException extends AuthException {
  final String status;

  ClientNotApprovedException(this.status)
      : super(
          status.toLowerCase() == 'pending'
              ? 'Your registration is still awaiting Owner approval. You can log in once your account has been approved.'
              : status.toLowerCase() == 'rejected'
                  ? 'Your registration request has not been approved. Please contact Amarnath Enterprise for assistance.'
                  : 'Your account status is "$status". Approval is required to access your account.',
          code: status.toLowerCase() == 'pending'
              ? 'approval-pending'
              : status.toLowerCase() == 'rejected'
                  ? 'approval-rejected'
                  : 'not-approved',
        );
}

class MissingUserRecordException extends AuthException {
  const MissingUserRecordException()
      : super(
          'No client profile record found for this account. Please contact support.',
          code: 'missing-user-record',
        );
}

class ClientSessionRestorationException extends AuthException {
  const ClientSessionRestorationException([
    super.message =
        'Password was updated successfully, but session could not be restored automatically. Please log in with your new password.',
  ]) : super(code: 'session-restoration-failed');
}
