
import 'package:follow_up_planner/core/constants/app_constance.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/day_blocking_result.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/ist_date_time.dart';
import 'scheduling_slot_generator.dart';

class DayBlockingService {
  DayBlockingService._();

  static DayBlockingResult blockDay({
    required DateTime date,
    required List<FollowUpCall> existingCalls,
    Set<String> blockedDateKeys = const {},
  }) {
    final blockedDate = DateTime.utc(
      date.year,
      date.month,
      date.day,
    );

    final blockedDateKey = IstDateTime.dateKey(blockedDate);

    // Validate whether the selected day is a working day.
    if (!IstDateTime.isWorkingDay(blockedDate)) {
      throw const AppException(
        'This day is already a non-working day.',
        code: 'DAY_NOT_WORKING',
      );
    }

    // Prevent blocking an already blocked day.
    if (blockedDateKeys.contains(blockedDateKey)) {
      throw const AppException(
        'This date has already been blocked.',
        code: 'DAY_ALREADY_BLOCKED',
      );
    }

    // Get all calls scheduled on the selected day.
    final callsToMove = existingCalls
        .where((call) => _isSameDay(call.scheduledAt, blockedDate))
        .toList();

    // R13: Sort by priority, then preserve original time order.
    callsToMove.sort((a, b) {
      final priorityComparison = _priorityRank(
        a.priority,
      ).compareTo(_priorityRank(b.priority));

      if (priorityComparison != 0) {
        return priorityComparison;
      }

      return a.scheduledAt.compareTo(b.scheduledAt);
    });

    // Remove calls from the blocked day.
    final updatedCalls = existingCalls
        .where((call) => !_isSameDay(call.scheduledAt, blockedDate))
        .toList();

    // Add the newly blocked date.
    final updatedBlockedDateKeys = {
      ...blockedDateKeys,
      blockedDateKey,
    };

    // R14: Reschedule calls in priority order.
    for (final call in callsToMove) {
      final nextSlot = _findNextSlot(
        requestedAt: IstDateTime.nextWorkingDay(blockedDate),
        phoneNumber: call.phoneNumber,
        existingCalls: updatedCalls,
        blockedDateKeys: updatedBlockedDateKeys,
      );

      if (nextSlot == null) {
        throw const AppException(
          'Unable to reschedule all calls. No available future slot found.',
          code: 'DAY_BLOCK_RESCHEDULE_FAILED',
        );
      }

      updatedCalls.add(
        call.copyWith(scheduledAt: nextSlot),
      );
    }

    return DayBlockingResult(
      blockedDate: blockedDate,
      updatedCalls: updatedCalls,
      movedCalls: callsToMove,
    );
  }

  // Find the next available slot.
  static DateTime? _findNextSlot({
    required DateTime requestedAt,
    required String phoneNumber,
    required List<FollowUpCall> existingCalls,
    required Set<String> blockedDateKeys,
  }) {
    var currentDate = DateTime.utc(
      requestedAt.year,
      requestedAt.month,
      requestedAt.day,
    );

    final normalizedPhone = _normalizePhoneNumber(phoneNumber);

    while (true) {
      final currentDateKey = IstDateTime.dateKey(currentDate);

      // Skip Sundays, non-working Saturdays,
      // company holidays and manually blocked dates.
      if (!IstDateTime.isWorkingDay(currentDate) ||
          blockedDateKeys.contains(currentDateKey)) {
        currentDate = currentDate.add(
          const Duration(days: 1),
        );
        continue;
      }

      // Get calls scheduled on the current day.
      final dailyCalls = existingCalls.where((call) {
        return _isSameDay(call.scheduledAt, currentDate);
      }).toList();

      // Maximum six calls per day.
      if (dailyCalls.length >= AppConstants.maxCallsPerDay) {
        currentDate = currentDate.add(
          const Duration(days: 1),
        );
        continue;
      }

      // Prevent duplicate calls for the same lead.
      final hasDuplicatePhone = dailyCalls.any(
        (call) =>
            _normalizePhoneNumber(call.phoneNumber) == normalizedPhone,
      );

      if (hasDuplicatePhone) {
        currentDate = currentDate.add(
          const Duration(days: 1),
        );
        continue;
      }

      // Generate available 30-minute slots.
      final slots = SchedulingSlotGenerator.generateSlotsForDay(
        currentDate,
      );

      for (final slot in slots) {
        // Do not schedule before the requested time.
        if (slot.isBefore(requestedAt)) {
          continue;
        }

        // Check whether the slot is occupied.
        final isOccupied = dailyCalls.any(
          (call) => call.scheduledAt.isAtSameMomentAs(slot),
        );

        if (!isOccupied) {
          return slot;
        }
      }

      // No available slot. Try the next day.
      currentDate = currentDate.add(
        const Duration(days: 1),
      );
    }
  }

  // Normalize phone numbers before comparison.
  static String _normalizePhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }

  // Hot first, Warm second, Cold last.
  static int _priorityRank(CallPriority priority) {
    switch (priority) {
      case CallPriority.hot:
        return 0;

      case CallPriority.warm:
        return 1;

      case CallPriority.cold:
        return 2;
    }
  }

  // Compare calendar dates.
  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
  
}
