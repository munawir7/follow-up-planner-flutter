import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/core/utils/indian_currency_formatter.dart';

void main() {
  group('Indian Currency Formatter Tests', () {
    test('Should format three digit numbers', () {
      expect(IndianCurrencyFormatter.formatRupees(500), '₹500');
    });

    test('Should format four digit numbers', () {
      expect(IndianCurrencyFormatter.formatRupees(1000), '₹1,000');
    });

    test('Should format Indian number grouping', () {
      expect(IndianCurrencyFormatter.formatRupees(12345678), '₹1,23,45,678');
    });

    test('Should format amounts in lakhs', () {
      expect(IndianCurrencyFormatter.formatSummary(123456), '1.23 L');
    });

    test('Should format amounts in crores', () {
      expect(IndianCurrencyFormatter.formatSummary(12345678), '1.23 Cr');
    });

    test('Should truncate instead of rounding', () {
      expect(IndianCurrencyFormatter.formatSummary(12399999), '1.23 Cr');
    });

    test('Should display values below one lakh in full', () {
      expect(IndianCurrencyFormatter.formatSummary(50000), '₹50,000');
    });

    test('Should format exactly two decimal places', () {
      expect(IndianCurrencyFormatter.formatSummary(100000), '1.00 L');
    });
  });
}
