import 'package:follow_up_planner/core/constants/app_constants.dart';

import '../entities/schedule_snapshot.dart';

class UndoRedoManager {
  final List<ScheduleSnapshot> _undoStack = [];
  final List<ScheduleSnapshot> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  void recordAction(ScheduleSnapshot previousState) {
    _undoStack.add(previousState);

    if (_undoStack.length > AppConstants.maxUndoSteps) {
      _undoStack.removeAt(0);
    }

    _redoStack.clear();
  }

  ScheduleSnapshot? undo(ScheduleSnapshot currentState) {
    if (!canUndo) return null;

    _redoStack.add(currentState);

    return _undoStack.removeLast();
  }

  ScheduleSnapshot? redo(ScheduleSnapshot currentState) {
    if (!canRedo) return null;

    _undoStack.add(currentState);

    if (_undoStack.length > AppConstants.maxUndoSteps) {
      _undoStack.removeAt(0);
    }

    return _redoStack.removeLast();
  }
}
