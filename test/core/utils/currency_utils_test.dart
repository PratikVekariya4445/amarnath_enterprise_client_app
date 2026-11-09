import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils Tests', () {
    test('formats hundreds without comma', () {
      expect(CurrencyUtils.formatIndianCurrency(420), '420');
      expect(CurrencyUtils.formatIndianCurrency(0), '0');
    });

    test('formats thousands with comma', () {
      expect(CurrencyUtils.formatIndianCurrency(4200), '4,200');
      expect(CurrencyUtils.formatIndianCurrency(8300), '8,300');
      expect(CurrencyUtils.formatIndianCurrency(6450), '6,450');
      expect(CurrencyUtils.formatIndianCurrency(5400), '5,400');
    });

    test('formats lakhs and crores with Indian grouping', () {
      expect(CurrencyUtils.formatIndianCurrency(125000), '1,25,000');
      expect(CurrencyUtils.formatIndianCurrency(10000000), '1,00,00,000');
    });

    test('formatWithRupee adds ₹ symbol and space', () {
      expect(CurrencyUtils.formatWithRupee(4200), '₹ 4,200');
      expect(CurrencyUtils.formatWithRupee(8300), '₹ 8,300');
    });

    test('parseAmount parses strings safely', () {
      expect(CurrencyUtils.parseAmount('4200'), 4200.0);
      expect(CurrencyUtils.parseAmount('₹ 4,200'), 4200.0);
      expect(CurrencyUtils.parseAmount(null), 0.0);
      expect(CurrencyUtils.parseAmount('invalid'), 0.0);
    });
  });
}
