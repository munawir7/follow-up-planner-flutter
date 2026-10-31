class IndianCurrencyFormatter {
  IndianCurrencyFormatter._();

  // Format complete Indian currency.
  static String formatRupees(num amount) {
    final rupees = amount.toInt();

    final isNegative = rupees < 0;
    final digits = rupees.abs().toString();

    if (digits.length <= 3) {
      return '${isNegative ? '-' : ''}₹$digits';
    }

    final lastThree = digits.substring(digits.length - 3);
    final remaining = digits.substring(0, digits.length - 3);

    final formattedRemaining = StringBuffer();

    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        formattedRemaining.write(',');
      }

      formattedRemaining.write(remaining[i]);
    }

    return '${isNegative ? '-' : ''}₹$formattedRemaining,$lastThree';
  }

  // Format summary values using Lakh and Crore.
  static String formatSummary(num amount) {
    final absoluteAmount = amount.abs();

    if (absoluteAmount < 100000) {
      return formatRupees(amount);
    }

    final isNegative = amount < 0;
    final prefix = isNegative ? '-' : '';

    if (absoluteAmount >= 10000000) {
      final value = _truncateTwoDecimals(absoluteAmount / 10000000);

      return '$prefix${value.toStringAsFixed(2)} Cr';
    }

    final value = _truncateTwoDecimals(absoluteAmount / 100000);

    return '$prefix${value.toStringAsFixed(2)} L';
  }

  // Truncate to exactly two decimal places.
  static double _truncateTwoDecimals(num value) {
    return (value * 100).floorToDouble() / 100;
  }
}
