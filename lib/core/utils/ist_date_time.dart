import '../constants/app_constants.dart';

class IstDateTime {
  IstDateTime._();

  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  // Get current IST time.
  static DateTime nowIst() {
    return DateTime.now().toUtc().add(_istOffset);
  }

  // Convert an actual timestamp into IST.
  static DateTime toIst(DateTime dateTime) {
    return dateTime.toUtc().add(_istOffset);
  }

  // Generate date key: yyyy-MM-dd.
  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // Check Sunday.
  static bool isSunday(DateTime date) {
    return date.weekday == DateTime.sunday;
  }

  // Check second and fourth Saturday.
  static bool isSecondOrFourthSaturday(DateTime date) {
    if (date.weekday != DateTime.saturday) {
      return false;
    }

    final weekOfMonth = ((date.day - 1) ~/ 7) + 1;

    return weekOfMonth == 2 || weekOfMonth == 4;
  }

  // Check company holidays using AppConstants as the single source.
  static bool isCompanyHoliday(DateTime date) {
    return AppConstants.companyHolidays.contains(dateKey(date));
  }

  // Check whether the date is a working day.
  static bool isWorkingDay(DateTime date) {
    return !isSunday(date) &&
        !isSecondOrFourthSaturday(date) &&
        !isCompanyHoliday(date);
  }

  // Find the next working day.
  static DateTime nextWorkingDay(DateTime date) {
    var nextDate = DateTime.utc(date.year, date.month, date.day);

    do {
      nextDate = nextDate.add(const Duration(days: 1));
    } while (!isWorkingDay(nextDate));

    return nextDate;
  }
}
