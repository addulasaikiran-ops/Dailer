// lib/features/settings/presentation/screens/blocked_numbers_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../core/services/spam_service.dart';

class BlockedNumbersScreen extends ConsumerWidget {
  const BlockedNumbersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blockedAsync = ref.watch(blockedNumbersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Numbers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddBlockDialog(context, ref),
          ),
        ],
      ),
      body: blockedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (blocked) => blocked.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: blocked.length,
                itemBuilder: (context, i) => Slidable(
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) async {
                          await ref
                              .read(spamServiceProvider)
                              .unblockNumber(blocked[i].number);
                          ref.invalidate(blockedNumbersProvider);
                        },
                        backgroundColor: AppColors.callGreen,
                        foregroundColor: Colors.white,
                        icon: Icons.lock_open_rounded,
                        label: 'Unblock',
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
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.missed.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.block_rounded,
                            color: AppColors.missed, size: 18),
                      ),
                      title: Text(
                        blocked[i].number,
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
                        blocked[i].label ?? 'Blocked',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 40))
                      .fadeIn(duration: 250.ms),
                ),
              ),
      ),
    );
  }

  void _showAddBlockDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Block number',
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\) ]'))
          ],
          decoration: const InputDecoration(hintText: 'Enter phone number'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await ref
                    .read(spamServiceProvider)
                    .blockNumber(ctrl.text.trim(), label: 'Manually blocked');
                ref.invalidate(blockedNumbersProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.missed),
            child: const Text('Block',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
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
          Icon(Icons.block_rounded,
              size: 64,
              color: AppColors.textSecondaryLight.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No blocked numbers',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to block a number',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13),
          ),
        ],
      ),
    );
  }
}
