import 'package:flutter_test/flutter_test.dart';

import 'package:follow_up_planner/core/errors/app_exception.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/services/day_blocking_services.dart';

void main() {
  // Helper function to create test calls.
  FollowUpCall createCall({
    required String id,
    required DateTime scheduledAt,
    required CallPriority priority,
    String? phoneNumber,
  }) {
    return FollowUpCall(
      id: id,
      leadName: 'Lead $id',
      phoneNumber:
          phoneNumber ?? id.codeUnits.map((code) => code.toString()).join(),
      priority: priority,
      dealValuePaise: 100000,
      requestedAt: scheduledAt,
      scheduledAt: scheduledAt,
      createdAt: scheduledAt,
    );
  }

  group('DayBlockingService', () {
    final blockedDate = DateTime.utc(2026, 11, 3);

    test('moves all calls from the blocked day', () {
      final existingCalls = [
        createCall(
          id: 'warm-1',
          scheduledAt: DateTime.utc(2026, 11, 3, 10),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'cold-1',
          scheduledAt: DateTime.utc(2026, 11, 3, 11),
          priority: CallPriority.cold,
        ),
      ];

      final result = DayBlockingService.blockDay(
        date: blockedDate,
        existingCalls: existingCalls,
      );

      expect(result.movedCallCount, 2);
      expect(result.updatedCalls.length, 2);

      expect(
        result.updatedCalls.every(
          (call) =>
              call.scheduledAt.year == 2026 &&
              call.scheduledAt.month == 11 &&
              call.scheduledAt.day == 4,
        ),
        isTrue,
        reason:
            'Actual scheduled dates: ${result.updatedCalls.map((call) => '${call.id}: ${call.scheduledAt.toIso8601String()}').join(', ')}',
      );

      // No calls should remain on the blocked date.
      expect(
        result.updatedCalls.any(
          (call) =>
              call.scheduledAt.year == 2026 &&
              call.scheduledAt.month == 11 &&
              call.scheduledAt.day == 3,
        ),
        false,
      );
    });

    test('schedules Hot calls before Warm and Cold calls', () {
      final existingCalls = [
        createCall(
          id: 'cold',
          scheduledAt: DateTime.utc(2026, 11, 3, 10),
          priority: CallPriority.cold,
        ),
        createCall(
          id: 'warm',
          scheduledAt: DateTime.utc(2026, 11, 3, 11),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'hot',
          scheduledAt: DateTime.utc(2026, 11, 3, 12),
          priority: CallPriority.hot,
        ),
      ];

      final result = DayBlockingService.blockDay(
        date: blockedDate,
        existingCalls: existingCalls,
      );

      final hotCall = result.updatedCalls.firstWhere(
        (call) => call.id == 'hot',
      );

      final warmCall = result.updatedCalls.firstWhere(
        (call) => call.id == 'warm',
      );

      final coldCall = result.updatedCalls.firstWhere(
        (call) => call.id == 'cold',
      );

      expect(hotCall.scheduledAt.isBefore(warmCall.scheduledAt), true);

      expect(warmCall.scheduledAt.isBefore(coldCall.scheduledAt), true);
    });

    test('preserves original time order for equal priorities', () {
      final existingCalls = [
        createCall(
          id: 'warm-late',
          scheduledAt: DateTime.utc(2026, 11, 3, 11),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'warm-early',
          scheduledAt: DateTime.utc(2026, 11, 3, 10),
          priority: CallPriority.warm,
        ),
      ];

      final result = DayBlockingService.blockDay(
        date: blockedDate,
        existingCalls: existingCalls,
      );

      final warmCalls =
          result.updatedCalls
              .where((call) => call.priority == CallPriority.warm)
              .toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      expect(warmCalls.first.id, 'warm-early');
      expect(warmCalls.last.id, 'warm-late');
    });

    test('starts rescheduling from 09:30 on the next working day', () {
      final existingCalls = [
        createCall(
          id: 'warm-1',
          scheduledAt: DateTime.utc(2026, 11, 3, 10),
          priority: CallPriority.warm,
        ),
      ];

      final result = DayBlockingService.blockDay(
        date: blockedDate,
        existingCalls: existingCalls,
      );

      expect(
        result.updatedCalls.first.scheduledAt,
        DateTime.utc(2026, 11, 4, 9, 30),
      );
    });

    test('does not allow blocking a Sunday', () {
      expect(
        () => DayBlockingService.blockDay(
          date: DateTime.utc(2026, 11, 8),
          existingCalls: [],
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('does not allow blocking a company holiday', () {
      expect(
        () => DayBlockingService.blockDay(
          date: DateTime.utc(2026, 12, 25),
          existingCalls: [],
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('returns an empty moved list when the blocked day has no calls', () {
      final result = DayBlockingService.blockDay(
        date: blockedDate,
        existingCalls: [],
      );

      expect(result.movedCalls, isEmpty);
      expect(result.updatedCalls, isEmpty);
      expect(result.movedCallCount, 0);
    });

    test('skips second Saturday and Sunday while rescheduling', () {
      final result = DayBlockingService.blockDay(
        date: DateTime.utc(2026, 11, 13),
        existingCalls: [
          createCall(
            id: 'warm-1',
            scheduledAt: DateTime.utc(2026, 11, 13, 10),
            priority: CallPriority.warm,
          ),
        ],
      );

      expect(
        result.updatedCalls.first.scheduledAt,
        DateTime.utc(2026, 11, 16, 9, 30),
      );
    });

    test('skips company holiday and non-working days while rescheduling', () {
      final result = DayBlockingService.blockDay(
        date: DateTime.utc(2026, 12, 24),
        existingCalls: [
          createCall(
            id: 'warm-1',
            scheduledAt: DateTime.utc(2026, 12, 24, 10),
            priority: CallPriority.warm,
          ),
        ],
      );

      expect(
        result.updatedCalls.first.scheduledAt,
        DateTime.utc(2026, 12, 28, 9, 30),
      );
    });

    test(
      'does not schedule the same normalized phone number twice on one day',
      () {
        final existingCalls = [
          createCall(
            id: 'existing',
            scheduledAt: DateTime.utc(2026, 11, 4, 9, 30),
            priority: CallPriority.warm,
            phoneNumber: '9876543210',
          ),
          createCall(
            id: 'moving',
            scheduledAt: DateTime.utc(2026, 11, 3, 10),
            priority: CallPriority.hot,
            phoneNumber: '98765 43210',
          ),
        ];

        final result = DayBlockingService.blockDay(
          date: blockedDate,
          existingCalls: existingCalls,
        );

        final movedCall = result.updatedCalls.firstWhere(
          (call) => call.id == 'moving',
        );

        expect(movedCall.scheduledAt, DateTime.utc(2026, 11, 5, 9, 30));
      },
    );

    test('moves a call to the next day when the next working day is full', () {
      final existingCalls = [
        createCall(
          id: 'moving',
          scheduledAt: DateTime.utc(2026, 11, 3, 10),
          priority: CallPriority.hot,
        ),
        createCall(
          id: 'existing-1',
          scheduledAt: DateTime.utc(2026, 11, 4, 9, 30),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'existing-2',
          scheduledAt: DateTime.utc(2026, 11, 4, 10),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'existing-3',
          scheduledAt: DateTime.utc(2026, 11, 4, 10, 30),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'existing-4',
          scheduledAt: DateTime.utc(2026, 11, 4, 11),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'existing-5',
          scheduledAt: DateTime.utc(2026, 11, 4, 11, 30),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'existing-6',
          scheduledAt: DateTime.utc(2026, 11, 4, 12),
          priority: CallPriority.warm,
        ),
      ];

      final result = DayBlockingService.blockDay(
        date: blockedDate,
        existingCalls: existingCalls,
      );
      

      final movedCall = result.updatedCalls.firstWhere(
        (call) => call.id == 'moving',
      );

      expect(movedCall.scheduledAt, DateTime.utc(2026, 11, 5, 9, 30));
    });
  });
}
