import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:follow_up_planner/core/errors/app_exception.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/data/datasources/local/follow_up_local_data_source.dart';
import 'package:follow_up_planner/features/follow_up/data/models/follow_up_call_model.dart';
import 'package:follow_up_planner/features/follow_up/data/repositories/follow_up_repository_impl.dart';

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

  // ADD CALL

  group('addCall', () {
    test('should add a follow-up call successfully', () async {
      when(() => localDataSource.insertCall(any())).thenAnswer((_) async {});

      await repository.addCall(testCall);

      verify(() => localDataSource.insertCall(any())).called(1);
    });

    test('should throw AppException when adding call fails', () async {
      when(
        () => localDataSource.insertCall(any()),
      ).thenThrow(Exception('Insert error'));

      await expectLater(
        repository.addCall(testCall),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'ADD_CALL_FAILED'),
        ),
      );
    });
  });

  // UPDATE CALL

  group('updateCall', () {
    test('should update a follow-up call successfully', () async {
      when(() => localDataSource.updateCall(any())).thenAnswer((_) async {});

      await repository.updateCall(testCall);

      verify(() => localDataSource.updateCall(any())).called(1);
    });

    test('should throw AppException when updating call fails', () async {
      when(
        () => localDataSource.updateCall(any()),
      ).thenThrow(Exception('Update error'));

      await expectLater(
        repository.updateCall(testCall),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'UPDATE_CALL_FAILED',
          ),
        ),
      );
    });
  });

  // DELETE CALL

  group('deleteCall', () {
    test('should delete a follow-up call successfully', () async {
      when(
        () => localDataSource.deleteCall('call_001'),
      ).thenAnswer((_) async {});

      await repository.deleteCall('call_001');

      verify(() => localDataSource.deleteCall('call_001')).called(1);
    });

    test('should throw AppException when deleting call fails', () async {
      when(
        () => localDataSource.deleteCall('call_001'),
      ).thenThrow(Exception('Delete error'));

      await expectLater(
        repository.deleteCall('call_001'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'DELETE_CALL_FAILED',
          ),
        ),
      );
    });
  });

  // REPLACE ALL CALLS

  group('replaceAllCalls', () {
    test('should replace all calls successfully', () async {
      when(
        () => localDataSource.replaceAllCalls(any()),
      ).thenAnswer((_) async {});

      await repository.replaceAllCalls([testCall]);

      verify(() => localDataSource.replaceAllCalls(any())).called(1);
    });

    test('should throw AppException when replacing calls fails', () async {
      when(
        () => localDataSource.replaceAllCalls(any()),
      ).thenThrow(Exception('Restore error'));

      await expectLater(
        repository.replaceAllCalls([testCall]),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'RESTORE_CALLS_FAILED',
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

      expect(result, isA<Set<String>>());

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

  // BLOCK DATE

  group('blockDate', () {
    test('should block a date successfully', () async {
      when(
        () => localDataSource.blockDate('2026-10-30'),
      ).thenAnswer((_) async {});

      await repository.blockDate('2026-10-30');

      verify(() => localDataSource.blockDate('2026-10-30')).called(1);
    });

    test('should throw AppException when blocking date fails', () async {
      when(
        () => localDataSource.blockDate('2026-10-30'),
      ).thenThrow(Exception('Block date error'));

      await expectLater(
        repository.blockDate('2026-10-30'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'BLOCK_DATE_FAILED',
          ),
        ),
      );
    });
  });

  // UNBLOCK DATE

  group('unblockDate', () {
    test('should unblock a date successfully', () async {
      when(
        () => localDataSource.unblockDate('2026-10-30'),
      ).thenAnswer((_) async {});

      await repository.unblockDate('2026-10-30');

      verify(() => localDataSource.unblockDate('2026-10-30')).called(1);
    });

    test('should throw AppException when unblocking date fails', () async {
      when(
        () => localDataSource.unblockDate('2026-10-30'),
      ).thenThrow(Exception('Unblock date error'));

      await expectLater(
        repository.unblockDate('2026-10-30'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'UNBLOCK_DATE_FAILED',
          ),
        ),
      );
    });
  });

  // REPLACE BLOCKED DATES

  group('replaceBlockedDates', () {
    test('should replace blocked dates successfully', () async {
      final dates = {'2026-10-30', '2026-10-31'};

      when(
        () => localDataSource.replaceBlockedDates(any()),
      ).thenAnswer((_) async {});

      await repository.replaceBlockedDates(dates);

      verify(() => localDataSource.replaceBlockedDates(any())).called(1);
    });

    test(
      'should throw AppException when replacing blocked dates fails',
      () async {
        final dates = {'2026-10-30'};

        when(
          () => localDataSource.replaceBlockedDates(any()),
        ).thenThrow(Exception('Restore blocked dates error'));

        await expectLater(
          repository.replaceBlockedDates(dates),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              'RESTORE_BLOCKED_DATES_FAILED',
            ),
          ),
        );
      },
    );
  });
}
