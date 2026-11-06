import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:follow_up_planner/features/follow_up/data/datasources/local/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:follow_up_planner/features/follow_up/domain/entities/follow_up_call.dart';
import 'package:follow_up_planner/features/follow_up/data/models/follow_up_call_model.dart';

void main() {
  late Directory tempDirectory;
  late Database database;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    tempDirectory = await Directory.systemTemp.createTemp(
      'follow_up_planner_test_',
    );

    await databaseFactoryFfi.setDatabasesPath(tempDirectory.path);

    database = await AppDatabase.instance.database;
  });

  tearDownAll(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  test('SQLite should preserve IST wall-clock timestamps', () async {
    final call = FollowUpCallModel(
      id: 'sqlite-test-001',
      leadName: 'Test Lead',
      phoneNumber: '9876543210',
      priority: CallPriority.hot,
      dealValuePaise: 100000,
      requestedAt: DateTime.utc(2026, 11, 3, 9, 30),
      scheduledAt: DateTime.utc(2026, 11, 3, 10, 0),
      createdAt: DateTime.utc(2026, 11, 3, 8, 0),
    );

    await database.insert(AppDatabase.callsTable, call.toMap());

    final rows = await database.query(
      AppDatabase.callsTable,
      where: 'id = ?',
      whereArgs: ['sqlite-test-001'],
    );

    expect(rows, hasLength(1));

    final restoredCall = FollowUpCallModel.fromMap(rows.first);

    expect(restoredCall.requestedAt.hour, 9);
    expect(restoredCall.requestedAt.minute, 30);

    expect(restoredCall.scheduledAt.hour, 10);
    expect(restoredCall.scheduledAt.minute, 0);

    expect(restoredCall.createdAt.hour, 8);
    expect(restoredCall.createdAt.minute, 0);

    expect(rows.first['requested_at'], '2026-11-03T09:30:00.000');
    expect(rows.first['scheduled_at'], '2026-11-03T10:00:00.000');
    expect(rows.first['created_at'], '2026-11-03T08:00:00.000');
  });
}
