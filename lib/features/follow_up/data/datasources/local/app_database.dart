import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'follow_up_planner.db';
  static const int _databaseVersion = 1;

  static const String callsTable = 'follow_up_calls';
  static const String blockedDaysTable = 'blocked_days';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    try {
      final databaseDirectory = await getDatabasesPath();
      final databasePath = path.join(databaseDirectory, _databaseName);

      return await openDatabase(
        databasePath,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
    } catch (error) {
      throw DatabaseException(
        'Failed to initialize the local database: $error',
      );
    }
  }

  Future<void> _onCreate(Database database, int version) async {
    await database.execute('''
CREATE TABLE $callsTable (
id TEXT PRIMARY KEY,
lead_name TEXT NOT NULL,
phone_number TEXT NOT NULL,
priority TEXT NOT NULL,
deal_value_paise INTEGER NOT NULL,
requested_at TEXT NOT NULL,
scheduled_at TEXT NOT NULL,
created_at TEXT NOT NULL
)
''');

    await database.execute('''
  CREATE TABLE $blockedDaysTable (
    date_key TEXT PRIMARY KEY
  )
''');
  }
}

class DatabaseException implements Exception {
  final String message;

  const DatabaseException(this.message);

  @override
  String toString() => message;
}
