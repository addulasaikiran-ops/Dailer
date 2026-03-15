// lib/features/voicemail/presentation/screens/voicemail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/models.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/contact_avatar.dart';

final voicemailsProvider = Provider<List<VoicemailModel>>((ref) {
  final now = DateTime.now();
  return [
    VoicemailModel(
      id: '1',
      number: '5551234567',
      contactName: 'David Lee',
      timestamp: now.subtract(const Duration(hours: 1)),
      durationSeconds: 45,
      isRead: false,
    ),
    VoicemailModel(
      id: '2',
      number: '5557778899',
      contactName: 'Mom',
      timestamp: now.subtract(const Duration(days: 1)),
      durationSeconds: 120,
      isRead: true,
    ),
  ];
});

class VoicemailScreen extends ConsumerWidget {
  const VoicemailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final voicemails = ref.watch(voicemailsProvider);
    final unread = voicemails.where((v) => !v.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Voicemail'),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread new',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: voicemails.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: voicemails.length,
              itemBuilder: (context, i) => _VoicemailTile(
                    vm: voicemails[i],
                    index: i,
                    isDark: isDark,
                  ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.voicemail_rounded,
              size: 72, color: AppColors.textSecondaryLight.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No voicemails',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryLight.withOpacity(0.5),
              )),
          const SizedBox(height: 8),
          Text('New messages will appear here',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppColors.textSecondaryLight.withOpacity(0.4),
              )),
        ],
      ),
    );
  }
}

class _VoicemailTile extends StatefulWidget {
  final VoicemailModel vm;
  final int index;
  final bool isDark;

  const _VoicemailTile(
      {required this.vm, required this.index, required this.isDark});

  @override
  State<_VoicemailTile> createState() => _VoicemailTileState();
}

class _VoicemailTileState extends State<_VoicemailTile> {
  bool _expanded = false;
  bool _playing = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final isDark = widget.isDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: !vm.isRead
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                ContactAvatar(name: vm.displayName, size: 46),
                if (!vm.isRead)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              vm.displayName,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight:
                    vm.isRead ? FontWeight.w600 : FontWeight.w800,
                fontSize: 15,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              '${DateFormat('MMM d, h:mm a').format(vm.timestamp)} · ${_durLabel(vm.durationSeconds)}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            trailing: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),

          // Expanded player
          if (_expanded)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Progress bar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 3,
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: _progress,
                      onChanged: (v) => setState(() => _progress = v),
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.primary.withOpacity(0.2),
                    ),
                  ),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded),
                        onPressed: () {},
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _playing = !_playing),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Icon(
                            _playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded),
                        onPressed: () {},
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const Spacer(),
                      // Call back
                      IconButton(
                        icon: const Icon(Icons.call_rounded),
                        color: AppColors.callGreen,
                        onPressed: () {},
                      ),
                      // Delete
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppColors.callRed,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0);
  }

  String _durLabel(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}
