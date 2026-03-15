// lib/features/dialpad/presentation/screens/dialpad_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/contact_avatar.dart';
import '../providers/dialpad_provider.dart';
import '../widgets/dial_key.dart';
import '../widgets/t9_suggestions.dart';

class DialpadScreen extends ConsumerStatefulWidget {
  const DialpadScreen({super.key});

  @override
  ConsumerState<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends ConsumerState<DialpadScreen>
    with TickerProviderStateMixin {
  late AnimationController _callBtnController;
  bool _showDialpad = true;

  @override
  void initState() {
    super.initState();
    _callBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _callBtnController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    HapticFeedback.lightImpact();
    ref.read(dialpadProvider.notifier).appendKey(key);
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    ref.read(dialpadProvider.notifier).backspace();
  }

  void _onCall() {
    final number = ref.read(dialpadProvider).displayNumber;
    if (number.isEmpty) return;
    HapticFeedback.mediumImpact();
    context.push('/call', extra: {'number': number, 'isOutgoing': true});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(dialpadProvider);
    final suggestions = ref.watch(t9SuggestionsProvider);
    final hasInput = state.displayNumber.isNotEmpty;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _buildHeader(context, isDark),

            // ── Number Display ───────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasInput) ...[
                    _buildNumberDisplay(context, state, isDark),
                    const SizedBox(height: 8),
                    if (suggestions.isNotEmpty)
                      T9Suggestions(
                        suggestions: suggestions,
                        onSelect: (contact) {
                          ref
                              .read(dialpadProvider.notifier)
                              .setNumber(contact.primaryPhone);
                        },
                      ),
                  ] else ...[
                    _buildSpeedDial(context, isDark),
                  ],
                ],
              ),
            ),

            // ── Dialpad ──────────────────────────────────────────
            _buildDialpad(context, isDark, hasInput),

            // ── Call Button ──────────────────────────────────────
            _buildCallButton(context, isDark, hasInput),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            'OpenDialer',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            onPressed: () => context.push('/contacts'),
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            onPressed: () => _showMoreMenu(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildNumberDisplay(
      BuildContext context, DialpadState state, bool isDark) {
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(
                        ClipboardData(text: state.displayNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Number copied'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                  child: Text(
                    state.formattedNumber,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: state.displayNumber.length > 12 ? 28 : 36,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _onBackspace,
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  ref.read(dialpadProvider.notifier).clear();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 18,
                    color: subColor,
                  ),
                ),
              ),
            ],
          ),
          if (state.matchedContact != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ContactAvatar(
                  name: state.matchedContact!.displayName,
                  photoUri: state.matchedContact!.photoUri,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  state.matchedContact!.displayName,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
          // SIM selector
          const SizedBox(height: 12),
          _SimSelector(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildSpeedDial(BuildContext context, bool isDark) {
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Column(
      children: [
        Icon(
          Icons.dialpad_rounded,
          size: 40,
          color: isDark
              ? AppColors.textSecondaryDark.withOpacity(0.3)
              : AppColors.textSecondaryLight.withOpacity(0.3),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter a number to call',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDialpad(BuildContext context, bool isDark, bool hasInput) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];
    const subLabels = {
      '1': '',
      '2': 'ABC',
      '3': 'DEF',
      '4': 'GHI',
      '5': 'JKL',
      '6': 'MNO',
      '7': 'PQRS',
      '8': 'TUV',
      '9': 'WXYZ',
      '*': '',
      '0': '+',
      '#': '',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          for (final row in keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row
                    .map((key) => DialKey(
                          label: key,
                          subLabel: subLabels[key] ?? '',
                          isDark: isDark,
                          onPressed: () => _onKeyPressed(key),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallButton(BuildContext context, bool isDark, bool hasInput) {
    return AnimatedOpacity(
      opacity: hasInput ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80),
        child: GestureDetector(
          onTap: hasInput ? _onCall : null,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06D6A0), Color(0xFF00B887)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06D6A0).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call_rounded, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text(
                  'Call',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(target: hasInput ? 1 : 0).scaleXY(
          begin: 0.95,
          end: 1.0,
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MoreMenuSheet(),
    );
  }
}

class _SimSelector extends ConsumerWidget {
  final bool isDark;
  const _SimSelector({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dialpadProvider);
    final bgColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SimChip(
            label: 'SIM 1',
            selected: state.selectedSim == 0,
            isDark: isDark,
            onTap: () => ref.read(dialpadProvider.notifier).selectSim(0),
          ),
          _SimChip(
            label: 'SIM 2',
            selected: state.selectedSim == 1,
            isDark: isDark,
            onTap: () => ref.read(dialpadProvider.notifier).selectSim(1),
          ),
        ],
      ),
    );
  }
}

class _SimChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _SimChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
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
    );
  }
}

class _MoreMenuSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _MenuTile(
            icon: Icons.call_merge_rounded,
            label: 'Conference call',
            onTap: () => Navigator.pop(context),
          ),
          _MenuTile(
            icon: Icons.speed_rounded,
            label: 'Speed dial',
            onTap: () => Navigator.pop(context),
          ),
          _MenuTile(
            icon: Icons.block_rounded,
            label: 'Blocked numbers',
            onTap: () => Navigator.pop(context),
          ),
          _MenuTile(
            icon: Icons.settings_rounded,
            label: 'Call settings',
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
