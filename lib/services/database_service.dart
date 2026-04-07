import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/models/alarm_model.dart';
import '../data/models/recording_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'voice_alarm.db');
    return await openDatabase(
      path,
      version: 2, // Upgraded version for recordings library
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Alarms table
    await db.execute('''
      CREATE TABLE alarms (
        id TEXT PRIMARY KEY,
        title TEXT,
        dateTime TEXT,
        audioPath TEXT,
        isActive INTEGER,
        isOneTime INTEGER
      )
    ''');

    // Recordings Library table
    await db.execute('''
      CREATE TABLE recordings (
        id TEXT PRIMARY KEY,
        name TEXT,
        path TEXT,
        dateTime TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE recordings (
          id TEXT PRIMARY KEY,
          name TEXT,
          path TEXT,
          dateTime TEXT
        )
      ''');
    }
  }

  // --- Alarms CRUD ---
  Future<void> insertAlarm(Alarm alarm) async {
    final db = await database;
    await db.insert(
      'alarms',
      alarm.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Alarm>> getAlarms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('alarms');
    return List.generate(maps.length, (i) {
      return Alarm.fromMap(maps[i]);
    });
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final db = await database;
    await db.update(
      'alarms',
      alarm.toMap(),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  Future<void> deleteAlarm(String id) async {
    final db = await database;
    await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Recordings Library CRUD ---
  Future<void> insertRecording(Recording recording) async {
    final db = await database;
    await db.insert(
      'recordings',
      recording.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Recording>> getRecordings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('recordings', orderBy: 'dateTime DESC');
    return List.generate(maps.length, (i) {
      return Recording.fromMap(maps[i]);
    });
  }

  Future<void> deleteRecording(String id) async {
    final db = await database;
    await db.delete(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
