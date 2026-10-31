import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/services/next_available_slot_finder.dart';

void main() {
  group('NextAvailableSlotFinder', () {
    final requestedAt = DateTime.utc(2026, 11, 3, 10, 0);

    test('should return requested time when it is available', () {
      final result = NextAvailableSlotFinder.findNextAvailableSlot(
        requestedAt: requestedAt,
        existingCalls: [],
        phoneNumber: '9123456789',
      );

      expect(result, requestedAt);
    });

    test('should return next slot when requested slot is occupied', () {
      final existingCalls = [
        FollowUpCall(
          id: '1',
          leadName: 'Test Lead',
          phoneNumber: '9876543210',
          priority: CallPriority.warm,
          dealValuePaise: 100000,
          requestedAt: requestedAt,
          scheduledAt: requestedAt,
          createdAt: requestedAt,
        ),
      ];

      final result = NextAvailableSlotFinder.findNextAvailableSlot(
        requestedAt: requestedAt,
        existingCalls: existingCalls,
        phoneNumber: '9123456789',
      );

      expect(result, DateTime.utc(2026, 11, 3, 10, 30));
    });

    test('should skip Sunday and find next working day', () {
      final result = NextAvailableSlotFinder.findNextAvailableSlot(
        requestedAt: DateTime.utc(2026, 11, 8, 10, 0),
        existingCalls: [],
        phoneNumber: '9123456789',
      );

      expect(result, DateTime.utc(2026, 11, 10, 9, 30));
    });

    test('should skip lunch break and find next available slot', () {
      final result = NextAvailableSlotFinder.findNextAvailableSlot(
        requestedAt: DateTime.utc(2026, 11, 3, 13, 0),
        existingCalls: [],
        phoneNumber: '9123456789',
      );

      expect(result, DateTime.utc(2026, 11, 3, 14, 0));
    });
  });
}
