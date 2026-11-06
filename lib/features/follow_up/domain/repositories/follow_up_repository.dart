import '../entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/schedule_diff.dart';

abstract class FollowUpRepository {
  Future<List<FollowUpCall>> getAllCalls();

  Future<void> applyScheduleDiff({
    required ScheduleDiff diff,
    required Set<String> blockedDateKeysToAdd,
    required Set<String> blockedDateKeysToRemove,
  });

  Future<Set<String>> getBlockedDates();

  Future<void> replaceSchedule({
    required List<FollowUpCall> calls,
    required Set<String> blockedDateKeys,
  });
}
