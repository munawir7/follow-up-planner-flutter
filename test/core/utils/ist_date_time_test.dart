import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/core/utils/ist_date_time.dart';

void main() {
  group('IST DateTime Tests', () {
    test('Should identify fifth Saturday as a working day', () {
  final date = DateTime.utc(2026, 10, 31);

  expect(date.weekday, DateTime.saturday);
  expect(IstDateTime.isSecondOrFourthSaturday(date), false);
  expect(IstDateTime.isWorkingDay(date), true);
});
    test('Should generate correct date key', () {
      final date = DateTime.utc(2026, 10, 30);

      expect(IstDateTime.dateKey(date), '2026-10-30');
    });

    test('Should identify Sunday', () {
      final date = DateTime.utc(2026, 11, 8);

      expect(IstDateTime.isSunday(date), true);
    });

    test('Should identify second Saturday', () {
      final date = DateTime.utc(2026, 11, 14);

      expect(IstDateTime.isSecondOrFourthSaturday(date), true);
    });

    test('Should identify fourth Saturday', () {
      final date = DateTime.utc(2026, 11, 28);

      expect(IstDateTime.isSecondOrFourthSaturday(date), true);
    });

    test('Should identify company holiday', () {
      final date = DateTime.utc(2026, 11, 9);

      expect(IstDateTime.isCompanyHoliday(date), true);
    });

    test('Should identify working day', () {
      final date = DateTime.utc(2026, 11, 10);

      expect(IstDateTime.isWorkingDay(date), true);
    });

    test('Should identify non-working day', () {
      final date = DateTime.utc(2026, 11, 8);

      expect(IstDateTime.isWorkingDay(date), false);
    });

    test('Should find next working day correctly', () {
      final date = DateTime.utc(2026, 11, 7);

      final result = IstDateTime.nextWorkingDay(date);

      expect(IstDateTime.dateKey(result), '2026-11-10');
    });
  });
}
