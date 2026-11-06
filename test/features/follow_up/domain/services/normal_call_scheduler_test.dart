import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

import 'package:follow_up_planner/features/follow_up/domain/services/normal_call_scheduler.dart';

void main() {
  group('NormalCallScheduler', () {
    final requestedDate = DateTime.utc(2026, 11, 3);

    FollowUpCall createCall({
      required String id,
      required DateTime requestedAt,
      required CallPriority priority,
      String phoneNumber = '9876543210',
    }) {
      return FollowUpCall(
        id: id,
        leadName: 'Lead $id',
        phoneNumber: phoneNumber,
        priority: priority,
        dealValuePaise: 100000,
        requestedAt: requestedAt,
        scheduledAt: requestedAt,
        createdAt: requestedAt,
      );
    }

    test('schedules a Warm call in the first available slot', () {
      final call = createCall(
        id: 'warm-1',
        requestedAt: requestedDate,
        priority: CallPriority.warm,
      );

      final result = NormalCallScheduler.scheduleCall(
        newCall: call,
        existingCalls: [],
        now: DateTime.utc(2026, 11, 3, 9, 0),
      );

      expect(
        result.scheduledCall.scheduledAt,
        DateTime.utc(2026, 11, 3, 9, 30),
      );
      expect(result.updatedCalls.length, 1);
    });

    test('schedules a Cold call after an occupied slot', () {
      final existingCall = createCall(
        id: 'existing',
        requestedAt: DateTime.utc(2026, 11, 3, 9, 30),
        priority: CallPriority.warm,
      );

      final coldCall = createCall(
        id: 'cold-1',
        requestedAt: DateTime.utc(2026, 11, 3, 9, 30),
        priority: CallPriority.cold,
        phoneNumber: '9876543211',
      );

      final result = NormalCallScheduler.scheduleCall(
        newCall: coldCall,
        existingCalls: [existingCall],
        now: DateTime.utc(2026, 11, 3, 9, 0),
      );

      expect(
        result.scheduledCall.scheduledAt,
        DateTime.utc(2026, 11, 3, 10, 0),
      );
    });

    test('rejects Hot calls', () {
      final hotCall = createCall(
        id: 'hot-1',
        requestedAt: requestedDate,
        priority: CallPriority.hot,
      );

      expect(
        () => NormalCallScheduler.scheduleCall(
          newCall: hotCall,
          existingCalls: [],
        ),
        throwsArgumentError,
      );
    });
  });
}
