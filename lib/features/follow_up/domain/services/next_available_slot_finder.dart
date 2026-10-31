import 'package:follow_up_planner/core/constants/app_constance.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';

import '../../../../core/utils/ist_date_time.dart';
import 'scheduling_slot_generator.dart';

class NextAvailableSlotFinder {
  NextAvailableSlotFinder._();

  static DateTime? findNextAvailableSlot({
    required DateTime requestedAt,
    required String phoneNumber,
    required List<FollowUpCall> existingCalls,
    Set<String> blockedDateKeys = const {},
  }) {
    var currentDate = DateTime.utc(
      requestedAt.year,
      requestedAt.month,
      requestedAt.day,
    );

    while (true) {
      final currentDateKey = IstDateTime.dateKey(currentDate);

      // Skip weekends, company holidays and manually blocked dates.
      if (!IstDateTime.isWorkingDay(currentDate) ||
          blockedDateKeys.contains(currentDateKey)) {
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }

      final dailyCalls = existingCalls.where((call) {
        return call.scheduledAt.year == currentDate.year &&
            call.scheduledAt.month == currentDate.month &&
            call.scheduledAt.day == currentDate.day;
      }).toList();

      // Prevent duplicate phone numbers on the same day.
      final hasDuplicatePhone = dailyCalls.any(
        (call) => call.phoneNumber.trim() == phoneNumber.trim(),
      );

      if (hasDuplicatePhone) {
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }

      // Maximum six calls per day.
      if (dailyCalls.length >= AppConstants.maxCallsPerDay) {
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }

      final availableSlots = SchedulingSlotGenerator.generateSlotsForDay(
        currentDate,
      );

      for (final slot in availableSlots) {
        // Never schedule before the requested date and time.
        if (slot.isBefore(requestedAt)) {
          continue;
        }

        final isOccupied = dailyCalls.any(
          (call) => call.scheduledAt.isAtSameMomentAs(slot),
        );

        if (!isOccupied) {
          return slot;
        }
      }

      // Try the next day if no slot is available.
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }
}
