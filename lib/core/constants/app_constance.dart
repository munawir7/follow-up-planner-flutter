class AppConstants {
  AppConstants._();

  // Application
  static const String appName = 'Follow-Up Planner';

  // Scheduling
  static const int callDurationMinutes = 30;
  static const int maxCallsPerDay = 6;
  static const int maxUndoSteps = 20;

  // Working hours
  static const int workingStartHour = 9;
  static const int workingStartMinute = 30;

  static const int workingEndHour = 18;
  static const int workingEndMinute = 30;

  // Lunch break: 1 PM to 2 PM
  static const int lunchStartHour = 13;
  static const int lunchEndHour = 14;

  // Priorities
  static const String priorityHot = 'Hot';
  static const String priorityWarm = 'Warm';
  static const String priorityCold = 'Cold';

  // Company holidays (YYYY-MM-DD)
  static const List<String> companyHolidays = [
    '2026-11-01',
    '2026-11-09',
    '2026-12-25',
    '2027-01-26',
  ];

  // Phone validation
  static const int phoneNumberLength = 10;
  static const String phoneNumberPattern = r'^[6-9]\d{9}$';

  // Indian currency
  static const String currencySymbol = '₹';
}
