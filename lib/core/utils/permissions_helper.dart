// lib/core/utils/permissions_helper.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralised permission request helper.
/// Call [requestAll] on app start after becoming default dialer.
class PermissionsHelper {
  /// Permissions required for core functionality.
  static const _required = [
    Permission.phone,
    Permission.contacts,
    Permission.callLog,
  ];

  /// Permissions required for call recording.
  static const _recording = [
    Permission.microphone,
    Permission.storage,
  ];

  /// Request all core permissions in one shot.
  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    return await _required.request();
  }

  /// Request recording permissions.
  static Future<bool> requestRecording() async {
    final result = await _recording.request();
    return result.values.every((s) => s.isGranted);
  }

  /// Returns true if all core permissions are granted.
  static Future<bool> get hasAllRequired async {
    for (final p in _required) {
      if (!(await p.isGranted)) return false;
    }
    return true;
  }

  /// Returns true if recording is permitted.
  static Future<bool> get canRecord async {
    return (await Permission.microphone.isGranted) &&
        (await Permission.storage.isGranted ||
            await Permission.manageExternalStorage.isGranted);
  }

  /// Show a dialog guiding the user to app settings when a permission is
  /// permanently denied.
  static Future<void> showPermanentlyDeniedDialog(
    BuildContext context,
    String permissionName,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$permissionName Required',
          style: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'OpenDialer needs the $permissionName permission to work properly. '
          'Please grant it in the app settings.',
          style: const TextStyle(fontFamily: 'Nunito'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
