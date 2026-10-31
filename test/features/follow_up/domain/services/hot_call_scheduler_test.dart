import 'package:flutter_test/flutter_test.dart';

import 'package:follow_up_planner/core/errors/app_exception.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/services/hot_call_scheduler.dart';

void main() {
  group('HotCallScheduler', () {
    final requestedDate = DateTime.utc(2026, 11, 3);

    FollowUpCall createCall({
      required String id,
      required DateTime scheduledAt,
      CallPriority priority = CallPriority.warm,
      String phoneNumber = '9876543210',
    }) {
      return FollowUpCall(
        id: id,
        leadName: 'Lead $id',
        phoneNumber: phoneNumber,
        priority: priority,
        dealValuePaise: 100000,
        requestedAt: requestedDate,
        scheduledAt: scheduledAt,
        createdAt: requestedDate,
      );
    }

    test('schedules Hot call in the requested day when a slot is free', () {
      final hotCall = createCall(
        id: 'hot-1',
        scheduledAt: requestedDate,
        priority: CallPriority.hot,
        phoneNumber: '9876543211',
      );

      final result = HotCallScheduler.scheduleHotCall(
        newCall: hotCall,
        existingCalls: [],
      );

      expect(
        result.scheduledCall.scheduledAt,
        requestedDate.add(const Duration(hours: 9, minutes: 30)),
      );
      expect(result.hasDisplacement, false);
    });

    test(
      'moves Hot call to the next working day when requested day is full',
      () {
        final existingCalls = List.generate(
          6,
          (index) => createCall(
            id: 'call-$index',
            scheduledAt: DateTime.utc(2026, 11, 3, 9, 30 + (index * 30)),
            phoneNumber: '98765432${10 + index}',
          ),
        );

        final hotCall = createCall(
          id: 'hot-2',
          scheduledAt: requestedDate,
          priority: CallPriority.hot,
          phoneNumber: '9876543219',
        );

        final result = HotCallScheduler.scheduleHotCall(
          newCall: hotCall,
          existingCalls: existingCalls,
        );

        expect(
          result.scheduledCall.scheduledAt,
          DateTime.utc(2026, 11, 4, 9, 30),
        );
      },
    );

    test('throws AppException when no slot and no Cold call can be moved', () {
      final existingCalls = [
        ...List.generate(
          6,
          (index) => createCall(
            id: 'first-$index',
            scheduledAt: DateTime.utc(2026, 11, 3, 9, 30 + (index * 30)),
          ),
        ),
        ...List.generate(
          6,
          (index) => createCall(
            id: 'second-$index',
            scheduledAt: DateTime.utc(2026, 11, 4, 9, 30 + (index * 30)),
          ),
        ),
      ];

      final hotCall = createCall(
        id: 'hot-3',
        scheduledAt: requestedDate,
        priority: CallPriority.hot,
        phoneNumber: '9876543219',
      );

      expect(
        () => HotCallScheduler.scheduleHotCall(
          newCall: hotCall,
          existingCalls: existingCalls,
        ),
        throwsA(isA<AppException>()),
      );
    });
    test('moves the latest Cold call and assigns its slot to the Hot call', () {
      final existingCalls = [
        // Six calls on the requested day.
        ...List.generate(
          5,
          (index) => createCall(
            id: 'warm-$index',
            scheduledAt: DateTime.utc(2026, 11, 3, 9, 30 + (index * 30)),
            phoneNumber: '98765432${10 + index}',
          ),
        ),

        // Latest Cold call of the requested day.
        createCall(
          id: 'cold-latest',
          scheduledAt: DateTime.utc(2026, 11, 3, 12, 30),
          priority: CallPriority.cold,
          phoneNumber: '9876543290',
        ),

        // Six calls on the next working day.
        ...List.generate(
          6,
          (index) => createCall(
            id: 'next-$index',
            scheduledAt: DateTime.utc(2026, 11, 4, 9, 30 + (index * 30)),
            phoneNumber: '98765433${10 + index}',
          ),
        ),
      ];

      final hotCall = createCall(
        id: 'hot-displacement',
        scheduledAt: requestedDate,
        priority: CallPriority.hot,
        phoneNumber: '9876543299',
      );

      final result = HotCallScheduler.scheduleHotCall(
        newCall: hotCall,
        existingCalls: existingCalls,
      );

      expect(
        result.scheduledCall.scheduledAt,
        DateTime.utc(2026, 11, 3, 12, 30),
      );

      expect(result.hasDisplacement, true);
      expect(result.displacedCall!.id, 'cold-latest');

     expect(
  result.displacedCall!.scheduledAt,
  DateTime.utc(2026, 11, 3, 14, 0),
);

      expect(result.updatedCalls.length, existingCalls.length + 1);
    });
  });
}
