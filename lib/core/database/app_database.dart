// lib/core/database/app_database.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();
  factory AppDatabase() => _instance ??= AppDatabase._();

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFile = path.join(dbPath, 'open_dialer.db');

    return await openDatabase(
      dbFile,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE call_logs (
        id TEXT PRIMARY KEY,
        number TEXT NOT NULL,
        contact_name TEXT,
        contact_photo_uri TEXT,
        type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        is_recorded INTEGER NOT NULL DEFAULT 0,
        recording_path TEXT,
        sim_slot INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE voicemails (
        id TEXT PRIMARY KEY,
        number TEXT NOT NULL,
        contact_name TEXT,
        timestamp INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        is_read INTEGER NOT NULL DEFAULT 0,
        audio_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recordings (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        number TEXT NOT NULL,
        contact_name TEXT,
        timestamp INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        file_size_bytes INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE blocked_numbers (
        id TEXT PRIMARY KEY,
        number TEXT NOT NULL UNIQUE,
        label TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_call_logs_timestamp ON call_logs(timestamp DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_call_logs_number ON call_logs(number)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic per version bump
  }

  // ── Call Logs ─────────────────────────────────────────
  Future<void> insertCallLog(CallLogModel log) async {
    final db = await database;
    await db.insert('call_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CallLogModel>> getCallLogs({int limit = 100, int offset = 0}) async {
    final db = await database;
    final rows = await db.query(
      'call_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(CallLogModel.fromMap).toList();
  }

  Future<List<CallLogModel>> getCallLogsByNumber(String number) async {
    final db = await database;
    final rows = await db.query(
      'call_logs',
      where: 'number = ?',
      whereArgs: [number],
      orderBy: 'timestamp DESC',
    );
    return rows.map(CallLogModel.fromMap).toList();
  }

  Future<int> getMissedCallCount() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM call_logs WHERE type = 'missed'");
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<void> deleteCallLog(String id) async {
    final db = await database;
    await db.delete('call_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllCallLogs() async {
    final db = await database;
    await db.delete('call_logs');
  }

  // ── Voicemails ────────────────────────────────────────
  Future<void> insertVoicemail(VoicemailModel vm) async {
    final db = await database;
    await db.insert('voicemails', {
      'id': vm.id,
      'number': vm.number,
      'contact_name': vm.contactName,
      'timestamp': vm.timestamp.millisecondsSinceEpoch,
      'duration_seconds': vm.durationSeconds,
      'is_read': vm.isRead ? 1 : 0,
      'audio_path': vm.audioPath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<VoicemailModel>> getVoicemails() async {
    final db = await database;
    final rows = await db.query('voicemails', orderBy: 'timestamp DESC');
    return rows.map((m) => VoicemailModel(
      id: m['id'] as String,
      number: m['number'] as String,
      contactName: m['contact_name'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
      durationSeconds: m['duration_seconds'] as int,
      isRead: (m['is_read'] as int) == 1,
      audioPath: m['audio_path'] as String?,
    )).toList();
  }

  Future<void> markVoicemailRead(String id) async {
    final db = await database;
    await db.update('voicemails', {'is_read': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteVoicemail(String id) async {
    final db = await database;
    await db.delete('voicemails', where: 'id = ?', whereArgs: [id]);
  }

  // ── Recordings ────────────────────────────────────────
  Future<void> insertRecording(RecordingModel rec) async {
    final db = await database;
    await db.insert('recordings', {
      'id': rec.id,
      'file_path': rec.filePath,
      'number': rec.number,
      'contact_name': rec.contactName,
      'timestamp': rec.timestamp.millisecondsSinceEpoch,
      'duration_seconds': rec.durationSeconds,
      'file_size_bytes': rec.fileSizeBytes,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<RecordingModel>> getRecordings() async {
    final db = await database;
    final rows = await db.query('recordings', orderBy: 'timestamp DESC');
    return rows.map((m) => RecordingModel(
      id: m['id'] as String,
      filePath: m['file_path'] as String,
      number: m['number'] as String,
      contactName: m['contact_name'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
      durationSeconds: m['duration_seconds'] as int,
      fileSizeBytes: m['file_size_bytes'] as int,
    )).toList();
  }

  Future<void> deleteRecording(String id) async {
    final db = await database;
    await db.delete('recordings', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) await db.close();
    _db = null;
  }
}
