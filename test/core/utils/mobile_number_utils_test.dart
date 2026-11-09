import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';

void main() {
  group('MobileNumberUtils Unit Tests', () {
    test('normalizes 10-digit mobile number to E.164 and 10-digit subscriber', () {
      expect(MobileNumberUtils.normalizeToE164('9876543210'), '+919876543210');
      expect(MobileNumberUtils.normalizeMobile('9876543210'), '9876543210');
      expect(MobileNumberUtils.normalizeMobileNumber('9876543210'), '9876543210');
    });

    test('normalizes numbers with spaces, hyphens, and +91 prefix', () {
      expect(MobileNumberUtils.normalizeToE164('+91 98765-43210'), '+919876543210');
      expect(MobileNumberUtils.normalizeMobile('+91 98765 43210'), '9876543210');
      expect(MobileNumberUtils.normalizeMobileNumber('+91 84698 00185'), '8469800185');
    });

    test('verifies Client authentication email format convention', () {
      expect(
        MobileNumberUtils.clientAuthEmailDomain,
        '@amarnath-enterprise-client.app',
      );
      expect(
        MobileNumberUtils.generateClientAuthEmail('8469800185'),
        '8469800185@amarnath-enterprise-client.app',
      );
      expect(
        MobileNumberUtils.generateClientAuthEmail('+91 84698 00185'),
        '8469800185@amarnath-enterprise-client.app',
      );
      expect(
        MobileNumberUtils.generateClientAuthEmail('9876543210'),
        '9876543210@amarnath-enterprise-client.app',
      );
    });

    test('verifies Owner authentication email convention remains distinct', () {
      expect(
        MobileNumberUtils.ownerAuthEmailDomain,
        '@amarnath-enterprise.app',
      );
      expect(
        MobileNumberUtils.generateOwnerAuthEmail('8469800185'),
        '8469800185@amarnath-enterprise.app',
      );
      expect(
        MobileNumberUtils.generateOwnerAuthEmail('+91 84698 00185'),
        '8469800185@amarnath-enterprise.app',
      );
    });

    test('verifies legacy Client authentication fallback email format', () {
      expect(
        MobileNumberUtils.legacyClientAuthEmailDomain,
        '@amarnath-enterprise.app',
      );
      expect(
        MobileNumberUtils.generateLegacyClientAuthEmail('8469800185'),
        '8469800185@amarnath-enterprise.app',
      );
    });

    test('backward-compatibility alias generateFirebaseEmail generates Client email', () {
      // ignore: deprecated_member_use_from_same_package
      expect(
        MobileNumberUtils.generateFirebaseEmail('8469800185'),
        '8469800185@amarnath-enterprise-client.app',
      );
    });

    test('validates valid and invalid mobile numbers', () {
      expect(MobileNumberUtils.isValidMobile('9876543210'), isTrue);
      expect(MobileNumberUtils.isValidMobile('8876543210'), isTrue);
      expect(MobileNumberUtils.isValidMobile('7876543210'), isTrue);
      expect(MobileNumberUtils.isValidMobile('6876543210'), isTrue);
      expect(MobileNumberUtils.isValidMobile('8469800185'), isTrue);

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
