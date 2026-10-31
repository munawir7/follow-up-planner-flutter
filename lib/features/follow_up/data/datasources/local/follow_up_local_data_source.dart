import 'package:sqflite/sqflite.dart';

import '../../models/follow_up_call_model.dart';
import 'app_database.dart';

class FollowUpLocalDataSource {
  final AppDatabase _appDatabase;

  FollowUpLocalDataSource({required AppDatabase appDatabase})
    : _appDatabase = appDatabase;

  Future<List<FollowUpCallModel>> getAllCalls() async {
    final db = await _appDatabase.database;

    final result = await db.query(
      AppDatabase.callsTable,
      orderBy: 'scheduled_at ASC',
    );

    return result.map((row) => FollowUpCallModel.fromMap(row)).toList();
  }

  Future<void> insertCall(FollowUpCallModel call) async {
    final db = await _appDatabase.database;

    await db.insert(
      AppDatabase.callsTable,
      call.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertCalls(List<FollowUpCallModel> calls) async {
    final db = await _appDatabase.database;

    await db.transaction((transaction) async {
      final batch = transaction.batch();

      for (final call in calls) {
        batch.insert(
          AppDatabase.callsTable,
          call.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> updateCall(FollowUpCallModel call) async {
    final db = await _appDatabase.database;

    await db.update(
      AppDatabase.callsTable,
      call.toMap(),
      where: 'id = ?',
      whereArgs: [call.id],
    );
  }

  Future<void> deleteCall(String id) async {
    final db = await _appDatabase.database;

    await db.delete(AppDatabase.callsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAllCalls(List<FollowUpCallModel> calls) async {
    final db = await _appDatabase.database;

    await db.transaction((transaction) async {
      await transaction.delete(AppDatabase.callsTable);

      final batch = transaction.batch();

      for (final call in calls) {
        batch.insert(
          AppDatabase.callsTable,
          call.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  Future<List<String>> getBlockedDates() async {
    final db = await _appDatabase.database;

    final result = await db.query(
      AppDatabase.blockedDaysTable,
      columns: ['date_key'],
      orderBy: 'date_key ASC',
    );

    return result.map((row) => row['date_key'] as String).toList();
  }

  Future<void> blockDate(String dateKey) async {
    final db = await _appDatabase.database;

    await db.insert(AppDatabase.blockedDaysTable, {
      'date_key': dateKey,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> unblockDate(String dateKey) async {
    final db = await _appDatabase.database;

    await db.delete(
      AppDatabase.blockedDaysTable,
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
  }

  Future<void> replaceBlockedDates(List<String> dateKeys) async {
    final db = await _appDatabase.database;

    await db.transaction((transaction) async {
      await transaction.delete(AppDatabase.blockedDaysTable);

      final batch = transaction.batch();

      for (final dateKey in dateKeys) {
        batch.insert(
          AppDatabase.blockedDaysTable,
          {'date_key': dateKey},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> replaceSchedule({
    required List<FollowUpCallModel> calls,
    required Set<String> blockedDateKeys,
  }) async {
    final db = await _appDatabase.database;

    await db.transaction((transaction) async {
      // Replace all calls.
      await transaction.delete(AppDatabase.callsTable);

      final callsBatch = transaction.batch();

      for (final call in calls) {
        callsBatch.insert(
          AppDatabase.callsTable,
          call.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await callsBatch.commit(noResult: true);

      // Replace all manually blocked dates.
      await transaction.delete(AppDatabase.blockedDaysTable);

      final blockedDaysBatch = transaction.batch();

      for (final dateKey in blockedDateKeys) {
        blockedDaysBatch.insert(
          AppDatabase.blockedDaysTable,
          {'date_key': dateKey},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      await blockedDaysBatch.commit(noResult: true);
    });
  }
}
