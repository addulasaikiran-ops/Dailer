// lib/core/models/call_log_model.dart

import 'package:equatable/equatable.dart';

enum CallType { incoming, outgoing, missed, rejected, blocked }

class CallLogModel extends Equatable {
  final String id;
  final String number;
  final String? contactName;
  final String? contactPhotoUri;
  final CallType type;
  final DateTime timestamp;
  final int durationSeconds;
  final bool isRecorded;
  final String? recordingPath;
  final int simSlot; // 0 or 1

  const CallLogModel({
    required this.id,
    required this.number,
    this.contactName,
    this.contactPhotoUri,
    required this.type,
    required this.timestamp,
    required this.durationSeconds,
    this.isRecorded = false,
    this.recordingPath,
    this.simSlot = 0,
  });

  String get displayName => contactName ?? _formatNumber(number);

  String get durationFormatted {
    if (durationSeconds == 0) return '';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  static String _formatNumber(String number) {
    // Basic formatting – real impl should use libphonenumber
    if (number.length == 10) {
      return '(${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6)}';
    }
    return number;
  }

  CallLogModel copyWith({
    String? id,
    String? number,
    String? contactName,
    String? contactPhotoUri,
    CallType? type,
    DateTime? timestamp,
    int? durationSeconds,
    bool? isRecorded,
    String? recordingPath,
    int? simSlot,
  }) {
    return CallLogModel(
      id: id ?? this.id,
      number: number ?? this.number,
      contactName: contactName ?? this.contactName,
      contactPhotoUri: contactPhotoUri ?? this.contactPhotoUri,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isRecorded: isRecorded ?? this.isRecorded,
      recordingPath: recordingPath ?? this.recordingPath,
      simSlot: simSlot ?? this.simSlot,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'contact_name': contactName,
      'contact_photo_uri': contactPhotoUri,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'is_recorded': isRecorded ? 1 : 0,
      'recording_path': recordingPath,
      'sim_slot': simSlot,
    };
  }

  factory CallLogModel.fromMap(Map<String, dynamic> map) {
    return CallLogModel(
      id: map['id'] as String,
      number: map['number'] as String,
      contactName: map['contact_name'] as String?,
      contactPhotoUri: map['contact_photo_uri'] as String?,
      type: CallType.values.firstWhere((e) => e.name == map['type'],
          orElse: () => CallType.incoming),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      durationSeconds: map['duration_seconds'] as int,
      isRecorded: (map['is_recorded'] as int) == 1,
      recordingPath: map['recording_path'] as String?,
      simSlot: map['sim_slot'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, number, type, timestamp];
}

// lib/core/models/contact_model.dart (inline for brevity)
class ContactModel extends Equatable {
  final String id;
  final String displayName;
  final List<String> phones;
  final String? photoUri;
  final bool isFavorite;

  const ContactModel({
    required this.id,
    required this.displayName,
    required this.phones,
    this.photoUri,
    this.isFavorite = false,
  });

  String get primaryPhone => phones.isNotEmpty ? phones.first : '';
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (displayName.isNotEmpty) return displayName[0].toUpperCase();
    return '?';
  }

  ContactModel copyWith({bool? isFavorite}) => ContactModel(
        id: id,
        displayName: displayName,
        phones: phones,
        photoUri: photoUri,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  @override
  List<Object?> get props => [id, displayName, phones, isFavorite];
}

// lib/core/models/voicemail_model.dart
class VoicemailModel extends Equatable {
  final String id;
  final String number;
  final String? contactName;
  final DateTime timestamp;
  final int durationSeconds;
  final bool isRead;
  final String? audioPath;

  const VoicemailModel({
    required this.id,
    required this.number,
    this.contactName,
    required this.timestamp,
    required this.durationSeconds,
    this.isRead = false,
    this.audioPath,
  });

  String get displayName => contactName ?? number;

  @override
  List<Object?> get props => [id, number, timestamp, isRead];
}

// lib/core/models/recording_model.dart
class RecordingModel extends Equatable {
  final String id;
  final String filePath;
  final String number;
  final String? contactName;
  final DateTime timestamp;
  final int durationSeconds;
  final int fileSizeBytes;

  const RecordingModel({
    required this.id,
    required this.filePath,
    required this.number,
    this.contactName,
    required this.timestamp,
    required this.durationSeconds,
    required this.fileSizeBytes,
  });

  String get displayName => contactName ?? number;
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(fileSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB';
  }

  @override
  List<Object?> get props => [id, filePath, timestamp];
}
