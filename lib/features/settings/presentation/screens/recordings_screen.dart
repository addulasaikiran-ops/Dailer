// lib/features/settings/presentation/screens/recordings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/recording_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/contact_avatar.dart';

final recordingsProvider = FutureProvider<List<RecordingModel>>((ref) {
  return AppDatabase().getRecordings();
});

class RecordingsScreen extends ConsumerWidget {
  const RecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncRec = ref.watch(recordingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Call Recordings')),
      body: asyncRec.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (recordings) => recordings.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: recordings.length,
                itemBuilder: (context, i) {
                  final rec = recordings[i];
                  return Slidable(
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) async {
                            await ref
                                .read(recordingServiceProvider)
                                .deleteRecording(rec);
                            ref.invalidate(recordingsProvider);
                          },
                          backgroundColor: AppColors.missed,
                          foregroundColor: Colors.white,
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: ContactAvatar(name: rec.displayName, size: 44),
                        title: Text(
                          rec.displayName,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormat('MMM d, h:mm a').format(rec.timestamp)} · ${_dur(rec.durationSeconds)} · ${rec.fileSizeFormatted}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        onTap: () => _showPlayer(context, rec),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: i * 40))
                        .fadeIn(duration: 250.ms),
                  );
                },
              ),
      ),
    );
  }

  String _dur(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return m > 0 ? '${m}m ${sec}s' : '${sec}s';
  }

  void _showPlayer(BuildContext context, RecordingModel rec) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PlayerSheet(recording: rec),
    );
  }
}

class _PlayerSheet extends StatefulWidget {
  final RecordingModel recording;
  const _PlayerSheet({required this.recording});

  @override
  State<_PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<_PlayerSheet> {
  bool _playing = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final rec = widget.recording;
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
          ContactAvatar(name: rec.displayName, size: 64),
          const SizedBox(height: 12),
          Text(rec.displayName,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text(DateFormat('EEEE, MMM d yyyy · h:mm a').format(rec.timestamp),
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppColors.textSecondaryLight)),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 3,
            ),
            child: Slider(
              value: _progress,
              onChanged: (v) => setState(() => _progress = v),
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primary.withOpacity(0.2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded),
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _playing = !_playing),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16)
                    ],
                  ),
                  child: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
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
          Icon(Icons.mic_none_rounded,
              size: 64,
              color: AppColors.textSecondaryLight.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No recordings yet',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Enable recording in Settings to save calls',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13)),
        ],
      ),
    );
  }
}
