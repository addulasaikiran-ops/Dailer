// lib/features/dialpad/presentation/widgets/dial_key.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/theme/app_theme.dart';

class DialKey extends StatefulWidget {
  final String label;
  final String subLabel;
  final bool isDark;
  final VoidCallback onPressed;

  const DialKey({
    super.key,
    required this.label,
    required this.subLabel,
    required this.isDark,
    required this.onPressed,
  });

  @override
  State<DialKey> createState() => _DialKeyState();
}

class _DialKeyState extends State<DialKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    setState(() => _pressed = true);
    _scaleController.forward();
  }

  void _onTapUp(_) {
    setState(() => _pressed = false);
    _scaleController.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final btnColor = widget.isDark
        ? AppColors.dialpadBtnDark
        : AppColors.dialpadBtnLight;
    final textColor = widget.isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final subColor = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        final scale = 1.0 - _scaleController.value;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _pressed
                ? (widget.isDark
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.08))
                : btnColor,
            borderRadius: BorderRadius.circular(40),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: widget.isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.0,
                ),
              ),
              if (widget.subLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subLabel,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
