import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:amarnath_enterprise_client_app/core/errors/auth_error_mapper.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';

/// Contract for the trusted backend service that calls the deployed Firebase Cloud Function
/// `reset_password_client_app` to securely reset an approved Client's password after SMS OTP verification.
abstract class ClientPasswordResetBackendService {
  Future<void> resetClientPassword({
    required String mobile,
    required String newPassword,
    required String idToken,
  });
}

/// Production implementation of [ClientPasswordResetBackendService].
///
/// Communicates over HTTPS POST with:
/// `https://us-central1-whats-deleted-8ca7b.cloudfunctions.net/reset_password_client_app`
/// passing `Authorization: Bearer <verified Phone Auth ID token>`
/// and `{ "mobile": normalizedMobile, "newPassword": newPassword }`.
class DefaultClientPasswordResetBackendService
    implements ClientPasswordResetBackendService {
  DefaultClientPasswordResetBackendService({
    String? customEndpointUrl,
    HttpClient Function()? clientFactory,
  })  : endpointUrl = (customEndpointUrl != null && customEndpointUrl.isNotEmpty)
            ? customEndpointUrl
            : defaultEndpointUrl,
        _clientFactory = clientFactory ?? HttpClient.new;

  /// Deployed Firebase Cloud Function URL for client password reset.
  static const String defaultEndpointUrl =
      'https://us-central1-whats-deleted-8ca7b.cloudfunctions.net/reset_password_client_app';

  final String endpointUrl;
  final HttpClient Function() _clientFactory;

  @override
  Future<void> resetClientPassword({
    required String mobile,
    required String newPassword,
    required String idToken,
  }) async {
    final normalized = MobileNumberUtils.normalizeMobileNumber(mobile);

    if (idToken.trim().isEmpty) {
      throw const AuthException(
        'Phone verification session has expired. Please verify your OTP again.',
        code: 'session-expired',
      );
    }

    if (newPassword.length < 6) {
      throw const AuthException(
        'Password must be at least 6 characters long.',
        code: 'weak-password',
      );
    }

    HttpClient? client;
    try {
      final uri = Uri.parse(endpointUrl);
      client = _clientFactory()..connectionTimeout = const Duration(seconds: 12);
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');

      final payload = jsonEncode({
        'mobile': normalized,
        'newPassword': newPassword,
      });

      request.write(payload);
      final response =
          await request.close().timeout(const Duration(seconds: 12));

      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Client password reset successfully via Cloud Function.');
        return;
      }

      // Handle specific HTTP error status codes with helpful actionable messages:
      if (response.statusCode == 404) {
        throw const AuthException(
          'Password reset service is currently unavailable. Please contact administrator.',
          code: 'backend-unavailable',
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        try {
          final json = jsonDecode(responseBody);
          final msg = json['error'] ?? json['message'];
          if (msg != null && msg.toString().isNotEmpty) {
            throw AuthException(msg.toString(), code: 'auth-forbidden');
          }
        } catch (e) {
          if (e is AuthException) rethrow;
        }
        throw const AuthException(
          'Phone verification identity is invalid or expired. Please verify OTP again.',
          code: 'unauthorized',
        );
      } else {
        try {
          final json = jsonDecode(responseBody);
          final msg = json['error'] ?? json['message'];
          if (msg != null && msg.toString().isNotEmpty) {
            throw AuthException(msg.toString(),
                code: 'backend-error-${response.statusCode}');
          }
        } catch (e) {
          if (e is AuthException) rethrow;
        }
        throw AuthException(
          'Password reset failed (Error ${response.statusCode}). Please try again later.',
          code: 'backend-error-${response.statusCode}',
        );
      }
    } on SocketException catch (_) {
      throw const AuthException(
        'Unable to connect to the password reset service. Please check your internet connection.',
        code: 'network-error',
      );
    } on TimeoutException catch (_) {
      throw const AuthException(
        'Password reset request timed out. Please try again.',
        code: 'timeout',
      );
    } finally {
      client?.close();
    }
  }
}
