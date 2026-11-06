import 'package:flutter/foundation.dart';
import 'package:follow_up_planner/core/errors/app_exception.dart';
import 'package:follow_up_planner/core/utils/ist_date_time.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/repositories/follow_up_repository.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/day_blocking_result.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/schedule_diff.dart';
import 'package:follow_up_planner/features/follow_up/domain/services/day_blocking_service.dart';

import '../../domain/entities/schedule_snapshot.dart';
import '../../domain/entities/scheduling_result.dart';
import '../../domain/services/call_scheduling_service.dart';
import '../../domain/services/undo_redo_manager.dart';

class FollowUpProvider extends ChangeNotifier {
  FollowUpProvider({
  required FollowUpRepository repository,
  DateTime Function()? nowProvider,
}) : _repository = repository,
     _nowProvider = nowProvider ?? IstDateTime.nowIst;

  final FollowUpRepository _repository;
  final DateTime Function() _nowProvider;
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

  // Friendly error handling.
  String _getFriendlyErrorMessage(Object error, StackTrace stackTrace) {
    debugPrint('FollowUpProvider Error: $error');
    debugPrint('StackTrace: $stackTrace');

    if (error is AppException) {
      return error.message;
    }

    return 'Something went wrong, Please try again.';
  }

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
    } catch (error, stackTrace) {
      _errorMessage = _getFriendlyErrorMessage(error, stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate and persist only the changed schedule records.
  Future<void> _saveScheduleDiff({
    required List<FollowUpCall> updatedCalls,
    Set<String> blockedDateKeysToAdd = const <String>{},
    Set<String> blockedDateKeysToRemove = const <String>{},
  }) async {
    final diff = ScheduleDiff.calculate(
      previousCalls: _calls,
      updatedCalls: updatedCalls,
    );

    await _repository.applyScheduleDiff(
      diff: diff,
      blockedDateKeysToAdd: blockedDateKeysToAdd,
      blockedDateKeysToRemove: blockedDateKeysToRemove,
    );
  }

  // Add and schedule a new call.
  Future<SchedulingResult?> addCall(FollowUpCall newCall) async {
    if (_isSaving) return null;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {

    final result = CallSchedulingService.scheduleCall(
  newCall: newCall,
  existingCalls: _calls,
  blockedDateKeys: _blockedDateKeys,
  now: _nowProvider(),
);
      // Step 2: Capture the previous state for undo.
      final previousState = ScheduleSnapshot(
        calls: _calls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 3: Save only changed records.
      await _saveScheduleDiff(updatedCalls: result.updatedCalls);

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
      // Step 1: Find the existing call.
      final existingCall = _calls.firstWhere(
        (call) => call.id == updatedCall.id,
        orElse: () => throw Exception('Call not found.'),
      );

     final schedulingChanged =
    existingCall.priority != updatedCall.priority ||
    !updatedCall.requestedAt.isAtSameMomentAs(existingCall.requestedAt);


      final previousState = ScheduleSnapshot(
        calls: _calls,
        blockedDateKeys: _blockedDateKeys,
      );

      late SchedulingResult result;

      if (!schedulingChanged) {
        // Only lead details changed.
        // Preserve the existing scheduled and originally requested times.
        final updatedCallInPlace = updatedCall.copyWith(
          scheduledAt: existingCall.scheduledAt,
          requestedAt: existingCall.requestedAt,
        );

        final updatedCalls = _calls.map((call) {
          return call.id == updatedCall.id ? updatedCallInPlace : call;
        }).toList();

        result = SchedulingResult(
          scheduledCall: updatedCallInPlace,
          updatedCalls: updatedCalls,

        );
      } else {
        // Scheduling fields changed. Run the scheduler.
        final existingCalls = _calls
            .where((call) => call.id != updatedCall.id)
            .toList();

        result = CallSchedulingService.scheduleCall(
          newCall: updatedCall,
          existingCalls: existingCalls,
          blockedDateKeys: _blockedDateKeys,
          now: _nowProvider(),
        );
      }

      // Step 4: Save only changed records.
      await _saveScheduleDiff(updatedCalls: result.updatedCalls);

      // Step 5: Record one undo action.
      _undoRedoManager.recordAction(previousState);

      // Step 6: Update provider state.
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
        throw const AppException('Call not found.', code: 'CALL_NOT_FOUND');
      }

      // Step 2: Create a new list without the selected call.
      final updatedCalls = _calls.where((call) => call.id != callId).toList();

      // Step 3: Capture the previous state for undo.
      final previousState = ScheduleSnapshot(
        calls: _calls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 4: Save only changed records.
      await _saveScheduleDiff(updatedCalls: updatedCalls);

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
        now: _nowProvider(),
      );

      // Step 3: Get the blocked date key.
      final blockedDateKey = IstDateTime.dateKey(result.blockedDate);

      // Step 4: Save changed calls and the blocked date atomically.
      await _saveScheduleDiff(
        updatedCalls: result.updatedCalls,
        blockedDateKeysToAdd: {blockedDateKey},
      );

      // Step 5: Record one undo action.
      _undoRedoManager.recordAction(previousState);

      // Step 6: Update provider state.
      _calls = result.updatedCalls;
      _blockedDateKeys = {..._blockedDateKeys, blockedDateKey};

      return result;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Unblock a previously blocked day.
  Future<bool> unblockDay(DateTime date) async {
    if (_isSaving) return false;

    final dateKey = IstDateTime.dateKey(date);

    if (!_blockedDateKeys.contains(dateKey)) {
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Capture the previous state for undo.
      final previousState = ScheduleSnapshot(
        calls: _calls,
        blockedDateKeys: _blockedDateKeys,
      );

      // Step 2: Remove the blocked date from SQLite.
      await _saveScheduleDiff(
        updatedCalls: _calls,
        blockedDateKeysToRemove: {dateKey},
      );

      // Step 3: Record undo history.
      _undoRedoManager.recordAction(previousState);

      // Step 4: Update provider state.
      final updatedBlockedDates = Set<String>.from(_blockedDateKeys)
        ..remove(dateKey);

      _blockedDateKeys = updatedBlockedDates;

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Undo the previous schedule operation.
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
