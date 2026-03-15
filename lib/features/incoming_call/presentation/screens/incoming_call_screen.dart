// lib/features/incoming_call/presentation/screens/incoming_call_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/contact_avatar.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  ConsumerState<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  // Simulated incoming call data — in production, injected via TelecomService
  static const _callerName = 'Sarah Johnson';
  static const _callerNumber = '+1 (555) 234-7890';
  static const _callerPhoto = null;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0D1F3C),
              Color(0xFF091A32),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Animated ripples ───────────────────────────────
            Positioned(
              top: size.height * 0.12,
              left: 0,
              right: 0,
              child: Center(child: _RippleEffect(controller: _rippleController)),
            ),

            // ── Content ────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Incoming label
                  Text(
                    'Incoming Call',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),

                  // Caller avatar
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale =
                          1.0 + 0.04 * _pulseController.value;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: ContactAvatar(
                      name: _callerName,
                      photoUri: _callerPhoto,
                      size: 120,
                      showRing: true,
                    ).animate().scale(
                          begin: const Offset(0.7, 0.7),
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        ),
                  ),

                  const SizedBox(height: 24),

                  // Caller name
                  Text(
                    _callerName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 400.ms,
                        delay: 300.ms,
                      ),

                  const SizedBox(height: 6),

                  Text(
                    _callerNumber,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 8),

                  // SIM indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sim_card,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'SIM 1 · Mobile',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const Spacer(),

                  // Quick actions
                  _QuickActions().animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 40),

                  // Answer / Reject
                  _SwipeAnswerBar(
                    onAnswer: () {
                      HapticFeedback.heavyImpact();
                      Navigator.pushReplacementNamed(context, '/call');
                    },
                    onReject: () {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(context);
                    },
                  ).animate().slideY(
                        begin: 1,
                        end: 0,
                        duration: 500.ms,
                        delay: 400.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ripple Effect ────────────────────────────────────────────────────────────

class _RippleEffect extends StatelessWidget {
  final AnimationController controller;

  const _RippleEffect({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          width: 300,
          height: 300,
          child: CustomPaint(
            painter: _RipplePainter(controller.value),
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  _RipplePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final offset = (i / 3.0);
      final animatedProgress = (progress + offset) % 1.0;
      final radius = maxRadius * animatedProgress;
      final opacity = (1 - animatedProgress) * 0.25;

      final paint = Paint()
        ..color = AppColors.primary.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickActionBtn(
          icon: Icons.message_outlined,
          label: 'Message',
          onTap: () {},
        ),
        _QuickActionBtn(
          icon: Icons.alarm_outlined,
          label: 'Remind me',
          onTap: () {},
        ),
        _QuickActionBtn(
          icon: Icons.volume_off_outlined,
          label: 'Silence',
          onTap: () {},
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Swipe Answer Bar ─────────────────────────────────────────────────────────

class _SwipeAnswerBar extends StatefulWidget {
  final VoidCallback onAnswer;
  final VoidCallback onReject;

  const _SwipeAnswerBar(
      {required this.onAnswer, required this.onReject});

  @override
  State<_SwipeAnswerBar> createState() => _SwipeAnswerBarState();
}

class _SwipeAnswerBarState extends State<_SwipeAnswerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _hintController;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reject button
          _CallActionButton(
            icon: Icons.call_end_rounded,
            color: AppColors.callRed,
            bgColor: AppColors.callRedBg.withOpacity(0.15),
            label: 'Decline',
            onPressed: widget.onReject,
          ),

          // Hint text
          AnimatedBuilder(
            animation: _hintController,
            builder: (_, __) => Opacity(
              opacity: 0.4 + 0.4 * _hintController.value,
              child: Text(
                '● ● ●',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

          // Answer button
          _CallActionButton(
            icon: Icons.call_rounded,
            color: AppColors.callGreen,
            bgColor: AppColors.callGreenBg.withOpacity(0.15),
            label: 'Answer',
            onPressed: widget.onAnswer,
          ),
        ],
      ),
    );
  }
}

class _CallActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;
  final VoidCallback onPressed;

  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_CallActionButton> createState() => _CallActionButtonState();
}

class _CallActionButtonState extends State<_CallActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: widget.color, size: 36),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
