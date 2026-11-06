import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:follow_up_planner/features/follow_up/presentation/providers/follow_up_provider.dart';
import 'package:follow_up_planner/features/follow_up/presentation/screens/add_call_screen.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/domain/repositories/follow_up_repository.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/schedule_diff.dart';
import 'package:follow_up_planner/main.dart';

class FakeFollowUpRepository implements FollowUpRepository {
  final List<FollowUpCall> _calls = [];
  final Set<String> _blockedDates = {};

  @override
  Future<List<FollowUpCall>> getAllCalls() async {
    return List.from(_calls);
  }

  @override
  Future<Set<String>> getBlockedDates() async {
    return Set.from(_blockedDates);
  }

  @override
  Future<void> applyScheduleDiff({
    required ScheduleDiff diff,
    required Set<String> blockedDateKeysToAdd,
    required Set<String> blockedDateKeysToRemove,
  }) async {
    _calls.removeWhere((call) => diff.deletedIds.contains(call.id));

    for (final call in diff.updated) {
      final index = _calls.indexWhere((item) => item.id == call.id);

      if (index != -1) {
        _calls[index] = call;
      }
    }

    _calls.addAll(diff.inserted);

    _blockedDates
      ..removeAll(blockedDateKeysToRemove)
      ..addAll(blockedDateKeysToAdd);
  }

  @override
  Future<void> replaceSchedule({
    required List<FollowUpCall> calls,
    required Set<String> blockedDateKeys,
  }) async {
    _calls
      ..clear()
      ..addAll(calls);

    _blockedDates
      ..clear()
      ..addAll(blockedDateKeys);
  }
}

void main() {

    testWidgets('Add Call screen should save a new follow-up call',
    (WidgetTester tester) async {
  final repository = FakeFollowUpRepository();

  final provider = FollowUpProvider(
    repository: repository,
    nowProvider: () => DateTime.utc(2026, 11, 6, 9, 0),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddCallScreen(
                        initialDateTime: DateTime.utc(
                          2026, 11, 10, 10, 0,
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open Add Call'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open Add Call'));
  await tester.pumpAndSettle();

  expect(find.text('Add Follow-Up Call'), findsOneWidget);

  final textFields = find.byType(TextFormField);

  await tester.enterText(textFields.at(0), 'Test Lead');
  await tester.enterText(textFields.at(1), '9876543210');
  await tester.enterText(textFields.at(2), '5000');

  await tester.ensureVisible(find.text('Save Follow-Up'));
  await tester.tap(find.text('Save Follow-Up'));

  await tester.pumpAndSettle();

  final savedCalls = await repository.getAllCalls();

  expect(savedCalls.length, 1);
  expect(savedCalls.first.leadName, 'Test Lead');
  expect(savedCalls.first.phoneNumber, '9876543210');
  expect(savedCalls.first.dealValuePaise, 500000);

  expect(find.text('Open Add Call'), findsOneWidget);
});
   testWidgets('Follow-Up Planner app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      FollowUpPlannerApp(repository: FakeFollowUpRepository()),
    );

    await tester.pumpAndSettle();

    expect(find.text('Follow-Up Planner'), findsOneWidget);
    expect(find.text('No calls scheduled'), findsOneWidget);
  });
}
