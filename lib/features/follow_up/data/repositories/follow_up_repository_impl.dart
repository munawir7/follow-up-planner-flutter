import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/domain/repositories/follow_up_repository.dart';

import '../../../../core/errors/app_exception.dart';
import '../datasources/local/follow_up_local_data_source.dart';
import '../models/follow_up_call_model.dart';

class FollowUpRepositoryImpl implements FollowUpRepository {
  FollowUpRepositoryImpl({required FollowUpLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final FollowUpLocalDataSource _localDataSource;

  @override
  Future<List<FollowUpCall>> getAllCalls() async {
    try {
      final models = await _localDataSource.getAllCalls();
      return models;
    } catch (error) {
      throw AppException(
        'Failed to fetch calls: $error',
        code: 'FETCH_CALLS_FAILED',
      );
    }
  }

  @override
  Future<void> replaceSchedule({
    required List<FollowUpCall> calls,
    required Set<String> blockedDateKeys,
  }) async {
    try {
      await _localDataSource.replaceSchedule(
        calls: calls.map((call) => FollowUpCallModel.fromEntity(call)).toList(),
        blockedDateKeys: blockedDateKeys,
      );
    } catch (error) {
      throw AppException(
        'Failed to replace the schedule: $error',
        code: 'REPLACE_SCHEDULE_FAILED',
      );
    }
  }

  @override
  Future<void> addCall(FollowUpCall call) async {
    try {
      final model = FollowUpCallModel.fromEntity(call);
      await _localDataSource.insertCall(model);
    } catch (error) {
      throw AppException('Failed to add call: $error', code: 'ADD_CALL_FAILED');
    }
  }

  @override
  Future<void> updateCall(FollowUpCall call) async {
    try {
      final model = FollowUpCallModel.fromEntity(call);
      await _localDataSource.updateCall(model);
    } catch (error) {
      throw AppException(
        'Failed to update call: $error',
        code: 'UPDATE_CALL_FAILED',
      );
    }
  }

  @override
  Future<void> deleteCall(String id) async {
    try {
      await _localDataSource.deleteCall(id);
    } catch (error) {
      throw AppException(
        'Failed to delete call: $error',
        code: 'DELETE_CALL_FAILED',
      );
    }
  }

  @override
  Future<void> replaceAllCalls(List<FollowUpCall> calls) async {
    try {
      final models = calls
          .map((call) => FollowUpCallModel.fromEntity(call))
          .toList();

      await _localDataSource.replaceAllCalls(models);
    } catch (error) {
      throw AppException(
        'Failed to restore calls: $error',
        code: 'RESTORE_CALLS_FAILED',
      );
    }
  }

  @override
  Future<Set<String>> getBlockedDates() async {
    try {
      final dates = await _localDataSource.getBlockedDates();
      return dates.toSet();
    } catch (error) {
      throw AppException(
        'Failed to fetch blocked dates: $error',
        code: 'FETCH_BLOCKED_DATES_FAILED',
      );
    }
  }

  @override
  Future<void> blockDate(String dateKey) async {
    try {
      await _localDataSource.blockDate(dateKey);
    } catch (error) {
      throw AppException(
        'Failed to block date: $error',
        code: 'BLOCK_DATE_FAILED',
      );
    }
  }

  @override
  Future<void> unblockDate(String dateKey) async {
    try {
      await _localDataSource.unblockDate(dateKey);
    } catch (error) {
      throw AppException(
        'Failed to unblock date: $error',
        code: 'UNBLOCK_DATE_FAILED',
      );
    }
  }

  @override
  Future<void> replaceBlockedDates(Set<String> dateKeys) async {
    try {
      await _localDataSource.replaceBlockedDates(dateKeys.toList());
    } catch (error) {
      throw AppException(
        'Failed to restore blocked dates: $error',
        code: 'RESTORE_BLOCKED_DATES_FAILED',
      );
    }
  }
}
