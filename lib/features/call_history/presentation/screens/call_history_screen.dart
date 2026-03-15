// lib/features/call_history/presentation/screens/call_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/models.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/contact_avatar.dart';

// ─── Mock provider — replace with real DB repo ───────────────────────────────
final callHistoryProvider = Provider<List<CallLogModel>>((ref) {
  final now = DateTime.now();
  return [
    CallLogModel(
      id: '1',
      number: '5559876543',
      contactName: 'Sarah Johnson',
      type: CallType.missed,
      timestamp: now.subtract(const Duration(hours: 2)),
      durationSeconds: 0,
    ),
    CallLogModel(
      id: '2',
      number: '5551234567',
      contactName: 'David Lee',
      type: CallType.outgoing,
      timestamp: now.subtract(const Duration(hours: 5)),
      durationSeconds: 243,
    ),
    CallLogModel(
      id: '3',
      number: '5554443322',
      type: CallType.incoming,
      timestamp: now.subtract(const Duration(days: 1)),
      durationSeconds: 60,
    ),
    CallLogModel(
      id: '4',
      number: '5557778899',
      contactName: 'Mom',
      type: CallType.outgoing,
      timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      durationSeconds: 754,
    ),
    CallLogModel(
      id: '5',
      number: '5551112222',
      contactName: 'Alex Rivera',
      type: CallType.missed,
      timestamp: now.subtract(const Duration(days: 2)),
      durationSeconds: 0,
    ),
    CallLogModel(
      id: '6',
      number: '5556667777',
      contactName: 'Tech Support',
      type: CallType.incoming,
      timestamp: now.subtract(const Duration(days: 3)),
      durationSeconds: 1820,
      isRecorded: true,
    ),
  ];
});

// ─── Screen ────────────────────────────────────────────────────────────────────

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logs = ref.watch(callHistoryProvider);
    final missed = logs.where((l) => l.type == CallType.missed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _showClearDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          labelStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: [
            const Tab(text: 'All'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Missed'),
                  if (missed.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.missed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${missed.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Recorded'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CallList(logs: logs),
          _CallList(logs: missed),
          _CallList(
              logs: logs.where((l) => l.isRecorded).toList()),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear all history?',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.missed),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

// ─── Call List ─────────────────────────────────────────────────────────────────

class _CallList extends StatelessWidget {
  final List<CallLogModel> logs;
  const _CallList({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded,
                size: 64,
                color: AppColors.textSecondaryLight.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'No calls here',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: AppColors.textSecondaryLight.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<CallLogModel>>{};
    for (final log in logs) {
      final key = _dateKey(log.timestamp);
      grouped.putIfAbsent(key, () => []).add(log);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: grouped.keys.length,
      itemBuilder: (context, i) {
        final dateKey = grouped.keys.elementAt(i);
        final dayLogs = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            ...dayLogs.asMap().entries.map((entry) =>
                _CallTile(log: entry.value, index: entry.key)),
          ],
        );
      },
    );
  }

  static String _dateKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(dt);
  }
}

// ─── Call Tile ─────────────────────────────────────────────────────────────────

class _CallTile extends StatelessWidget {
  final CallLogModel log;
  final int index;

  const _CallTile({required this.log, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {},
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: Icons.call_rounded,
            label: 'Call',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          ),
          SlidableAction(
            onPressed: (_) {},
            backgroundColor: AppColors.missed,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: ContactAvatar(
            name: log.displayName,
            size: 44,
          ),
          title: Text(
            log.displayName,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: log.type == CallType.missed
                  ? AppColors.missed
                  : isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
            ),
          ),
          subtitle: Row(
            children: [
              _CallTypeIcon(type: log.type),
              const SizedBox(width: 4),
              Text(
                _typeLabel(log.type),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: _typeColor(log.type),
                ),
              ),
              if (log.durationSeconds > 0) ...[
                Text(
                  '  ·  ${log.durationFormatted}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('h:mm a').format(log.timestamp),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              if (log.isRecorded)
                const Icon(Icons.fiber_manual_record,
                    color: AppColors.callRed, size: 8),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0, duration: 300.ms);
  }

  String _typeLabel(CallType type) {
    return switch (type) {
      CallType.incoming => 'Incoming',
      CallType.outgoing => 'Outgoing',
      CallType.missed => 'Missed',
      CallType.rejected => 'Rejected',
      CallType.blocked => 'Blocked',
    };
  }

  Color _typeColor(CallType type) {
    return switch (type) {
      CallType.missed || CallType.rejected => AppColors.missed,
      CallType.incoming => AppColors.incoming,
      CallType.outgoing => AppColors.outgoing,
      CallType.blocked => Colors.grey,
    };
  }
}

class _CallTypeIcon extends StatelessWidget {
  final CallType type;
  const _CallTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      CallType.missed => (Icons.call_missed_rounded, AppColors.missed),
      CallType.incoming => (Icons.call_received_rounded, AppColors.incoming),
      CallType.outgoing => (Icons.call_made_rounded, AppColors.outgoing),
      CallType.rejected => (Icons.call_missed_outgoing_rounded, AppColors.missed),
      CallType.blocked => (Icons.block_rounded, Colors.grey),
    };
    return Icon(icon, size: 12, color: color);
  }
}
