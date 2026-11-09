import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('formats ISO 8601 string to dd MMM yyyy, hh:mm a', () {
      final formatted = DateFormatter.formatOrderDateTime('2026-11-08T14:15:00.000Z');
      expect(formatted.isNotEmpty, isTrue);
      expect(formatted, contains('2026'));
      expect(formatted, contains('Nov'));
    });

    test('handles empty and null inputs safely', () {
      expect(DateFormatter.formatOrderDateTime(null), '');
      expect(DateFormatter.formatOrderDateTime(''), '');
      expect(DateFormatter.formatOrderDateTime('   '), '');
    });

    test('returns original string if not valid date', () {
      expect(DateFormatter.formatOrderDateTime('invalid_date'), 'invalid_date');
    });
  });
}
