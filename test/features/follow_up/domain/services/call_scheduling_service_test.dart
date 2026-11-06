import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

import 'package:follow_up_planner/features/follow_up/domain/services/call_scheduling_service.dart';

void main() {
  group('CallSchedulingService', () {
    final requestedDate = DateTime.utc(2026, 11, 3);

    FollowUpCall createCall({
      required String id,
      required CallPriority priority,
    }) {
      return FollowUpCall(
        id: id,
        leadName: 'Lead $id',
        phoneNumber: '9876543210',
        priority: priority,
        dealValuePaise: 100000,
        requestedAt: requestedDate,
        scheduledAt: requestedDate,
        createdAt: requestedDate,
      );
    }

    test('routes Hot calls to HotCallScheduler', () {
      final call = createCall(id: 'hot-1', priority: CallPriority.hot);

      final result = CallSchedulingService.scheduleCall(
        newCall: call,
        existingCalls: [],
        now: DateTime.utc(2026, 11, 3, 9, 0),
      );

      expect(result.scheduledCall.priority, CallPriority.hot);
      expect(
        result.scheduledCall.scheduledAt,
        DateTime.utc(2026, 11, 3, 9, 30),
      );
    });

    test('routes Warm calls to NormalCallScheduler', () {
      final call = createCall(id: 'warm-1', priority: CallPriority.warm);

      final result = CallSchedulingService.scheduleCall(
        newCall: call,
        existingCalls: [],
        now: DateTime.utc(2026, 11, 3, 9, 0),
      );

      expect(result.scheduledCall.priority, CallPriority.warm);
      expect(
        result.scheduledCall.scheduledAt,
        DateTime.utc(2026, 11, 3, 9, 30),
      );
    });

    test('routes Cold calls to NormalCallScheduler', () {
      final call = createCall(id: 'cold-1', priority: CallPriority.cold);

      final result = CallSchedulingService.scheduleCall(
        newCall: call,
        existingCalls: [],
        now: DateTime.utc(2026, 11, 3, 9, 0),
      );

      expect(result.scheduledCall.priority, CallPriority.cold);
      expect(
        result.scheduledCall.scheduledAt,
        DateTime.utc(2026, 11, 3, 9, 30),
      );
    });
  });
}
