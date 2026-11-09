/// Utility class for formatting Indian currency (INR).
class CurrencyUtils {
  CurrencyUtils._();

  /// Formats a numeric amount into standard Indian currency comma grouping.
  ///
  /// Examples:
  /// - `420` -> `"420"`
  /// - `4200` -> `"4,200"`
  /// - `8300` -> `"8,300"`
  /// - `125000` -> `"1,25,000"`
  /// - `10000000` -> `"1,00,00,000"`
  static String formatIndianCurrency(num amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    // Split integer and decimal parts
    final parts = absAmount.toStringAsFixed(2).split('.');
    String integerPart = parts[0];
    final decimalPart = parts[1];

    if (integerPart.length <= 3) {
      final formatted = integerPart;
      final result = decimalPart == '00' ? formatted : '$formatted.$decimalPart';
      return isNegative ? '-$result' : result;
    }

    // Last 3 digits
    final lastThree = integerPart.substring(integerPart.length - 3);
    final remaining = integerPart.substring(0, integerPart.length - 3);

    final buffer = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    buffer.write(',');
    buffer.write(lastThree);

    final result = decimalPart == '00' ? buffer.toString() : '${buffer.toString()}.$decimalPart';
    return isNegative ? '-$result' : result;
  }

  /// Formats an amount with the Indian Rupee symbol and a space: `₹ 4,200`.
  static String formatWithRupee(num amount) {
    return '₹ ${formatIndianCurrency(amount)}';
  }

  /// Parses a string representation of an amount safely to double.
  static double parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final clean = value.toString().replaceAll('₹', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }
}
