import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';

import 'package:follow_up_planner/features/follow_up/domain/entities/schedule_snapshot.dart';
import 'package:follow_up_planner/features/follow_up/domain/services/undo_redo_manager.dart';

void main() {
  late UndoRedoManager manager;

  ScheduleSnapshot createSnapshot({
    required String id,
    Set<String> blockedDateKeys = const {},
  }) {
    final call = FollowUpCall(
      id: id,
      leadName: 'Test Lead',
      phoneNumber: '9876543210',
      priority: CallPriority.warm,
      dealValuePaise: 100000,
      requestedAt: DateTime.utc(2026, 11, 3, 10),
      scheduledAt: DateTime.utc(2026, 11, 3, 10),
      createdAt: DateTime.utc(2026, 11, 2),
    );

    return ScheduleSnapshot(calls: [call], blockedDateKeys: blockedDateKeys);
  }

  setUp(() {
    manager = UndoRedoManager();
  });

  group('UndoRedoManager', () {
    test('initially undo and redo should be unavailable', () {
      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isFalse);
    });

    test('recording an action should enable undo', () {
      final previousState = createSnapshot(id: 'call-1');

      manager.recordAction(previousState);

      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isFalse);
    });

    test('undo should restore previous snapshot and enable redo', () {
      final previousState = createSnapshot(id: 'call-1');
      final currentState = createSnapshot(id: 'call-2');

      manager.recordAction(previousState);

      final restoredState = manager.undo(currentState);

      expect(restoredState, isNotNull);
      expect(restoredState!.calls.first.id, 'call-1');
      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isTrue);
    });

    test('redo should restore the undone snapshot', () {
      final previousState = createSnapshot(id: 'call-1');
      final currentState = createSnapshot(id: 'call-2');

      manager.recordAction(previousState);

      manager.undo(currentState);

      final restoredState = manager.redo(previousState);

      expect(restoredState, isNotNull);
      expect(restoredState!.calls.first.id, 'call-2');
      expect(manager.canRedo, isFalse);
      expect(manager.canUndo, isTrue);
    });

    test('new action should clear redo history', () {
      final firstState = createSnapshot(id: 'call-1');
      final secondState = createSnapshot(id: 'call-2');
      final thirdState = createSnapshot(id: 'call-3');

      manager.recordAction(firstState);
      manager.undo(secondState);

      expect(manager.canRedo, isTrue);

      manager.recordAction(thirdState);

      expect(manager.canRedo, isFalse);
      expect(manager.canUndo, isTrue);
    });

    test('undo history should not exceed 20 steps', () {
      for (var i = 0; i < 25; i++) {
        manager.recordAction(createSnapshot(id: 'call-$i'));
      }

      var undoCount = 0;

      while (manager.canUndo) {
        manager.undo(createSnapshot(id: 'current-$undoCount'));
        undoCount++;
      }

      expect(undoCount, 20);
    });

    test('undo should return null when history is empty', () {
      final result = manager.undo(createSnapshot(id: 'current'));

      expect(result, isNull);
    });

    test('redo should return null when redo history is empty', () {
      final result = manager.redo(createSnapshot(id: 'current'));

      expect(result, isNull);
    });

    test('snapshot should preserve blocked dates', () {
      final previousState = createSnapshot(
        id: 'call-1',
        blockedDateKeys: {'2026-11-03'},
      );

      manager.recordAction(previousState);

      final restoredState = manager.undo(createSnapshot(id: 'call-2'));

      expect(restoredState!.blockedDateKeys, contains('2026-11-03'));
    });
  });
}
