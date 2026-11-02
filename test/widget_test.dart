import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/domain/repositories/follow_up_repository.dart';
import 'package:follow_up_planner/main.dart';

class FakeFollowUpRepository implements FollowUpRepository {
  final List<FollowUpCall> _calls = [];
  final Set<String> _blockedDates = {};

  @override
  Future<List<FollowUpCall>> getAllCalls() async {
    return _calls;
  }

  @override
  Future<void> addCall(FollowUpCall call) async {
    _calls.add(call);
  }

  @override
  Future<void> updateCall(FollowUpCall call) async {
    final index = _calls.indexWhere((item) => item.id == call.id);

    if (index != -1) {
      _calls[index] = call;
    }
  }

  @override
  Future<void> deleteCall(String id) async {
    _calls.removeWhere((call) => call.id == id);
  }

  @override
  Future<void> replaceAllCalls(List<FollowUpCall> calls) async {
    _calls
      ..clear()
      ..addAll(calls);
  }

  @override
  Future<Set<String>> getBlockedDates() async {
    return _blockedDates;
  }

  @override
  Future<void> blockDate(String dateKey) async {
    _blockedDates.add(dateKey);
  }

  @override
  Future<void> unblockDate(String dateKey) async {
    _blockedDates.remove(dateKey);
  }

  @override
  Future<void> replaceBlockedDates(Set<String> dateKeys) async {
    _blockedDates
      ..clear()
      ..addAll(dateKeys);
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
  testWidgets('Follow-Up Planner app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      FollowUpPlannerApp(repository: FakeFollowUpRepository()),
    );

    await tester.pumpAndSettle();

    expect(find.text('Follow-Up Planner'), findsOneWidget);
    expect(find.text('No calls scheduled'), findsOneWidget);
  });
}
