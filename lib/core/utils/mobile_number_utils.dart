/// Utilities for Indian mobile number normalization, validation, and pseudo-email generation.
class MobileNumberUtils {
  MobileNumberUtils._();

  /// Client Firebase Email/Password domain convention.
  static const String clientAuthEmailDomain = '@amarnath-enterprise-client.app';

  /// Owner Firebase Email/Password domain convention.
  /// Kept separate for the Owner app and verified in tests.
  static const String ownerAuthEmailDomain = '@amarnath-enterprise.app';

  /// Legacy Client Firebase Email/Password domain convention.
  /// Used for fallback authentication of existing accounts.
  static const String legacyClientAuthEmailDomain = '@amarnath-enterprise.app';

  /// Deprecated alias to [clientAuthEmailDomain].
  @Deprecated('Use clientAuthEmailDomain instead')
  static const String firebaseEmailDomain = clientAuthEmailDomain;

  static const String indianMobileValidationMessage =
      'Enter a valid 10-digit Indian mobile number.';

  /// Normalizes an input string to canonical E.164 format: `+91XXXXXXXXXX`.
  static String normalizeToE164(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Mobile number cannot be empty.');
    }

    if (!RegExp(r'^\+?[\d\s\-()]+$').hasMatch(trimmed)) {
      throw const FormatException(indianMobileValidationMessage);
    }

    final cleaned = trimmed.replaceAll(RegExp(r'[\s\-()]'), '');

    if (cleaned.lastIndexOf('+') > 0) {
      throw const FormatException(indianMobileValidationMessage);
    }

    String subscriber;

    if (cleaned.startsWith('+')) {
      if (!cleaned.startsWith('+91')) {
        throw const FormatException(indianMobileValidationMessage);
      }
      subscriber = cleaned.substring(3);
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      subscriber = cleaned.substring(2);
    } else if (cleaned.length == 11 && cleaned.startsWith('0')) {
      subscriber = cleaned.substring(1);
    } else if (cleaned.length == 10) {
      subscriber = cleaned;
    } else {
      throw const FormatException(indianMobileValidationMessage);
    }

    if (subscriber.startsWith('+') ||
        (subscriber.startsWith('91') && subscriber.length > 10)) {
      throw const FormatException(indianMobileValidationMessage);
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(subscriber)) {
      throw const FormatException(indianMobileValidationMessage);
    }

    return '+91$subscriber';
  }

  /// Normalizes an Indian mobile number into a consistent 10-digit subscriber string (e.g. `9876543210`).
  static String normalizeMobile(String input) {
    final e164 = normalizeToE164(input);
    return e164.substring(3);
  }

  /// Alias for [normalizeMobile] ensuring exact naming alignment with shared auth conventions.
  static String normalizeMobileNumber(String input) => normalizeMobile(input);

  /// Centralized validation method returning user-friendly error messages or null if valid.
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your mobile number';
    }

    try {
      normalizeToE164(value);
      return null;
    } on FormatException catch (e) {
      return e.message;
    } catch (_) {
      return indianMobileValidationMessage;
    }
  }

  /// Returns true if [value] is a valid Indian mobile number.
  static bool isValidMobile(String? value) {
    return validateMobile(value) == null;
  }

  /// Generates the Client Firebase Email/Password identifier using the normalized mobile number.
  /// Format: `${normalizedMobileDigits}@amarnath-enterprise-client.app`
  static String generateClientAuthEmail(String mobile) {
    final normalizedMobile = normalizeMobileNumber(mobile);
    return '$normalizedMobile$clientAuthEmailDomain';
  }

  /// Generates the Owner Firebase Email/Password identifier.
  /// Format: `${normalizedMobileDigits}@amarnath-enterprise.app`
  ///
  /// Kept separate for the Owner app.
  static String generateOwnerAuthEmail(String mobile) {
    final normalizedMobile = normalizeMobileNumber(mobile);
    return '$normalizedMobile$ownerAuthEmailDomain';
  }

  /// Generates the legacy Client Firebase Email/Password identifier.
  /// Format: `${normalizedMobileDigits}@amarnath-enterprise.app`
  ///
  /// Used solely for graceful fallback login for previously registered client accounts.
  static String generateLegacyClientAuthEmail(String mobile) {
    final normalizedMobile = normalizeMobileNumber(mobile);
    return '$normalizedMobile$legacyClientAuthEmailDomain';
  }

  /// Formats an Indian mobile number for clean display (e.g. `+91 98765 43210`).
  static String formatForDisplay(String input) {
    try {
      final e164 = normalizeToE164(input);
      final sub = e164.substring(3);
      return '+91 ${sub.substring(0, 5)} ${sub.substring(5)}';
    } catch (_) {
      return input;
    }
  }

  /// Backward-compatible alias for [generateClientAuthEmail].
  @Deprecated('Use generateClientAuthEmail instead')
  static String generateFirebaseEmail(String mobile) =>
      generateClientAuthEmail(mobile);
}
