import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:follow_up_planner/features/follow_up/data/repositories/follow_up_repository_impl.dart';
import 'package:follow_up_planner/core/errors/app_exception.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/schedule_diff.dart';
import 'package:follow_up_planner/features/follow_up/data/datasources/local/follow_up_local_data_source.dart';
import 'package:follow_up_planner/features/follow_up/data/models/follow_up_call_model.dart';

class MockFollowUpLocalDataSource extends Mock
    implements FollowUpLocalDataSource {}

class FakeFollowUpCallModel extends Fake implements FollowUpCallModel {}

void main() {
  late MockFollowUpLocalDataSource localDataSource;
  late FollowUpRepositoryImpl repository;

  final testCall = FollowUpCall(
    id: 'call_001',
    leadName: 'John Doe',
    phoneNumber: '9876543210',
    priority: CallPriority.hot,
    dealValuePaise: 500000,
    requestedAt: DateTime(2026, 10, 30, 10, 0),
    scheduledAt: DateTime(2026, 10, 31, 11, 0),
    createdAt: DateTime(2026, 10, 29, 9, 0),
  );

  final testModel = FollowUpCallModel.fromEntity(testCall);

  setUpAll(() {
    registerFallbackValue(FakeFollowUpCallModel());
    registerFallbackValue(<FollowUpCallModel>[]);
    registerFallbackValue(<String>[]);
    registerFallbackValue(<String>{});
  });

  setUp(() {
    localDataSource = MockFollowUpLocalDataSource();
    repository = FollowUpRepositoryImpl(localDataSource: localDataSource);
  });

  // GET ALL CALLS

  group('getAllCalls', () {
    test('should return all follow-up calls', () async {
      when(
        () => localDataSource.getAllCalls(),
      ).thenAnswer((_) async => [testModel]);

      final result = await repository.getAllCalls();

      expect(result, [testModel]);

      verify(() => localDataSource.getAllCalls()).called(1);
    });

    test('should throw AppException when fetching calls fails', () async {
      when(
        () => localDataSource.getAllCalls(),
      ).thenThrow(Exception('Database error'));

      await expectLater(
        repository.getAllCalls(),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'FETCH_CALLS_FAILED',
          ),
        ),
      );
    });
  });

  // GET BLOCKED DATES

  group('getBlockedDates', () {
    test('should return blocked dates as a Set', () async {
      when(
        () => localDataSource.getBlockedDates(),
      ).thenAnswer((_) async => ['2026-10-30', '2026-10-31']);

      final result = await repository.getBlockedDates();

      expect(result, {'2026-10-30', '2026-10-31'});

      verify(() => localDataSource.getBlockedDates()).called(1);
    });

    test(
      'should throw AppException when fetching blocked dates fails',
      () async {
        when(
          () => localDataSource.getBlockedDates(),
        ).thenThrow(Exception('Blocked dates error'));

        await expectLater(
          repository.getBlockedDates(),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              'FETCH_BLOCKED_DATES_FAILED',
            ),
          ),
        );
      },
    );
  });

  // APPLY SCHEDULE DIFF

  group('applyScheduleDiff', () {
    test('should apply schedule changes successfully', () async {
      final diff = ScheduleDiff(
        inserted: [testCall],
        updated: [],
        deletedIds: [],
      );

      when(
        () => localDataSource.applyScheduleDiff(
          inserted: any(named: 'inserted'),
          updated: any(named: 'updated'),
          deletedIds: any(named: 'deletedIds'),
          blockedDateKeysToAdd: any(named: 'blockedDateKeysToAdd'),
          blockedDateKeysToRemove: any(named: 'blockedDateKeysToRemove'),
        ),
      ).thenAnswer((_) async {});

      await repository.applyScheduleDiff(
        diff: diff,
        blockedDateKeysToAdd: {'2026-10-30'},
        blockedDateKeysToRemove: {},
      );

      verify(
        () => localDataSource.applyScheduleDiff(
          inserted: any(named: 'inserted'),
          updated: any(named: 'updated'),
          deletedIds: any(named: 'deletedIds'),
          blockedDateKeysToAdd: any(named: 'blockedDateKeysToAdd'),
          blockedDateKeysToRemove: any(named: 'blockedDateKeysToRemove'),
        ),
      ).called(1);
    });

    test('should throw AppException when applying changes fails', () async {
      final diff = ScheduleDiff(inserted: [testCall]);

      when(
        () => localDataSource.applyScheduleDiff(
          inserted: any(named: 'inserted'),
          updated: any(named: 'updated'),
          deletedIds: any(named: 'deletedIds'),
          blockedDateKeysToAdd: any(named: 'blockedDateKeysToAdd'),
          blockedDateKeysToRemove: any(named: 'blockedDateKeysToRemove'),
        ),
      ).thenThrow(Exception('Database update error'));

      await expectLater(
        repository.applyScheduleDiff(
          diff: diff,
          blockedDateKeysToAdd: {},
          blockedDateKeysToRemove: {},
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'APPLY_SCHEDULE_DIFF_FAILED',
          ),
        ),
      );
    });
  });

  // REPLACE SCHEDULE (UNDO/REDO)

  group('replaceSchedule', () {
    test('should replace the complete schedule successfully', () async {
      when(
        () => localDataSource.replaceSchedule(
          calls: any(named: 'calls'),
          blockedDateKeys: any(named: 'blockedDateKeys'),
        ),
      ).thenAnswer((_) async {});

      await repository.replaceSchedule(
        calls: [testCall],
        blockedDateKeys: {'2026-10-30'},
      );

      verify(
        () => localDataSource.replaceSchedule(
          calls: any(named: 'calls'),
          blockedDateKeys: any(named: 'blockedDateKeys'),
        ),
      ).called(1);
    });

    test('should throw AppException when replacing schedule fails', () async {
      when(
        () => localDataSource.replaceSchedule(
          calls: any(named: 'calls'),
          blockedDateKeys: any(named: 'blockedDateKeys'),
        ),
      ).thenThrow(Exception('Restore error'));

      await expectLater(
        repository.replaceSchedule(calls: [testCall], blockedDateKeys: {}),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'REPLACE_SCHEDULE_FAILED',
          ),
        ),
      );
    });
  });
}
