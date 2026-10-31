import 'package:follow_up_planner/domain/entities/follow_up_call.dart';

class SchedulingResult {
  final FollowUpCall scheduledCall;
  final List<FollowUpCall> updatedCalls;
  final FollowUpCall? displacedCall;

  const SchedulingResult({
    required this.scheduledCall,
    required this.updatedCalls,
    this.displacedCall,
  });

  bool get hasDisplacement => displacedCall != null;
}
