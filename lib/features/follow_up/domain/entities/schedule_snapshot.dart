import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

class ScheduleSnapshot {
  final List<FollowUpCall> calls;
  final Set<String> blockedDateKeys;

  ScheduleSnapshot({
    required List<FollowUpCall> calls,
    Set<String> blockedDateKeys = const {},
  }) : calls = List.unmodifiable(calls),
       blockedDateKeys = Set.unmodifiable(blockedDateKeys);
}
