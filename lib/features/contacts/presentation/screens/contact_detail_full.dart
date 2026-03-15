// lib/features/contacts/presentation/screens/contact_detail_full.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/contact_avatar.dart';
import '../../../call_history/data/call_log_repository.dart';

class ContactDetailFullScreen extends ConsumerWidget {
  final String contactId;
  const ContactDetailFullScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In production, fetch from contactsRepositoryProvider by ID
    const contact = ContactModel(
      id: '8',
      displayName: 'Sarah Johnson',
      phones: ['+1 (555) 987-6543', '+1 (555) 111-2222'],
      isFavorite: true,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsing App Bar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            actions: [
              IconButton(
                icon: Icon(
                    contact.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFBE0B)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/contacts/new'),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') _confirmDelete(context);
                  if (v == 'block') {}
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'block',
                      child: Text('Block number',
                          style: TextStyle(fontFamily: 'Nunito'))),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete contact',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              color: AppColors.missed))),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [const Color(0xFF161829), AppColors.surfaceDark]
                        : [
                            AppColors.primary.withOpacity(0.05),
                            AppColors.surfaceLight
                          ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 64),
                    ContactAvatar(
                      name: contact.displayName,
                      photoUri: contact.photoUri,
                      size: 88,
                      showRing: true,
                    ).animate().scale(
                          begin: const Offset(0.7, 0.7),
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 12),
                    Text(
                      contact.displayName,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ).animate(delay: 200.ms).fadeIn(),
                  ],
                ),
              ),
            ),
          ),

          // ── Quick Actions ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QuickAction(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    color: AppColors.callGreen,
                    onTap: () =>
                        context.push('/call', extra: {'number': contact.primaryPhone}),
                  ),
                  _QuickAction(
                    icon: Icons.message_rounded,
                    label: 'Message',
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                  _QuickAction(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    color: const Color(0xFF8338EC),
                    onTap: () {},
                  ),
                  _QuickAction(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    color: AppColors.accentWarm,
                    onTap: () {},
                  ),
                ],
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
            ),
          ),

          // ── Phone numbers ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _Section(
              title: 'Phone',
              isDark: isDark,
              delay: 400,
              children: contact.phones
                  .asMap()
                  .entries
                  .map((e) => _InfoTile(
                        icon: Icons.phone_outlined,
                        title: e.value,
                        subtitle: e.key == 0 ? 'Mobile' : 'Work',
                        isDark: isDark,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _IconAction(
                                icon: Icons.copy_outlined,
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: e.value));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('Copied'),
                                    duration: Duration(seconds: 1),
                                  ));
                                }),
                            _IconAction(
                                icon: Icons.call_rounded,
                                color: AppColors.callGreen,
                                onTap: () => context.push('/call',
                                    extra: {'number': e.value})),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          // ── Recent calls ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Section(
              title: 'Recent Calls',
              isDark: isDark,
              delay: 500,
              children: [
                _InfoTile(
                  icon: Icons.call_missed_rounded,
                  iconColor: AppColors.missed,
                  title: 'Missed call',
                  subtitle: 'Today, 2:30 PM',
                  isDark: isDark,
                ),
                _InfoTile(
                  icon: Icons.call_made_rounded,
                  iconColor: AppColors.outgoing,
                  title: 'Outgoing · 4m 3s',
                  subtitle: 'Yesterday, 11:00 AM',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete contact?',
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: const Text('This cannot be undone.',
            style: TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.missed),
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final bool isDark;
  final int delay;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.isDark,
    required this.delay,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: children.asMap().entries.map((e) {
                return Column(
                  children: [
                    if (e.key > 0)
                      Divider(
                        height: 1,
                        indent: 52,
                        color: isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight,
                      ),
                    e.value,
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      )
          .animate(delay: Duration(milliseconds: delay))
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.1, end: 0),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ??
        (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    return ListTile(
      leading: Icon(icon, color: ic, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      trailing: trailing,
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _IconAction({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 16, color: color ?? AppColors.primary),
      ),
    );
  }
}
