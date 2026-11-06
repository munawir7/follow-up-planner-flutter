import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/day_blocking_result.dart';
import 'package:follow_up_planner/features/follow_up/presentation/extensions/call_priority_extensions.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/ist_date_time.dart';
import 'next_available_slot_finder.dart';

class DayBlockingService {
  DayBlockingService._();

  static DayBlockingResult blockDay({
    required DateTime date,
    required List<FollowUpCall> existingCalls,
    Set<String> blockedDateKeys = const {},
    DateTime? now,
  }) {
    final blockedDate = DateTime.utc(date.year, date.month, date.day);

    // Get the current IST time.
    final currentTime = now ?? IstDateTime.nowIst();

    final today = DateTime.utc(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );

    final blockedDateKey = IstDateTime.dateKey(blockedDate);

    // Prevent blocking past dates.
    if (blockedDate.isBefore(today)) {
      throw const AppException(
        'Past dates cannot be blocked.',
        code: 'PAST_DATE_NOT_ALLOWED',
      );
    }

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
        .where((call) => IstDateTime.isSameDay(call.scheduledAt, blockedDate))
        .toList();

    // Sort calls by priority, then by their original scheduled time.
    callsToMove.sort((a, b) {
      final priorityComparison = a.priority.sortOrder.compareTo(
        b.priority.sortOrder,
      );

      if (priorityComparison != 0) {
        return priorityComparison;
      }

      return a.scheduledAt.compareTo(b.scheduledAt);
    });

    // Remove calls from the blocked day.
    final updatedCalls = existingCalls
        .where((call) => !IstDateTime.isSameDay(call.scheduledAt, blockedDate))
        .toList();

    final movedCalls = <FollowUpCall>[];

    // Add the newly blocked date.
    final updatedBlockedDateKeys = {...blockedDateKeys, blockedDateKey};

    // Reschedule calls in priority order.
    for (final call in callsToMove) {
      final nextSlot = NextAvailableSlotFinder.findNextAvailableSlot(
        requestedAt: IstDateTime.nextWorkingDay(blockedDate),
        phoneNumber: call.phoneNumber,
        existingCalls: updatedCalls,
        blockedDateKeys: updatedBlockedDateKeys,
        now: currentTime,
      );

      if (nextSlot == null) {
        throw const AppException(
          'Unable to reschedule all calls. No available future slot found.',
          code: 'DAY_BLOCK_RESCHEDULE_FAILED',
        );
      }

      final movedCall = call.copyWith(scheduledAt: nextSlot);

      updatedCalls.add(movedCall);
      movedCalls.add(movedCall);
    }

    return DayBlockingResult(
      blockedDate: blockedDate,
      updatedCalls: updatedCalls,
      movedCalls: movedCalls,
    );
  }
}
