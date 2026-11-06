import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/repositories/follow_up_repository.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/schedule_diff.dart';
import 'package:follow_up_planner/features/follow_up/presentation/providers/follow_up_provider.dart';

// Mock repository.
class MockFollowUpRepository extends Mock implements FollowUpRepository {}

// Mocktail fallback for ScheduleDiff.
class FakeScheduleDiff extends Fake implements ScheduleDiff {}

void main() {
  late MockFollowUpRepository repository;
  late FollowUpProvider provider;

  // Use a future working date.
  final scheduledTime = DateTime.utc(2026, 11, 5, 10, 0);

  // Create a sample call.
  FollowUpCall createTestCall({
    String id = 'call-1',
    String leadName = 'John',
    String phoneNumber = '9876543210',
    CallPriority priority = CallPriority.warm,
    int dealValuePaise = 100000,
    DateTime? requestedAt,
    DateTime? scheduledAt,
  }) {
    return FollowUpCall(
      id: id,
      leadName: leadName,
      phoneNumber: phoneNumber,
      priority: priority,
      dealValuePaise: dealValuePaise,
      requestedAt: requestedAt ?? scheduledTime,
      scheduledAt: scheduledAt ?? scheduledTime,
      createdAt: scheduledTime,
    );
  }

  setUpAll(() {
    registerFallbackValue(FakeScheduleDiff());
    registerFallbackValue(<String>{});
  });

  setUp(() {
    repository = MockFollowUpRepository();
    provider = FollowUpProvider(
  repository: repository,
   nowProvider: () => DateTime.utc(2026, 11, 6, 9, 0),);

    when(
      () => repository.getAllCalls(),
    ).thenAnswer((_) async => [createTestCall()]);

    when(
      () => repository.getBlockedDates(),
    ).thenAnswer((_) async => <String>{});

    // Mock the new diff-based repository method.
    when(
      () => repository.applyScheduleDiff(
        diff: any(named: 'diff'),
        blockedDateKeysToAdd: any(named: 'blockedDateKeysToAdd'),
        blockedDateKeysToRemove: any(named: 'blockedDateKeysToRemove'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => repository.replaceSchedule(
        calls: any(named: 'calls'),
        blockedDateKeys: any(named: 'blockedDateKeys'),
      ),
    ).thenAnswer((_) async {});
  });

  group('FollowUpProvider editCall', () {
    setUp(() async {
      await provider.loadSchedule();
    });

    test('editing lead name should preserve scheduled time', () async {
      final updatedCall = createTestCall(leadName: 'Updated John');

      final result = await provider.editCall(updatedCall);

      expect(result, isNotNull);
      expect(result!.scheduledCall.leadName, 'Updated John');
      expect(result.scheduledCall.scheduledAt, scheduledTime);
    });

    test('editing phone number should preserve scheduled time', () async {
      final updatedCall = createTestCall(phoneNumber: '9999999999');

      final result = await provider.editCall(updatedCall);

      expect(result, isNotNull);
      expect(result!.scheduledCall.phoneNumber, '9999999999');
      expect(result.scheduledCall.scheduledAt, scheduledTime);
    });

    test('editing deal value should preserve scheduled time', () async {
      final updatedCall = createTestCall(dealValuePaise: 250000);

      final result = await provider.editCall(updatedCall);

      expect(result, isNotNull);
      expect(result!.scheduledCall.dealValuePaise, 250000);
      expect(result.scheduledCall.scheduledAt, scheduledTime);
    });

    test('editing lead details should preserve requested and scheduled times', () async {
  final originalRequestedTime = DateTime.utc(2026, 11, 5, 9, 30);
  final originalScheduledTime = DateTime.utc(2026, 11, 5, 10, 0);

  final originalCall = createTestCall(
    requestedAt: originalRequestedTime,
    scheduledAt: originalScheduledTime,
  );

  // Load the original call into the provider.
  when(
    () => repository.getAllCalls(),
  ).thenAnswer((_) async => [originalCall]);

  await provider.loadSchedule();

  final updatedCall = originalCall.copyWith(
    leadName: 'Updated John',
    dealValuePaise: 250000,
  );

  final result = await provider.editCall(updatedCall);

  expect(result, isNotNull);
  expect(result!.scheduledCall.requestedAt, originalRequestedTime);
  expect(result.scheduledCall.scheduledAt, originalScheduledTime);
  expect(result.scheduledCall.leadName, 'Updated John');
});

    test('changing priority should trigger scheduling', () async {
      final updatedCall = createTestCall(priority: CallPriority.hot);

      final result = await provider.editCall(updatedCall);

      expect(result, isNotNull);
      expect(result!.scheduledCall.priority, CallPriority.hot);
    });

    test('changing requested date should trigger rescheduling', () async {
      final newRequestedTime = DateTime.utc(2026, 11, 6, 11, 0);

      final updatedCall = createTestCall(
        requestedAt: newRequestedTime,
        scheduledAt: newRequestedTime,
      );

      final result = await provider.editCall(updatedCall);

      expect(result, isNotNull);
      expect(result!.scheduledCall.scheduledAt, newRequestedTime);
    });

    test('updated call should be saved using schedule diff', () async {
      final updatedCall = createTestCall(leadName: 'Updated John');

      await provider.editCall(updatedCall);

      verify(
        () => repository.applyScheduleDiff(
          diff: any(named: 'diff'),
          blockedDateKeysToAdd: any(named: 'blockedDateKeysToAdd'),
          blockedDateKeysToRemove: any(named: 'blockedDateKeysToRemove'),
        ),
      ).called(1);
    });
      group('FollowUpProvider unblockDay', () {
    final blockedDate = DateTime.utc(2026, 11, 6);
    const blockedDateKey = '2026-11-06';

    setUp(() async {
      when(
        () => repository.getBlockedDates(),
      ).thenAnswer((_) async => {blockedDateKey});

      await provider.loadSchedule();
    });

    test('unblockDay should remove the blocked date', () async {
      final result = await provider.unblockDay(blockedDate);

      expect(result, true);
      expect(provider.blockedDateKeys.contains(blockedDateKey), false);

      verify(
        () => repository.applyScheduleDiff(
          diff: any(named: 'diff'),
          blockedDateKeysToAdd: any(named: 'blockedDateKeysToAdd'),
          blockedDateKeysToRemove: {blockedDateKey},
        ),
      ).called(1);
    });

    test('undo should restore the unblocked date', () async {
      await provider.unblockDay(blockedDate);

      final undoResult = await provider.undo();

      expect(undoResult, true);
      expect(provider.blockedDateKeys.contains(blockedDateKey), true);

      verify(
        () => repository.replaceSchedule(
          calls: any(named: 'calls'),
          blockedDateKeys: {blockedDateKey},
        ),
      ).called(1);
    });
  });

  group('FollowUpProvider deleteCall', () {
  setUp(() async {
    await provider.loadSchedule();
  });

  test('deleteCall should remove the selected call', () async {
    final result = await provider.deleteCall('call-1');

    expect(result, true);
    expect(provider.calls, isEmpty);
    expect(provider.canUndo, true);
  });

  test('deleteCall should preserve state when saving fails', () async {
    when(
      () => repository.applyScheduleDiff(
        diff: any(named: 'diff'),
        blockedDateKeysToAdd: any(named: 'blockedDateKeysToAdd'),
        blockedDateKeysToRemove: any(named: 'blockedDateKeysToRemove'),
      ),
    ).thenAnswer((_) async {
      throw Exception('Database failure');
    });

    final result = await provider.deleteCall('call-1');

    expect(result, false);
    expect(provider.calls.length, 1);
    expect(provider.calls.first.id, 'call-1');
    expect(provider.errorMessage, isNotNull);
  });
});

group('FollowUpProvider blockDay', () {
  setUp(() async {
    when(() => repository.getAllCalls()).thenAnswer(
      (_) async => [
        createTestCall(
          requestedAt: DateTime.utc(2026, 11, 10, 10, 0),
          scheduledAt: DateTime.utc(2026, 11, 10, 10, 0),
        ),
      ],
    );

    await provider.loadSchedule();
  });

  test('blockDay should block the selected date', () async {
    final blockedDate = DateTime.utc(2026, 11, 10);

    final result = await provider.blockDay(blockedDate);

    expect(result, isNotNull);
    expect(
      provider.blockedDateKeys.contains('2026-11-10'),
      true,
    );

    expect(
      provider.calls.every(
        (call) =>
            call.scheduledAt.year != 2026 ||
            call.scheduledAt.month != 11 ||
            call.scheduledAt.day != 10,
      ),
      true,
    );
  });

  test('blockDay should preserve state when saving fails', () async {
    when(
      () => repository.applyScheduleDiff(
        diff: any(named: 'diff'),
        blockedDateKeysToAdd: any(named: 'blockedDateKeysToAdd'),
        blockedDateKeysToRemove: any(named: 'blockedDateKeysToRemove'),
      ),
    ).thenAnswer((_) async {
      throw Exception('Database failure');
    });

    final result = await provider.blockDay(
      DateTime.utc(2026, 11, 10),
    );

    expect(result, isNull);
    expect(provider.blockedDateKeys, isEmpty);
    expect(provider.calls.length, 1);
    expect(
      provider.calls.first.scheduledAt,
      DateTime.utc(2026, 11, 10, 10, 0),
    );
    expect(provider.errorMessage, isNotNull);
  });
});
  group('FollowUpProvider addCall', () {
  setUp(() async {
    await provider.loadSchedule();
  });

  test('addCall should save and update provider state', () async {
    final newCall = createTestCall(
      id: 'new-call',
      leadName: 'New Lead',
      phoneNumber: '9876543211',
      requestedAt: DateTime.utc(2026, 11, 10, 10, 0),
      scheduledAt: DateTime.utc(2026, 11, 10, 10, 0),
    );

    final result = await provider.addCall(newCall);

    expect(result, isNotNull);
    expect(provider.calls.length, 2);
    expect(
      provider.calls.any((call) => call.id == 'new-call'),
      true,
    );

    verify(
      () => repository.applyScheduleDiff(
        diff: any(named: 'diff'),
        blockedDateKeysToAdd: any(named: 'blockedDateKeysToAdd'),
        blockedDateKeysToRemove: any(named: 'blockedDateKeysToRemove'),
      ),
    ).called(1);
  });
});
  });
  group('FollowUpProvider undo and redo', () {
  setUp(() async {
    await provider.loadSchedule();
  });

  test('undo and redo should restore a deleted call', () async {
    // Delete the call.
    final deleted = await provider.deleteCall('call-1');

    expect(deleted, true);
    expect(provider.calls, isEmpty);

    // Undo should restore the call.
    final undone = await provider.undo();

    expect(undone, true);
    expect(provider.calls.length, 1);
    expect(provider.calls.first.id, 'call-1');

    // Redo should delete the call again.
    final redone = await provider.redo();

    expect(redone, true);
    expect(provider.calls, isEmpty);
  });

  test('undo and redo should restore a blocked day', () async {
    final callTime = DateTime.utc(2026, 11, 10, 10, 0);

    when(() => repository.getAllCalls()).thenAnswer(
      (_) async => [
        createTestCall(
          requestedAt: callTime,
          scheduledAt: callTime,
        ),
      ],
    );

    await provider.loadSchedule();

    // Block November 10.
    final result = await provider.blockDay(
      DateTime.utc(2026, 11, 10),
    );

    expect(result, isNotNull);
    expect(provider.blockedDateKeys, contains('2026-11-10'));

    // Undo should restore the original schedule.
    final undone = await provider.undo();

    expect(undone, true);
    expect(provider.blockedDateKeys, isEmpty);
    expect(provider.calls.length, 1);
    expect(provider.calls.first.scheduledAt, callTime);

    // Redo should block November 10 again.
    final redone = await provider.redo();

    expect(redone, true);
    expect(provider.blockedDateKeys, contains('2026-11-10'));
    expect(
      provider.calls.every(
        (call) => call.scheduledAt.day != 10 ||
            call.scheduledAt.month != 11,
      ),
      true,
    );
  });
});
}
