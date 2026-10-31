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
    final blockedDate = DateTime.utc(date.year, date.month, date.day);
    final blockedDateKey = IstDateTime.dateKey(blockedDate);

    if (!IstDateTime.isWorkingDay(blockedDate)) {
      throw const AppException(
        'This day is already a non-working day.',
        code: 'DAY_NOT_WORKING',
      );
    }

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

    // R13: Sort by priority, then original time.
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

    // Include the newly blocked date in the blocked-date set.
    final updatedBlockedDateKeys = {...blockedDateKeys, blockedDateKey};

    // R14: Move calls to the earliest available future slots.
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

      updatedCalls.add(call.copyWith(scheduledAt: nextSlot));
    }

    return DayBlockingResult(
      blockedDate: blockedDate,
      updatedCalls: updatedCalls,
      movedCalls: callsToMove,
    );
  }

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

    while (true) {
      final currentDateKey = IstDateTime.dateKey(currentDate);

      // Skip non-working and manually blocked dates.
      if (!IstDateTime.isWorkingDay(currentDate) ||
          blockedDateKeys.contains(currentDateKey)) {
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }

      final dailyCalls = existingCalls.where((call) {
        return _isSameDay(call.scheduledAt, currentDate);
      }).toList();

      if (dailyCalls.length < AppConstants.maxCallsPerDay) {
        final hasDuplicatePhone = dailyCalls.any(
          (call) => call.phoneNumber.trim() == phoneNumber.trim(),
        );

        if (!hasDuplicatePhone) {
          final slots = SchedulingSlotGenerator.generateSlotsForDay(
            currentDate,
          );

          for (final slot in slots) {
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
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

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

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
