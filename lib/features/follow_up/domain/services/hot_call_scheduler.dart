import 'package:follow_up_planner/core/constants/app_constance.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/ist_date_time.dart';
import '../entities/scheduling_result.dart';
import 'next_available_slot_finder.dart';
import 'scheduling_slot_generator.dart';

class HotCallScheduler {
  HotCallScheduler._();

  static SchedulingResult scheduleHotCall({
    required FollowUpCall newCall,
    required List<FollowUpCall> existingCalls,
    Set<String> blockedDateKeys = const {},
  }) {
    if (newCall.priority != CallPriority.hot) {
      throw ArgumentError(
        'Only Hot calls can be scheduled using HotCallScheduler.',
      );
    }

    final requestedDay = DateTime.utc(
      newCall.requestedAt.year,
      newCall.requestedAt.month,
      newCall.requestedAt.day,
    );

    // Find the first two eligible working days.
    final firstWorkingDay = _findNextEligibleDay(requestedDay, blockedDateKeys);

    final secondWorkingDay = _findNextEligibleDay(
      firstWorkingDay.add(const Duration(days: 1)),
      blockedDateKeys,
    );

    final allowedDays = [firstWorkingDay, secondWorkingDay];

    // First, try to find a normal available slot.
    for (final day in allowedDays) {
      final dailyCalls = existingCalls.where((call) {
        return _isSameDay(call.scheduledAt, day);
      }).toList();

      final hasDuplicatePhone = dailyCalls.any(
        (call) => call.phoneNumber.trim() == newCall.phoneNumber.trim(),
      );

      if (hasDuplicatePhone ||
          dailyCalls.length >= AppConstants.maxCallsPerDay) {
        continue;
      }

      final slots = SchedulingSlotGenerator.generateSlotsForDay(day);

      for (final slot in slots) {
        if (slot.isBefore(newCall.requestedAt)) {
          continue;
        }

        final isOccupied = dailyCalls.any(
          (call) => call.scheduledAt.isAtSameMomentAs(slot),
        );

        if (!isOccupied) {
          final scheduledCall = newCall.copyWith(scheduledAt: slot);

          return SchedulingResult(
            scheduledCall: scheduledCall,
            updatedCalls: [...existingCalls, scheduledCall],
          );
        }
      }
    }

    // R12: Find Cold calls on the original requested day.
    final requestedDayCalls = existingCalls.where((call) {
      return _isSameDay(call.scheduledAt, requestedDay);
    }).toList();

    // Prevent duplicate phone numbers.
    final hasDuplicateHotPhone = requestedDayCalls.any(
      (call) => call.phoneNumber.trim() == newCall.phoneNumber.trim(),
    );

    if (hasDuplicateHotPhone) {
      throw const AppException(
        'This lead already has a call scheduled on the requested day.',
        code: 'DUPLICATE_PHONE',
      );
    }

    // Find Cold calls that can be displaced without moving
    // the Hot call backward from its requested time.
    final coldCalls =
        requestedDayCalls
            .where(
              (call) =>
                  call.priority == CallPriority.cold &&
                  !call.scheduledAt.isBefore(newCall.requestedAt),
            )
            .toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    if (coldCalls.isEmpty) {
      throw const AppException(
        'No available slot for this Hot call, and no Cold call can be moved.',
        code: 'HOT_CALL_NO_SLOT',
      );
    }

    // Select the latest Cold call.
    final coldCallToMove = coldCalls.first;

    // Temporarily remove the Cold call.
    final callsWithoutCold = existingCalls
        .where((call) => call.id != coldCallToMove.id)
        .toList();

    // Find a new slot for the displaced Cold call.
    final newColdSlot = NextAvailableSlotFinder.findNextAvailableSlot(
      requestedAt: coldCallToMove.scheduledAt.add(
        const Duration(minutes: AppConstants.callDurationMinutes),
      ),
      phoneNumber: coldCallToMove.phoneNumber,
      existingCalls: callsWithoutCold,
      blockedDateKeys: blockedDateKeys,
    );

    if (newColdSlot == null) {
      throw const AppException(
        'Unable to find another slot for the displaced Cold call.',
        code: 'COLD_CALL_MOVE_FAILED',
      );
    }

    final movedColdCall = coldCallToMove.copyWith(scheduledAt: newColdSlot);

    // The Hot call takes the Cold call's original slot.
    final scheduledHotCall = newCall.copyWith(
      scheduledAt: coldCallToMove.scheduledAt,
    );

    final updatedCalls = [...callsWithoutCold, movedColdCall, scheduledHotCall];

    return SchedulingResult(
      scheduledCall: scheduledHotCall,
      updatedCalls: updatedCalls,
      displacedCall: movedColdCall,
    );
  }

  static DateTime _findNextEligibleDay(
    DateTime startDate,
    Set<String> blockedDateKeys,
  ) {
    var date = DateTime.utc(startDate.year, startDate.month, startDate.day);

    while (!IstDateTime.isWorkingDay(date) ||
        blockedDateKeys.contains(IstDateTime.dateKey(date))) {
      date = date.add(const Duration(days: 1));
    }

    return date;
  }

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
