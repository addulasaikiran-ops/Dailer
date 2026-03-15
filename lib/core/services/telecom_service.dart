// lib/core/services/telecom_service.dart

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flutter-side wrapper around the Android Telecom MethodChannel.
/// All call actions should go through this service.
class TelecomService {
  static const _channel = MethodChannel('com.opendialer/telecom');
  static const _events = EventChannel('com.opendialer/call_events');

  // ── Call control ──────────────────────────────────────────────────────────

  Future<void> makeCall(String number, {int simSlot = 0}) async {
    await _channel.invokeMethod('makeCall', {
      'number': number,
      'simSlot': simSlot,
    });
  }

  Future<void> answerCall() async {
    await _channel.invokeMethod('answerCall');
  }

  Future<void> rejectCall() async {
    await _channel.invokeMethod('rejectCall');
  }

  Future<void> hangUp() async {
    await _channel.invokeMethod('hangUp');
  }

  Future<void> holdCall() async {
    await _channel.invokeMethod('holdCall');
  }

  Future<void> unholdCall() async {
    await _channel.invokeMethod('unholdCall');
  }

  Future<void> setMuted(bool muted) async {
    await _channel.invokeMethod('setMuted', {'muted': muted});
  }

  Future<void> setSpeaker(bool on) async {
    await _channel.invokeMethod('setSpeaker', {'on': on});
  }

  // ── Default dialer ────────────────────────────────────────────────────────

  Future<void> requestDefaultDialer() async {
    await _channel.invokeMethod('requestDefaultDialer');
  }

  Future<bool> isDefaultDialer() async {
    return await _channel.invokeMethod<bool>('isDefaultDialer') ?? false;
  }

  // ── Event stream ──────────────────────────────────────────────────────────

  Stream<CallEvent> get callEvents {
    return _events
        .receiveBroadcastStream()
        .map((data) => CallEvent.fromMap(Map<String, dynamic>.from(data)));
  }
}

// ─── CallEvent model ──────────────────────────────────────────────────────────

enum CallEventType {
  incoming,
  answered,
  rejected,
  ended,
  held,
  resumed,
  audioState,
  failed,
}

class CallEvent {
  final CallEventType type;
  final bool? isMuted;
  final bool? isSpeaker;
  final String? number;

  const CallEvent({
    required this.type,
    this.isMuted,
    this.isSpeaker,
    this.number,
  });

  factory CallEvent.fromMap(Map<String, dynamic> map) {
    final eventStr = map['event'] as String? ?? '';
    final type = switch (eventStr) {
      'incoming' => CallEventType.incoming,
      'answered' => CallEventType.answered,
      'rejected' => CallEventType.rejected,
      'ended' => CallEventType.ended,
      'held' => CallEventType.held,
      'resumed' => CallEventType.resumed,
      'audioState' => CallEventType.audioState,
      _ => CallEventType.failed,
    };
    return CallEvent(
      type: type,
      isMuted: map['isMuted'] as bool?,
      isSpeaker: map['isSpeaker'] as bool?,
      number: map['number'] as String?,
    );
  }
}

// ─── Riverpod providers ───────────────────────────────────────────────────────

final telecomServiceProvider = Provider<TelecomService>((ref) {
  return TelecomService();
});

final callEventsProvider = StreamProvider<CallEvent>((ref) {
  return ref.watch(telecomServiceProvider).callEvents;
});
