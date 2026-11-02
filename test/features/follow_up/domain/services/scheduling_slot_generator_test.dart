import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/features/follow_up/domain/services/scheduling_slot_generator.dart';

void main() {
  group('SchedulingSlotGenerator', () {
    test('should generate 16 slots for a normal working day', () {
      final slots = SchedulingSlotGenerator.generateSlotsForDay(
        DateTime(2026, 11, 3),
      );

      expect(slots.length, 16);
    });

    test('first slot should start at 09:30 AM', () {
      final slots = SchedulingSlotGenerator.generateSlotsForDay(
        DateTime(2026, 11, 3),
      );

      expect(slots.first.hour, 9);
      expect(slots.first.minute, 30);
    });

    test('last slot should start at 06:00 PM', () {
      final slots = SchedulingSlotGenerator.generateSlotsForDay(
        DateTime(2026, 11, 3),
      );

      expect(slots.last.hour, 18);
      expect(slots.last.minute, 0);
    });

    test('should not generate lunch break slots', () {
      final slots = SchedulingSlotGenerator.generateSlotsForDay(
        DateTime(2026, 11, 3),
      );

      final lunchSlots = slots.where((slot) => slot.hour == 13);

      expect(lunchSlots, isEmpty);
    });

    test('should return empty slots for Sunday', () {
      final slots = SchedulingSlotGenerator.generateSlotsForDay(
        DateTime(2026, 11, 8),
      );

      expect(slots, isEmpty);
    });

    test('should return empty slots for company holiday', () {
      final slots = SchedulingSlotGenerator.generateSlotsForDay(
        DateTime(2026, 12, 25),
      );

      expect(slots, isEmpty);
    });
  });
}
