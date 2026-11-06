import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/data/models/follow_up_call_model.dart';

void main() {
  group('FollowUpCallModel IST timestamp tests', () {
    final requestedAt = DateTime.utc(2026, 11, 3, 9, 30);
    final scheduledAt = DateTime.utc(2026, 11, 3, 10, 0);
    final createdAt = DateTime.utc(2026, 11, 3, 8, 0);

    final call = FollowUpCallModel(
      id: 'test-001',
      leadName: 'Test Lead',
      phoneNumber: '9876543210',
      priority: CallPriority.hot,
      dealValuePaise: 100000,
      requestedAt: requestedAt,
      scheduledAt: scheduledAt,
      createdAt: createdAt,
    );

    test('Should store IST timestamps without Z suffix', () {
      final map = call.toMap();

      expect(map['requested_at'], '2026-11-03T09:30:00.000');

      expect(map['scheduled_at'], '2026-11-03T10:00:00.000');

      expect(map['created_at'], '2026-11-03T08:00:00.000');
    });

    test('Should restore the same IST wall-clock time', () {
      final map = call.toMap();

      final restoredCall = FollowUpCallModel.fromMap(map);

      expect(restoredCall.requestedAt.hour, 9);
      expect(restoredCall.requestedAt.minute, 30);

      expect(restoredCall.scheduledAt.hour, 10);
      expect(restoredCall.scheduledAt.minute, 0);

      expect(restoredCall.createdAt.hour, 8);
      expect(restoredCall.createdAt.minute, 0);
    });

    test('Should preserve wall-clock time from existing Z timestamps', () {
      final map = call.toMap();

      map['requested_at'] = '2026-11-03T09:30:00.000Z';
      map['scheduled_at'] = '2026-11-03T10:00:00.000Z';
      map['created_at'] = '2026-11-03T08:00:00.000Z';

      final restoredCall = FollowUpCallModel.fromMap(map);

      expect(restoredCall.requestedAt.hour, 9);
      expect(restoredCall.requestedAt.minute, 30);

      expect(restoredCall.scheduledAt.hour, 10);
      expect(restoredCall.scheduledAt.minute, 0);

      expect(restoredCall.createdAt.hour, 8);
      expect(restoredCall.createdAt.minute, 0);
    });
  });
}
