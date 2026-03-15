// lib/core/services/spam_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

/// SpamService — lightweight local spam detection.
///
/// Strategy:
///   1. Check against user's manually blocked list (DB).
///   2. Heuristic rules: premium-rate prefixes, known scam patterns.
///   3. (Future) Optional cloud lookup via open spam databases.
class SpamService {
  final AppDatabase _db;

  SpamService(this._db);

  // ── Manual block list ────────────────────────────────────────────────────

  Future<void> blockNumber(String number, {String? label}) async {
    final db = await _db.database;
    await db.insert('blocked_numbers', {
      'id': _uuid(),
      'number': _normalize(number),
      'label': label,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: _ConflictAlgorithm.replace);
  }

  Future<void> unblockNumber(String number) async {
    final db = await _db.database;
    await db.delete('blocked_numbers',
        where: 'number = ?', whereArgs: [_normalize(number)]);
  }

  Future<List<BlockedNumber>> getBlockedNumbers() async {
    final db = await _db.database;
    final rows = await db.query('blocked_numbers', orderBy: 'created_at DESC');
    return rows
        .map((r) => BlockedNumber(
              id: r['id'] as String,
              number: r['number'] as String,
              label: r['label'] as String?,
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                  r['created_at'] as int),
            ))
        .toList();
  }

  Future<bool> isBlocked(String number) async {
    final db = await _db.database;
    final rows = await db.query('blocked_numbers',
        where: 'number = ?', whereArgs: [_normalize(number)], limit: 1);
    return rows.isNotEmpty;
  }

  // ── Spam heuristics ──────────────────────────────────────────────────────

  /// Returns a [SpamResult] for a given number.
  Future<SpamResult> check(String number) async {
    final n = _normalize(number);

    // 1. Check user block list
    if (await isBlocked(n)) {
      return SpamResult(isSpam: true, reason: SpamReason.userBlocked);
    }

    // 2. Heuristic patterns
    if (_isPremiumRate(n)) {
      return SpamResult(isSpam: true, reason: SpamReason.premiumRate);
    }
    if (_isKnownSpamPrefix(n)) {
      return SpamResult(isSpam: true, reason: SpamReason.suspectedSpam);
    }

    return SpamResult(isSpam: false, reason: SpamReason.clean);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _normalize(String number) =>
      number.replaceAll(RegExp(r'[^\d+]'), '');

  static bool _isPremiumRate(String n) {
    // US premium-rate: 1-900-xxx-xxxx
    return n.startsWith('1900') || n.startsWith('900');
  }

  static bool _isKnownSpamPrefix(String n) {
    // Example heuristic — short international numbers often used for SMS fraud
    if (n.length < 6) return true;
    // Repeated digit patterns
    if (RegExp(r'^(\d)\1{5,}$').hasMatch(n)) return true;
    return false;
  }

  static String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return now.toRadixString(16).padLeft(16, '0');
  }
}

// ignore: non_constant_identifier_names
final _ConflictAlgorithm = _CA();
class _CA {
  int get replace => 5; // sqflite ConflictAlgorithm.replace value
}

// ── Data classes ──────────────────────────────────────────────────────────────

enum SpamReason { clean, userBlocked, premiumRate, suspectedSpam }

class SpamResult {
  final bool isSpam;
  final SpamReason reason;
  const SpamResult({required this.isSpam, required this.reason});
}

class BlockedNumber {
  final String id;
  final String number;
  final String? label;
  final DateTime createdAt;
  const BlockedNumber(
      {required this.id,
      required this.number,
      this.label,
      required this.createdAt});
}

// ── Provider ──────────────────────────────────────────────────────────────────

final spamServiceProvider = Provider<SpamService>((ref) {
  return SpamService(AppDatabase());
});

final blockedNumbersProvider = FutureProvider<List<BlockedNumber>>((ref) {
  return ref.watch(spamServiceProvider).getBlockedNumbers();
});
