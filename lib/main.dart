// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'shared/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'features/dialpad/presentation/screens/dialpad_screen.dart';
import 'features/call_history/presentation/screens/call_history_screen.dart';
import 'features/contacts/presentation/screens/contacts_screen.dart';
import 'features/voicemail/presentation/screens/voicemail_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/incoming_call/presentation/screens/incoming_call_screen.dart';
import 'features/active_call/presentation/screens/active_call_screen.dart';
import 'features/contacts/presentation/screens/contact_detail_screen.dart';
import 'features/contacts/presentation/screens/add_edit_contact_screen.dart';
import 'shared/screens/default_dialer_request_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: OpenDialerApp()));
}

final _router = GoRouter(
  initialLocation: '/dialer',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/dialer', builder: (c, s) => const DialpadScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/history',
            builder: (c, s) => const CallHistoryScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/contacts',
            builder: (c, s) => const ContactsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (c, s) =>
                    ContactDetailScreen(contactId: s.pathParameters['id']!),
              ),
              GoRoute(
                path: 'new',
                builder: (c, s) => const AddEditContactScreen(),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/voicemail',
              builder: (c, s) => const VoicemailScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/settings',
              builder: (c, s) => const SettingsScreen()),
        ]),
      ],
    ),

    // Full-screen routes (no bottom nav)
    GoRoute(
      path: '/incoming',
      builder: (c, s) => const IncomingCallScreen(),
    ),
    GoRoute(
      path: '/call',
      builder: (c, s) => const ActiveCallScreen(),
    ),
    GoRoute(
      path: '/default-dialer',
      builder: (c, s) => const DefaultDialerRequestScreen(),
    ),
  ],
);

class OpenDialerApp extends ConsumerWidget {
  const OpenDialerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'OpenDialer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

// ─── Main Shell (Bottom Nav) ──────────────────────────────────────────────────

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: shell,
      extendBody: true,
      bottomNavigationBar: _BottomNav(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        isDark: isDark,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isDark;

  const _BottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dialpad_outlined),
              selectedIcon: Icon(Icons.dialpad),
              label: 'Dialpad',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Recents',
            ),
            NavigationDestination(
              icon: Icon(Icons.contacts_outlined),
              selectedIcon: Icon(Icons.contacts),
              label: 'Contacts',
            ),
            NavigationDestination(
              icon: Icon(Icons.voicemail_outlined),
              selectedIcon: Icon(Icons.voicemail),
              label: 'Voicemail',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
