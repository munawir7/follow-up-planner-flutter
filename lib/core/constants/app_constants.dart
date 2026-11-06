class AppConstants {
  AppConstants._();

  static const String appName = 'Follow-Up Planner';

  static const int callDurationMinutes = 30;
  static const int maxCallsPerDay = 6;
  static const int maxUndoSteps = 20;

  static const int workingStartHour = 9;
  static const int workingStartMinute = 30;

  static const int workingEndHour = 18;
  static const int workingEndMinute = 30;

  static const int lunchStartHour = 13;
  static const int lunchEndHour = 14;

  static const List<String> companyHolidays = [
    '2026-11-01',
    '2026-11-09',
    '2026-12-25',
    '2027-01-26',
  ];

  static const int phoneNumberLength = 10;
  static const String phoneNumberPattern = r'^[6-9]\d{9}$';

  static const String currencySymbol = '₹';

  static const int maxDealValuePaise = 1000000000;
}
