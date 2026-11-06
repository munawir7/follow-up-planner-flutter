import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'follow_up_planner.db';
  static const int _databaseVersion = 2;

  static const String callsTable = 'follow_up_calls';
  static const String blockedDaysTable = 'blocked_days';

  static const String _scheduledAtIndex = 'idx_follow_up_calls_scheduled_at';

  Future<Database>? _databaseFuture;

  Future<Database> get database {
    if (_databaseFuture != null) {
      return _databaseFuture!;
    }

    final future = _initializeDatabase().catchError((Object error) {
      _databaseFuture = null;
      throw error;
    });

    _databaseFuture = future;

    return future;
  }

  Future<Database> _initializeDatabase() async {
    try {
      final databaseDirectory = await getDatabasesPath();
      final databasePath = path.join(databaseDirectory, _databaseName);

      return await openDatabase(
        databasePath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (error) {
      throw LocalDbException('Failed to initialize the local database: $error');
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

    await _createScheduledAtIndex(database);
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createScheduledAtIndex(database);
    }
  }

  Future<void> _createScheduledAtIndex(Database database) async {
    await database.execute('''
      CREATE INDEX IF NOT EXISTS $_scheduledAtIndex
      ON $callsTable (scheduled_at)
    ''');
  }
}

class LocalDbException implements Exception {
  final String message;

  const LocalDbException(this.message);

  @override
  String toString() => message;
}
