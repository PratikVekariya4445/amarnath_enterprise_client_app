import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/errors/auth_error_mapper.dart';

void main() {
  group('AuthErrorMapper & Exceptions Unit Tests', () {
    test('ClientAccessDeniedException message', () {
      const ex = ClientAccessDeniedException();
      expect(ex.code, 'not-a-client');
      expect(
        ex.message,
        'Access denied. Owner accounts cannot log in to the Client app.',
      );
    });

    test('ClientNotApprovedException messages for pending and rejected', () {
      final pendingEx = ClientNotApprovedException('pending');
      expect(
        pendingEx.message,
        'Your account approval is pending. Please wait for administrator verification.',
      );

      final rejectedEx = ClientNotApprovedException('rejected');
      expect(
        rejectedEx.message,
        'Your account registration request has been rejected. Please contact support.',
      );

      final otherEx = ClientNotApprovedException('suspended');
      expect(
        otherEx.message,
        'Your account status is "suspended". Approval is required to access your account.',
      );
    });

    test('mapCustomAuthError maps strings and custom exceptions correctly', () {
      expect(
        AuthErrorMapper.mapCustomAuthError(const ClientAccessDeniedException()),
        'Access denied. Owner accounts cannot log in to the Client app.',
      );
      expect(
        AuthErrorMapper.mapCustomAuthError(Exception('network error occurred')),
        'Unable to connect to server. Please check your internet connection.',
      );
    });
  });
}
