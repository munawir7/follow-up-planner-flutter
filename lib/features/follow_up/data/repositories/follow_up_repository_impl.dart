import 'package:follow_up_planner/core/errors/app_exception.dart';
import 'package:follow_up_planner/features/follow_up/data/datasources/local/follow_up_local_data_source.dart';
import 'package:follow_up_planner/features/follow_up/data/models/follow_up_call_model.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/schedule_diff.dart';
import 'package:follow_up_planner/features/follow_up/domain/repositories/follow_up_repository.dart';

class FollowUpRepositoryImpl implements FollowUpRepository {
  final FollowUpLocalDataSource _localDataSource;

  FollowUpRepositoryImpl({required FollowUpLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  @override
  Future<List<FollowUpCallModel>> getAllCalls() async {
    try {
      return await _localDataSource.getAllCalls();
    } catch (error) {
      throw AppException(
        'Failed to fetch follow-up calls: $error',
        code: 'FETCH_CALLS_FAILED',
      );
    }
  }

  @override
  Future<void> applyScheduleDiff({
    required ScheduleDiff diff,
    required Set<String> blockedDateKeysToAdd,
    required Set<String> blockedDateKeysToRemove,
  }) async {
    try {
      await _localDataSource.applyScheduleDiff(
        inserted: diff.inserted.map(FollowUpCallModel.fromEntity).toList(),
        updated: diff.updated.map(FollowUpCallModel.fromEntity).toList(),
        deletedIds: diff.deletedIds,
        blockedDateKeysToAdd: blockedDateKeysToAdd,
        blockedDateKeysToRemove: blockedDateKeysToRemove,
      );
    } catch (error) {
      throw AppException(
        'Failed to apply schedule changes: $error',
        code: 'APPLY_SCHEDULE_DIFF_FAILED',
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
  Future<void> replaceSchedule({
    required List<FollowUpCall> calls,
    required Set<String> blockedDateKeys,
  }) async {
    try {
      await _localDataSource.replaceSchedule(
        calls: calls.map(FollowUpCallModel.fromEntity).toList(),
        blockedDateKeys: blockedDateKeys,
      );
    } catch (error) {
      throw AppException(
        'Failed to restore schedule: $error',
        code: 'REPLACE_SCHEDULE_FAILED',
      );
    }
  }
}
