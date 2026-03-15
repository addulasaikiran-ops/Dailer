// lib/core/services/recording_service.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/models.dart';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final AppDatabase _db;
  final _uuid = const Uuid();

  String? _currentPath;
  DateTime? _startTime;
  String? _currentNumber;
  String? _currentContactName;

  RecordingService(this._db);

  Future<bool> get isRecording => _recorder.isRecording();

  Future<String?> startRecording({
    required String number,
    String? contactName,
  }) async {
    // Check permission
    if (!await _recorder.hasPermission()) return null;

    try {
      final dir = await _recordingsDir();
      final filename =
          'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = '${dir.path}/$filename';

      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

      _currentPath = path;
      _startTime = DateTime.now();
      _currentNumber = number;
      _currentContactName = contactName;

      return path;
    } catch (e) {
      return null;
    }
  }

  Future<RecordingModel?> stopRecording() async {
    if (!await _recorder.isRecording()) return null;

    final path = await _recorder.stop();
    if (path == null || _startTime == null) return null;

    final file = File(path);
    final sizeBytes = await file.exists() ? await file.length() : 0;
    final duration =
        DateTime.now().difference(_startTime!).inSeconds;

    final recording = RecordingModel(
      id: _uuid.v4(),
      filePath: path,
      number: _currentNumber ?? '',
      contactName: _currentContactName,
      timestamp: _startTime!,
      durationSeconds: duration,
      fileSizeBytes: sizeBytes,
    );

    await _db.insertRecording(recording);

    _currentPath = null;
    _startTime = null;
    _currentNumber = null;
    _currentContactName = null;

    return recording;
  }

  Future<void> cancelRecording() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
      // Delete incomplete file
      if (_currentPath != null) {
        final file = File(_currentPath!);
        if (await file.exists()) await file.delete();
      }
    }
    _currentPath = null;
    _startTime = null;
  }

  Future<void> deleteRecording(RecordingModel recording) async {
    // Delete file
    final file = File(recording.filePath);
    if (await file.exists()) await file.delete();
    // Delete DB entry
    await _db.deleteRecording(recording.id);
  }

  Future<Directory> _recordingsDir() async {
    final base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/OpenDialer/Recordings');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  void dispose() {
    _recorder.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final db = AppDatabase();
  final service = RecordingService(db);
  ref.onDispose(service.dispose);
  return service;
});

final isRecordingProvider = StreamProvider<bool>((ref) {
  // Poll recording state every 500ms
  return Stream.periodic(const Duration(milliseconds: 500))
      .asyncMap((_) => ref.watch(recordingServiceProvider).isRecording);
});
