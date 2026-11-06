import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

import '../../../../core/errors/app_exception.dart';
import '../entities/scheduling_result.dart';
import 'next_available_slot_finder.dart';

class NormalCallScheduler {
  NormalCallScheduler._();

  static SchedulingResult scheduleCall({
    required FollowUpCall newCall,
    required List<FollowUpCall> existingCalls,
    Set<String> blockedDateKeys = const {},
    DateTime? now,
  }) {
    if (newCall.priority == CallPriority.hot) {
      throw ArgumentError(
        'Hot calls must be scheduled using HotCallScheduler.',
      );
    }

    final availableSlot = NextAvailableSlotFinder.findNextAvailableSlot(
      requestedAt: newCall.requestedAt,
      phoneNumber: newCall.phoneNumber,
      existingCalls: existingCalls,
      blockedDateKeys: blockedDateKeys,
      now: now,
    );

    if (availableSlot == null) {
      throw const AppException(
        'Unable to find an available slot for this call.',
        code: 'NO_AVAILABLE_SLOT',
      );
    }

    final scheduledCall = newCall.copyWith(scheduledAt: availableSlot);

    return SchedulingResult(
      scheduledCall: scheduledCall,
      updatedCalls: [...existingCalls, scheduledCall],
    );
  }
}
