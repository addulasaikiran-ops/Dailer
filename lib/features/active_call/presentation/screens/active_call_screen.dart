// lib/features/active_call/presentation/screens/active_call_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/contact_avatar.dart';

// ─── State ─────────────────────────────────────────────────────────────────────

class ActiveCallState {
  final bool isMuted;
  final bool isSpeaker;
  final bool isOnHold;
  final bool isRecording;
  final bool isKeypadShowing;
  final int elapsedSeconds;

  const ActiveCallState({
    this.isMuted = false,
    this.isSpeaker = false,
    this.isOnHold = false,
    this.isRecording = false,
    this.isKeypadShowing = false,
    this.elapsedSeconds = 0,
  });

  ActiveCallState copyWith({
    bool? isMuted,
    bool? isSpeaker,
    bool? isOnHold,
    bool? isRecording,
    bool? isKeypadShowing,
    int? elapsedSeconds,
  }) {
    return ActiveCallState(
      isMuted: isMuted ?? this.isMuted,
      isSpeaker: isSpeaker ?? this.isSpeaker,
      isOnHold: isOnHold ?? this.isOnHold,
      isRecording: isRecording ?? this.isRecording,
      isKeypadShowing: isKeypadShowing ?? this.isKeypadShowing,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  String get timerLabel {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class ActiveCallNotifier extends StateNotifier<ActiveCallState> {
  Timer? _timer;

  ActiveCallNotifier() : super(const ActiveCallState()) {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
    HapticFeedback.selectionClick();
  }

  void toggleSpeaker() {
    state = state.copyWith(isSpeaker: !state.isSpeaker);
    HapticFeedback.selectionClick();
  }

  void toggleHold() {
    state = state.copyWith(isOnHold: !state.isOnHold);
    if (state.isOnHold) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
    HapticFeedback.selectionClick();
  }

  void toggleRecording() {
    state = state.copyWith(isRecording: !state.isRecording);
    HapticFeedback.mediumImpact();
  }

  void toggleKeypad() {
    state = state.copyWith(isKeypadShowing: !state.isKeypadShowing);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final activeCallProvider =
    StateNotifierProvider<ActiveCallNotifier, ActiveCallState>((ref) {
  return ActiveCallNotifier();
});

// ─── Screen ────────────────────────────────────────────────────────────────────

class ActiveCallScreen extends ConsumerWidget {
  const ActiveCallScreen({super.key});

  static const _callerName = 'Sarah Johnson';
  static const _callerNumber = '+1 (555) 234-7890';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeCallProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: state.isOnHold
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFF0D1F3C), const Color(0xFF091A32)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── Caller Info ────────────────────────────────────────
              _CallerInfo(
                name: _callerName,
                number: _callerNumber,
                timerLabel: state.timerLabel,
                isOnHold: state.isOnHold,
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 40),

              // ── Recording Indicator (subtle) ────────────────────
              if (state.isRecording)
                _RecordingBadge()
                    .animate()
                    .fadeIn()
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .custom(
                      duration: 1200.ms,
                      builder: (_, value, child) =>
                          Opacity(opacity: 0.6 + 0.4 * value, child: child),
                    ),

              const Spacer(),

              // ── In-call Keypad ─────────────────────────────────────
              if (state.isKeypadShowing) ...[
                _InCallKeypad().animate().slideY(begin: 0.3, end: 0),
                const SizedBox(height: 24),
              ],

              // ── Action Buttons ─────────────────────────────────────
              _ActionGrid(
                state: state,
                onMute: () => ref.read(activeCallProvider.notifier).toggleMute(),
                onSpeaker: () =>
                    ref.read(activeCallProvider.notifier).toggleSpeaker(),
                onHold: () =>
                    ref.read(activeCallProvider.notifier).toggleHold(),
                onRecord: () =>
                    ref.read(activeCallProvider.notifier).toggleRecording(),
                onKeypad: () =>
                    ref.read(activeCallProvider.notifier).toggleKeypad(),
                onAdd: () {},
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),

              // ── End Call ──────────────────────────────────────────
              _EndCallButton(
                onEnd: () => Navigator.pop(context),
              ).animate().slideY(
                    begin: 0.5,
                    end: 0,
                    delay: 300.ms,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Caller Info ──────────────────────────────────────────────────────────────

class _CallerInfo extends StatelessWidget {
  final String name;
  final String number;
  final String timerLabel;
  final bool isOnHold;

  const _CallerInfo({
    required this.name,
    required this.number,
    required this.timerLabel,
    required this.isOnHold,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ContactAvatar(name: name, size: 100, showRing: true),
        const SizedBox(height: 20),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          number,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isOnHold
                ? Colors.orange.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isOnHold ? 'On Hold' : timerLabel,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isOnHold ? Colors.orange : AppColors.primaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Recording Badge ──────────────────────────────────────────────────────────

class _RecordingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.callRed.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.callRed.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, color: AppColors.callRed, size: 10),
          SizedBox(width: 6),
          Text(
            'Recording',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.callRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Grid ──────────────────────────────────────────────────────────────

class _ActionGrid extends StatelessWidget {
  final ActiveCallState state;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onHold;
  final VoidCallback onRecord;
  final VoidCallback onKeypad;
  final VoidCallback onAdd;

  const _ActionGrid({
    required this.state,
    required this.onMute,
    required this.onSpeaker,
    required this.onHold,
    required this.onRecord,
    required this.onKeypad,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionBtn(
                icon: state.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: state.isMuted ? 'Unmute' : 'Mute',
                active: state.isMuted,
                onTap: onMute,
              ),
              _ActionBtn(
                icon: state.isSpeaker
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded,
                label: 'Speaker',
                active: state.isSpeaker,
                onTap: onSpeaker,
              ),
              _ActionBtn(
                icon: Icons.dialpad_rounded,
                label: 'Keypad',
                active: state.isKeypadShowing,
                onTap: onKeypad,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionBtn(
                icon: state.isOnHold
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                label: state.isOnHold ? 'Resume' : 'Hold',
                active: state.isOnHold,
                onTap: onHold,
              ),
              _ActionBtn(
                icon: Icons.fiber_manual_record_rounded,
                label: state.isRecording ? 'Stop Rec' : 'Record',
                active: state.isRecording,
                activeColor: AppColors.callRed,
                onTap: onRecord,
              ),
              _ActionBtn(
                icon: Icons.person_add_outlined,
                label: 'Add call',
                onTap: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.active = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlightColor = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: active
                    ? highlightColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: active
                    ? Border.all(color: highlightColor.withOpacity(0.5))
                    : null,
              ),
              child: Icon(
                icon,
                color: active ? highlightColor : Colors.white70,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                color: active ? highlightColor : Colors.white60,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── End Call Button ──────────────────────────────────────────────────────────

class _EndCallButton extends StatelessWidget {
  final VoidCallback onEnd;
  const _EndCallButton({required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEnd,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4D6D), Color(0xFFD62B4B)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D6D).withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

// ─── In-call Keypad ───────────────────────────────────────────────────────────

class _InCallKeypad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: rows
            .map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: row
                        .map((k) => _MiniKey(label: k))
                        .toList(),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MiniKey extends StatelessWidget {
  final String label;
  const _MiniKey({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        width: 56,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
