import 'package:flutter_test/flutter_test.dart';

import 'package:follow_up_planner/core/errors/app_exception.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/services/day_blocking_services.dart';

void main() {
  group('DayBlockingService', () {
    final blockedDate = DateTime.utc(2026, 11, 3);

    FollowUpCall createCall({
      required String id,
      required DateTime scheduledAt,
      required CallPriority priority,
      String? phoneNumber,
    }) {
      return FollowUpCall(
        id: id,
        leadName: 'Lead $id',
        phoneNumber: phoneNumber ?? '98765432${id.hashCode.abs() % 100}',
        priority: priority,
        dealValuePaise: 100000,
        requestedAt: scheduledAt,
        scheduledAt: scheduledAt,
        createdAt: scheduledAt,
      );
    }

    test('moves all calls from the blocked day', () {
      final existingCalls = [
        createCall(
          id: 'warm-1',
          scheduledAt: DateTime.utc(2026, 11, 3, 10, 0),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'cold-1',
          scheduledAt: DateTime.utc(2026, 11, 3, 11, 0),
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
        true,
      );
    });

    test('schedules Hot calls before Warm and Cold calls', () {
      final existingCalls = [
        createCall(
          id: 'cold-1',
          scheduledAt: DateTime.utc(2026, 11, 3, 10, 0),
          priority: CallPriority.cold,
        ),
        createCall(
          id: 'warm-1',
          scheduledAt: DateTime.utc(2026, 11, 3, 11, 0),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'hot-1',
          scheduledAt: DateTime.utc(2026, 11, 3, 12, 0),
          priority: CallPriority.hot,
        ),
      ];

      final result = DayBlockingService.blockDay(
        date: blockedDate,
        existingCalls: existingCalls,
      );

      final hotCall = result.updatedCalls.firstWhere(
        (call) => call.id == 'hot-1',
      );

      final warmCall = result.updatedCalls.firstWhere(
        (call) => call.id == 'warm-1',
      );

      final coldCall = result.updatedCalls.firstWhere(
        (call) => call.id == 'cold-1',
      );

      expect(hotCall.scheduledAt.isBefore(warmCall.scheduledAt), true);

      expect(warmCall.scheduledAt.isBefore(coldCall.scheduledAt), true);
    });

    test('preserves original time order for equal priorities', () {
      final existingCalls = [
        createCall(
          id: 'warm-late',
          scheduledAt: DateTime.utc(2026, 11, 3, 11, 0),
          priority: CallPriority.warm,
        ),
        createCall(
          id: 'warm-early',
          scheduledAt: DateTime.utc(2026, 11, 3, 10, 0),
          priority: CallPriority.warm,
        ),
      ];

      final result = DayBlockingService.blockDay(
        date: blockedDate,
        existingCalls: existingCalls,
      );

      final movedWarmCalls =
          result.updatedCalls
              .where((call) => call.priority == CallPriority.warm)
              .toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      expect(movedWarmCalls[0].id, 'warm-early');
      expect(movedWarmCalls[1].id, 'warm-late');
    });

    test('starts rescheduling from 09:30 on the next working day', () {
      final existingCalls = [
        createCall(
          id: 'warm-1',
          scheduledAt: DateTime.utc(2026, 11, 3, 10, 0),
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
  });
}
