import 'package:sqflite/sqflite.dart';

import '../../models/follow_up_call_model.dart';
import 'app_database.dart';

class FollowUpLocalDataSource {
  final AppDatabase _appDatabase;

  FollowUpLocalDataSource({required AppDatabase appDatabase})
    : _appDatabase = appDatabase;

  // Fetch all calls.
  Future<List<FollowUpCallModel>> getAllCalls() async {
    final db = await _appDatabase.database;

    final result = await db.query(
      AppDatabase.callsTable,
      orderBy: 'scheduled_at ASC',
    );

    return result.map((row) => FollowUpCallModel.fromMap(row)).toList();
  }

  // Fetch all blocked dates.
  Future<List<String>> getBlockedDates() async {
    final db = await _appDatabase.database;

    final result = await db.query(
      AppDatabase.blockedDaysTable,
      columns: ['date_key'],
      orderBy: 'date_key ASC',
    );

    return result.map((row) => row['date_key'] as String).toList();
  }

  // Apply only changed records in one SQLite transaction.
  Future<void> applyScheduleDiff({
    required List<FollowUpCallModel> inserted,
    required List<FollowUpCallModel> updated,
    required List<String> deletedIds,
    required Set<String> blockedDateKeysToAdd,
    required Set<String> blockedDateKeysToRemove,
  }) async {
    final db = await _appDatabase.database;

    await db.transaction((transaction) async {
      final batch = transaction.batch();

      // Delete removed calls.
      for (final id in deletedIds) {
        batch.delete(AppDatabase.callsTable, where: 'id = ?', whereArgs: [id]);
      }

      // Update modified calls.
      for (final call in updated) {
        batch.update(
          AppDatabase.callsTable,
          call.toMap(),
          where: 'id = ?',
          whereArgs: [call.id],
        );
      }

      // Insert new calls.
      for (final call in inserted) {
        batch.insert(
          AppDatabase.callsTable,
          call.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      // Remove unblocked dates.
      for (final dateKey in blockedDateKeysToRemove) {
        batch.delete(
          AppDatabase.blockedDaysTable,
          where: 'date_key = ?',
          whereArgs: [dateKey],
        );
      }

      // Add newly blocked dates.
      for (final dateKey in blockedDateKeysToAdd) {
        batch.insert(
          AppDatabase.blockedDaysTable,
          {'date_key': dateKey},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  // Restore a complete schedule for undo/redo.
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
