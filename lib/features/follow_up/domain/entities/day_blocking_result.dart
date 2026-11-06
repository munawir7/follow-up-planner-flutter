import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

class DayBlockingResult {
  final DateTime blockedDate;
  final List<FollowUpCall> updatedCalls;
  final List<FollowUpCall> movedCalls;

  const DayBlockingResult({
    required this.blockedDate,
    required this.updatedCalls,
    required this.movedCalls,
  });

  int get movedCallCount => movedCalls.length;
}
