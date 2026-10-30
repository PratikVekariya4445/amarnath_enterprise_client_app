import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';

void main() {
  group('MobileNumberUtils Unit Tests', () {
    test('normalizes 10-digit mobile number to E.164 and 10-digit subscriber', () {
      expect(MobileNumberUtils.normalizeToE164('9876543210'), '+919876543210');
      expect(MobileNumberUtils.normalizeMobile('9876543210'), '9876543210');
    });

    test('normalizes numbers with spaces, hyphens, and +91 prefix', () {
      expect(MobileNumberUtils.normalizeToE164('+91 98765-43210'), '+919876543210');
      expect(MobileNumberUtils.normalizeMobile('+91 98765 43210'), '9876543210');
    });

    test('generates Firebase pseudo-email identity', () {
      expect(
        MobileNumberUtils.generateFirebaseEmail('9876543210'),
        '9876543210@amarnath-enterprise.app',
      );
      expect(
        MobileNumberUtils.generateFirebaseEmail('+91 9123456789'),
        '9123456789@amarnath-enterprise.app',
      );
    });

    test('validates valid and invalid mobile numbers', () {
      expect(MobileNumberUtils.isValidMobile('9876543210'), isTrue);
      expect(MobileNumberUtils.isValidMobile('8876543210'), isTrue);
      expect(MobileNumberUtils.isValidMobile('7876543210'), isTrue);
      expect(MobileNumberUtils.isValidMobile('6876543210'), isTrue);

      // Invalid starts (1-5)
      expect(MobileNumberUtils.isValidMobile('5876543210'), isFalse);
      expect(MobileNumberUtils.isValidMobile('1234567890'), isFalse);

      // Invalid lengths
      expect(MobileNumberUtils.isValidMobile('98765'), isFalse);
      expect(MobileNumberUtils.isValidMobile('987654321000'), isFalse);

      // Empty or letters
      expect(MobileNumberUtils.isValidMobile(''), isFalse);
      expect(MobileNumberUtils.isValidMobile('abcdefghij'), isFalse);
    });
  });
}
