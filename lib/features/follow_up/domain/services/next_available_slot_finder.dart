
import 'package:follow_up_planner/core/constants/app_constance.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';

import '../../../../core/utils/ist_date_time.dart';
import 'scheduling_slot_generator.dart';

class NextAvailableSlotFinder {
  NextAvailableSlotFinder._();

  // Normalize phone numbers before comparison.
  static String _normalizePhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  }

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

    final normalizedPhone = _normalizePhoneNumber(phoneNumber);

    while (true) {
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

      // Same lead cannot have two calls on the same day.
      final hasDuplicatePhone = dailyCalls.any(
        (call) =>
            _normalizePhoneNumber(call.phoneNumber) == normalizedPhone,
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
        if (slot.isBefore(requestedAt)) {
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
  }
}
