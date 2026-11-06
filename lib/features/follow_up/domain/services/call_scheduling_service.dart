import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

import '../entities/scheduling_result.dart';
import 'hot_call_scheduler.dart';
import 'normal_call_scheduler.dart';

class CallSchedulingService {
  CallSchedulingService._();

  static SchedulingResult scheduleCall({
    required FollowUpCall newCall,
    required List<FollowUpCall> existingCalls,
    Set<String> blockedDateKeys = const {},
    DateTime? now,
  }) {
    switch (newCall.priority) {
      case CallPriority.hot:
        return HotCallScheduler.scheduleHotCall(
          newCall: newCall,
          existingCalls: existingCalls,
          blockedDateKeys: blockedDateKeys,
          now: now,
        );

      case CallPriority.warm:
      case CallPriority.cold:
        return NormalCallScheduler.scheduleCall(
          newCall: newCall,
          existingCalls: existingCalls,
          blockedDateKeys: blockedDateKeys,
          now: now,
        );
    }
  }
}
