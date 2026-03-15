// lib/features/settings/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../core/services/settings_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── Appearance ─────────────────────────────────────────
          _SectionCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            iconColor: const Color(0xFF8338EC),
            isDark: isDark,
            delay: 0,
            children: [
              _SegmentedSettingTile(
                label: 'Theme',
                subtitle: 'Choose your preferred look',
                options: const ['System', 'Light', 'Dark'],
                selectedIndex: themeMode.index,
                onChanged: (i) => ref
                    .read(themeModeProvider.notifier)
                    .setMode(ThemeMode.values[i]),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Call Recording ─────────────────────────────────────
          _SectionCard(
            title: 'Call Recording',
            icon: Icons.fiber_manual_record_rounded,
            iconColor: AppColors.callRed,
            isDark: isDark,
            delay: 80,
            children: [
              _SwitchTile(
                label: 'Enable call recording',
                subtitle: 'Allow recording calls manually',
                value: settings.callRecordingEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setCallRecording(v),
                isDark: isDark,
              ),
              if (settings.callRecordingEnabled)
                _SwitchTile(
                  label: 'Auto-record all calls',
                  subtitle: 'Automatically start recording every call',
                  value: settings.autoRecordAll,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setAutoRecord(v),
                  isDark: isDark,
                ),
              _NavigateTile(
                label: 'Recordings folder',
                subtitle: 'View saved recordings',
                icon: Icons.folder_outlined,
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── SIM & Network ──────────────────────────────────────
          _SectionCard(
            title: 'SIM & Network',
            icon: Icons.sim_card_outlined,
            iconColor: AppColors.accent,
            isDark: isDark,
            delay: 160,
            children: [
              _SegmentedSettingTile(
                label: 'Default SIM for calls',
                subtitle: 'Select which SIM to use by default',
                options: const ['SIM 1', 'SIM 2', 'Ask'],
                selectedIndex: settings.defaultSimSlot,
                onChanged: (i) =>
                    ref.read(settingsProvider.notifier).setDefaultSim(i),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Feedback & Interaction ─────────────────────────────
          _SectionCard(
            title: 'Interaction',
            icon: Icons.touch_app_outlined,
            iconColor: AppColors.primary,
            isDark: isDark,
            delay: 240,
            children: [
              _SwitchTile(
                label: 'Haptic feedback on dialpad',
                subtitle: 'Vibrate when pressing dial keys',
                value: settings.hapticDialpad,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setHaptic(v),
                isDark: isDark,
              ),
              _SwitchTile(
                label: 'Vibrate on ring',
                subtitle: 'Phone vibrates for incoming calls',
                value: settings.vibrateOnRing,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setVibrate(v),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Spam & Blocking ────────────────────────────────────
          _SectionCard(
            title: 'Spam & Blocking',
            icon: Icons.block_rounded,
            iconColor: AppColors.accentWarm,
            isDark: isDark,
            delay: 320,
            children: [
              _SwitchTile(
                label: 'Spam call protection',
                subtitle: 'Identify and filter suspected spam',
                value: settings.spamBlockingEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setSpamBlocking(v),
                isDark: isDark,
              ),
              _NavigateTile(
                label: 'Blocked numbers',
                subtitle: 'Manage your block list',
                icon: Icons.list_alt_outlined,
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Language ───────────────────────────────────────────
          _SectionCard(
            title: 'Language & Region',
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF06D6A0),
            isDark: isDark,
            delay: 400,
            children: [
              _NavigateTile(
                label: 'Language',
                subtitle: _languageLabel(settings.language),
                icon: Icons.translate_rounded,
                isDark: isDark,
                onTap: () => _showLanguagePicker(context, ref, settings.language),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── About ──────────────────────────────────────────────
          _SectionCard(
            title: 'About',
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.textSecondaryLight,
            isDark: isDark,
            delay: 480,
            children: [
              _NavigateTile(
                label: 'Version',
                subtitle: '1.0.0 (MIT License)',
                icon: Icons.verified_outlined,
                isDark: isDark,
                onTap: () {},
              ),
              _NavigateTile(
                label: 'Open source licenses',
                subtitle: 'Third-party components',
                icon: Icons.code_rounded,
                isDark: isDark,
                onTap: () => showLicensePage(context: context),
              ),
              _NavigateTile(
                label: 'Privacy Policy',
                subtitle: 'How we handle your data',
                icon: Icons.privacy_tip_outlined,
                isDark: isDark,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _languageLabel(String code) {
    const map = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'zh': '中文',
      'ar': 'العربية',
      'hi': 'हिन्दी',
    };
    return map[code] ?? code;
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String current) {
    const langs = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'zh': '中文',
      'ar': 'العربية',
      'hi': 'हिन्दी',
    };
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Select Language',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
          ...langs.entries.map((e) => ListTile(
                title: Text(e.value,
                    style: const TextStyle(fontFamily: 'Nunito')),
                trailing: current == e.key
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLanguage(e.key);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final int delay;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.delay,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          ...children.map((child) => Column(
                children: [
                  if (children.indexOf(child) > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                    ),
                  child,
                ],
              )),
          const SizedBox(height: 8),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.06, end: 0, duration: 300.ms);
  }
}

// ─── Setting Tiles ────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SwitchTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}

class _NavigateTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _NavigateTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          size: 20),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      onTap: onTap,
    );
  }
}

class _SegmentedSettingTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _SegmentedSettingTile({
    required this.label,
    required this.subtitle,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: options.asMap().entries.map((e) {
                final selected = e.key == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        e.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
