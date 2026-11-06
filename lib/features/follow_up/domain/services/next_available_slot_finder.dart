import 'package:follow_up_planner/core/constants/app_constants.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

import '../../../../core/utils/ist_date_time.dart';
import '../../../../core/utils/phone_utils.dart';
import 'scheduling_slot_generator.dart';

class NextAvailableSlotFinder {
  NextAvailableSlotFinder._();

  // Maximum period to search for an available slot.
  static const int maxSearchDays = 365;

  static DateTime? findNextAvailableSlot({
    required DateTime requestedAt,
    required String phoneNumber,
    required List<FollowUpCall> existingCalls,
    Set<String> blockedDateKeys = const {},
    DateTime? now,
  }) {
    final currentTime = now ?? IstDateTime.nowIst();

    final searchStart = requestedAt.isAfter(currentTime)
        ? requestedAt
        : currentTime;

    var currentDate = DateTime.utc(
      searchStart.year,
      searchStart.month,
      searchStart.day,
    );

    // Normalize the new phone number once before searching.
    final normalizedPhone = PhoneUtils.normalize(phoneNumber);

    // Search only within the configured maximum period.
    final searchEndDate = currentDate.add(const Duration(days: maxSearchDays));

    while (!currentDate.isAfter(searchEndDate)) {
      final currentDateKey = IstDateTime.dateKey(currentDate);

      // Skip Sundays, non-working Saturdays, company holidays
      // and manually blocked dates.
      if (!IstDateTime.isWorkingDay(currentDate) ||
          blockedDateKeys.contains(currentDateKey)) {
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }

      // Get all calls scheduled for the current day.
      final dailyCalls = existingCalls.where((call) {
        return call.scheduledAt.year == currentDate.year &&
            call.scheduledAt.month == currentDate.month &&
            call.scheduledAt.day == currentDate.day;
      }).toList();

      // Check whether the same phone number already exists that day.
      final hasDuplicatePhone = dailyCalls.any(
        (call) => PhoneUtils.normalize(call.phoneNumber) == normalizedPhone,
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

      // Generate available 30-minute slots.
      final availableSlots = SchedulingSlotGenerator.generateSlotsForDay(
        currentDate,
      );

      for (final slot in availableSlots) {
        // Never schedule before the requested date and time.
        if (slot.isBefore(searchStart)) {
          continue;
        }

        // Check whether another call occupies this slot.
        final isOccupied = dailyCalls.any(
          (call) => call.scheduledAt.isAtSameMomentAs(slot),
        );

        if (!isOccupied) {
          return slot;
        }
      }

      // No available slot. Try the next working day.
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // No available slot found within 365 days.
    return null;
  }
}
