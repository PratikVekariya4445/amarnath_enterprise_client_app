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
      case 'invalid-email':
        return 'Invalid mobile format for authentication.';
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
  ClientNotApprovedException(String status)
      : super(
          status.toLowerCase() == 'pending'
              ? 'Your account approval is pending. Please wait for administrator verification.'
              : status.toLowerCase() == 'rejected'
                  ? 'Your account registration request has been rejected. Please contact support.'
                  : 'Your account status is "$status". Approval is required to access your account.',
          code: 'not-approved',
        );
}

class MissingUserRecordException extends AuthException {
  const MissingUserRecordException()
      : super(
          'No client profile record found for this account. Please contact support.',
          code: 'missing-user-record',
        );
}
