import 'package:flutter/foundation.dart';
import 'package:follow_up_planner/core/utils/ist_date_time.dart';

import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/domain/repositories/follow_up_repository.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/day_blocking_result.dart';
import 'package:follow_up_planner/features/follow_up/domain/services/day_blocking_services.dart';

import '../../domain/entities/schedule_snapshot.dart';
import '../../domain/entities/scheduling_result.dart';
import '../../domain/services/call_scheduling_service.dart';
import '../../domain/services/undo_redo_manager.dart';

class FollowUpProvider extends ChangeNotifier {
  FollowUpProvider({required FollowUpRepository repository})
    : _repository = repository;

  final FollowUpRepository _repository;

  // Undo and redo manager.
  final UndoRedoManager _undoRedoManager = UndoRedoManager();

  // Schedule data.
  List<FollowUpCall> _calls = [];
  Set<String> _blockedDateKeys = {};

  // UI states.
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Getters.
  List<FollowUpCall> get calls => List.unmodifiable(_calls);

  Set<String> get blockedDateKeys => Set.unmodifiable(_blockedDateKeys);

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  bool get canUndo => _undoRedoManager.canUndo;

  bool get canRedo => _undoRedoManager.canRedo;

  // Load calls and blocked dates from SQLite.
  Future<void> loadSchedule() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final calls = await _repository.getAllCalls();

      final blockedDates = await _repository.getBlockedDates();

      _calls = calls;
      _blockedDateKeys = blockedDates;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add and schedule a new call.
  Future<SchedulingResult?> addCall(FollowUpCall newCall) async {
    if (_isSaving) return null;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Schedule the new call.
      final result = CallSchedulingService.scheduleCall(
        newCall: newCall,
        existingCalls: _calls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 2: Capture the previous state for undo.
      final previousState = ScheduleSnapshot(
        calls: _calls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 3: Save the complete updated schedule atomically.
      await _repository.replaceSchedule(
        calls: result.updatedCalls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 4: Record undo history after successful persistence.
      _undoRedoManager.recordAction(previousState);

      // Step 5: Update in-memory state.
      _calls = result.updatedCalls;

      return result;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Edit and reschedule an existing call.
  Future<SchedulingResult?> editCall(FollowUpCall updatedCall) async {
    if (_isSaving) return null;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Check whether the call exists.
      final callExists = _calls.any((call) => call.id == updatedCall.id);

      if (!callExists) {
        throw Exception('Call not found.');
      }

      // Step 2: Remove the old call before rescheduling.
      final existingCalls = _calls
          .where((call) => call.id != updatedCall.id)
          .toList();

      // Step 3: Capture the previous schedule for undo.
      final previousState = ScheduleSnapshot(
        calls: _calls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 4: Schedule the updated call.
      final result = CallSchedulingService.scheduleCall(
        newCall: updatedCall,
        existingCalls: existingCalls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 5: Save the updated schedule to SQLite.
      await _repository.replaceSchedule(
        calls: result.updatedCalls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 6: Record one undo action.
      _undoRedoManager.recordAction(previousState);

      // Step 7: Update provider state.
      _calls = result.updatedCalls;

      return result;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Delete a call from the schedule.
  Future<bool> deleteCall(String callId) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Check whether the call exists.
      final callExists = _calls.any((call) => call.id == callId);

      if (!callExists) {
        throw Exception('Call not found.');
      }

      // Step 2: Create a new list without the selected call.
      final updatedCalls = _calls.where((call) => call.id != callId).toList();

      // Step 3: Capture the previous state for undo.
      final previousState = ScheduleSnapshot(
        calls: _calls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 4: Save the updated schedule.
      await _repository.replaceSchedule(
        calls: updatedCalls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 5: Record one undo action.
      _undoRedoManager.recordAction(previousState);

      // Step 6: Update provider state.
      _calls = updatedCalls;

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Block a working day and reschedule its calls.
  Future<DayBlockingResult?> blockDay(DateTime date) async {
    if (_isSaving) return null;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Capture the previous schedule for undo.
      final previousState = ScheduleSnapshot(
        calls: _calls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 2: Reschedule all calls from the selected day.
      final result = DayBlockingService.blockDay(
        date: date,
        existingCalls: _calls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 3: Add the blocked date.
      final updatedBlockedDates = {
        ..._blockedDateKeys,
        IstDateTime.dateKey(result.blockedDate),
      };

      // Step 4: Save calls and blocked dates atomically.
      await _repository.replaceSchedule(
        calls: result.updatedCalls,
        blockedDateKeys: updatedBlockedDates,
      );

      // Step 5: Record one undo action.
      _undoRedoManager.recordAction(previousState);

      // Step 6: Update provider state.
      _calls = result.updatedCalls;
      _blockedDateKeys = updatedBlockedDates;

      return result;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Undo the last schedule operation.
  Future<bool> undo() async {
    if (_isSaving || !_undoRedoManager.canUndo) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final currentState = ScheduleSnapshot(
      calls: _calls,
      blockedDateKeys: _blockedDateKeys,
    );

    ScheduleSnapshot? previousState;

    try {
      // Step 1: Retrieve the previous state.
      previousState = _undoRedoManager.undo(currentState);

      if (previousState == null) return false;

      // Step 2: Restore the previous schedule in SQLite.
      await _repository.replaceSchedule(
        calls: previousState.calls,
        blockedDateKeys: previousState.blockedDateKeys,
      );

      // Step 3: Update provider state.
      _calls = previousState.calls.toList();
      _blockedDateKeys = previousState.blockedDateKeys.toSet();

      return true;
    } catch (error) {
      // Restore undo history if database saving fails.
      if (previousState != null) {
        _undoRedoManager.redo(previousState);
      }

      _errorMessage = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Redo the previously undone schedule operation.
  Future<bool> redo() async {
    if (_isSaving || !_undoRedoManager.canRedo) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final currentState = ScheduleSnapshot(
      calls: _calls,
      blockedDateKeys: _blockedDateKeys,
    );

    ScheduleSnapshot? nextState;

    try {
      // Step 1: Retrieve the next state.
      nextState = _undoRedoManager.redo(currentState);

      if (nextState == null) return false;

      // Step 2: Restore the schedule in SQLite.
      await _repository.replaceSchedule(
        calls: nextState.calls,
        blockedDateKeys: nextState.blockedDateKeys,
      );

      // Step 3: Update provider state.
      _calls = nextState.calls.toList();
      _blockedDateKeys = nextState.blockedDateKeys.toSet();

      return true;
    } catch (error) {
      // Restore redo history if database saving fails.
      if (nextState != null) {
        _undoRedoManager.undo(nextState);
      }

      _errorMessage = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
