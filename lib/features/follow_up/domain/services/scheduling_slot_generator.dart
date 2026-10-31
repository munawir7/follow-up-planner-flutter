import 'package:follow_up_planner/core/constants/app_constance.dart';

import '../../../../core/utils/ist_date_time.dart';

class SchedulingSlotGenerator {
  SchedulingSlotGenerator._();

  /// Generates all valid 30-minute call slots for a working day.
  static List<DateTime> generateSlotsForDay(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);

    // Check whether the selected date is a working day.
    if (!IstDateTime.isWorkingDay(day)) {
      return [];
    }

    final slots = <DateTime>[];

    // Working day starts at 09:30 AM.
    final startTime = DateTime.utc(
      day.year,
      day.month,
      day.day,
      AppConstants.workingStartHour,
      AppConstants.workingStartMinute,
    );

    // Working day ends at 06:30 PM.
    final endTime = DateTime.utc(
      day.year,
      day.month,
      day.day,
      AppConstants.workingEndHour,
      AppConstants.workingEndMinute,
    );

    var currentSlot = startTime;

    while (currentSlot.isBefore(endTime)) {
      // Exclude lunch break: 01:00 PM to 02:00 PM.
      final isLunchTime =
          currentSlot.hour >= AppConstants.lunchStartHour &&
          currentSlot.hour < AppConstants.lunchEndHour;

      if (!isLunchTime) {
        slots.add(currentSlot);
      }

      // Move to the next 30-minute slot.
      currentSlot = currentSlot.add(
        const Duration(minutes: AppConstants.callDurationMinutes),
      );
    }

    return slots;
  }
}
