// lib/core/services/settings_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Keys ─────────────────────────────────────────────────────────────────────
const _kThemeMode = 'theme_mode';
const _kCallRecording = 'call_recording_enabled';
const _kAutoRecord = 'auto_record_all';
const _kDefaultSim = 'default_sim_slot';
const _kSpamBlocking = 'spam_blocking';
const _kVibrate = 'vibrate_on_ring';
const _kHaptic = 'haptic_dialpad';
const _kLanguage = 'language';

// ─── Providers ────────────────────────────────────────────────────────────────
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not yet loaded');
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) {
    final prefs = ref.watch(sharedPrefsProvider);
    return ThemeModeNotifier(prefs);
  },
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs)
      : super(ThemeMode.values[_prefs.getInt(_kThemeMode) ?? 0]);

  void setMode(ThemeMode mode) {
    state = mode;
    _prefs.setInt(_kThemeMode, mode.index);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsNotifier(prefs);
});

class AppSettings {
  final bool callRecordingEnabled;
  final bool autoRecordAll;
  final int defaultSimSlot;
  final bool spamBlockingEnabled;
  final bool vibrateOnRing;
  final bool hapticDialpad;
  final String language;

  const AppSettings({
    this.callRecordingEnabled = false,
    this.autoRecordAll = false,
    this.defaultSimSlot = 0,
    this.spamBlockingEnabled = true,
    this.vibrateOnRing = true,
    this.hapticDialpad = true,
    this.language = 'en',
  });

  AppSettings copyWith({
    bool? callRecordingEnabled,
    bool? autoRecordAll,
    int? defaultSimSlot,
    bool? spamBlockingEnabled,
    bool? vibrateOnRing,
    bool? hapticDialpad,
    String? language,
  }) {
    return AppSettings(
      callRecordingEnabled: callRecordingEnabled ?? this.callRecordingEnabled,
      autoRecordAll: autoRecordAll ?? this.autoRecordAll,
      defaultSimSlot: defaultSimSlot ?? this.defaultSimSlot,
      spamBlockingEnabled: spamBlockingEnabled ?? this.spamBlockingEnabled,
      vibrateOnRing: vibrateOnRing ?? this.vibrateOnRing,
      hapticDialpad: hapticDialpad ?? this.hapticDialpad,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs)
      : super(AppSettings(
          callRecordingEnabled: _prefs.getBool(_kCallRecording) ?? false,
          autoRecordAll: _prefs.getBool(_kAutoRecord) ?? false,
          defaultSimSlot: _prefs.getInt(_kDefaultSim) ?? 0,
          spamBlockingEnabled: _prefs.getBool(_kSpamBlocking) ?? true,
          vibrateOnRing: _prefs.getBool(_kVibrate) ?? true,
          hapticDialpad: _prefs.getBool(_kHaptic) ?? true,
          language: _prefs.getString(_kLanguage) ?? 'en',
        ));

  void setCallRecording(bool value) {
    state = state.copyWith(callRecordingEnabled: value);
    _prefs.setBool(_kCallRecording, value);
  }

  void setAutoRecord(bool value) {
    state = state.copyWith(autoRecordAll: value);
    _prefs.setBool(_kAutoRecord, value);
  }

  void setDefaultSim(int slot) {
    state = state.copyWith(defaultSimSlot: slot);
    _prefs.setInt(_kDefaultSim, slot);
  }

  void setSpamBlocking(bool value) {
    state = state.copyWith(spamBlockingEnabled: value);
    _prefs.setBool(_kSpamBlocking, value);
  }

  void setVibrate(bool value) {
    state = state.copyWith(vibrateOnRing: value);
    _prefs.setBool(_kVibrate, value);
  }

  void setHaptic(bool value) {
    state = state.copyWith(hapticDialpad: value);
    _prefs.setBool(_kHaptic, value);
  }

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
    _prefs.setString(_kLanguage, lang);
  }
}
