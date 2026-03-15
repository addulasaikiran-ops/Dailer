// lib/shared/widgets/contact_avatar.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Generates a consistent color from the contact name
Color _colorForName(String name) {
  const palette = [
    Color(0xFF3D7BFF),
    Color(0xFF06D6A0),
    Color(0xFFFF6B6B),
    Color(0xFFFFBE0B),
    Color(0xFFFB5607),
    Color(0xFF8338EC),
    Color(0xFF3A86FF),
    Color(0xFFFF006E),
  ];
  if (name.isEmpty) return palette[0];
  final hash = name.codeUnits.fold(0, (a, b) => a + b);
  return palette[hash % palette.length];
}

class ContactAvatar extends StatelessWidget {
  final String name;
  final String? photoUri;
  final double size;
  final bool showRing;

  const ContactAvatar({
    super.key,
    required this.name,
    this.photoUri,
    this.size = 48,
    this.showRing = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForName(name);
    final initials = _initials(name);
    final fontSize = size * 0.38;

    Widget avatar;

    if (photoUri != null && photoUri!.isNotEmpty) {
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: photoUri!.startsWith('http')
            ? Image.network(
                photoUri!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials_widget(size, color, initials, fontSize),
              )
            : Image.file(
                File(photoUri!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials_widget(size, color, initials, fontSize),
              ),
      );
    } else {
      avatar = _initials_widget(size, color, initials, fontSize);
    }

    if (showRing) {
      return Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _initials_widget(
      double size, Color color, String initials, double fontSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
