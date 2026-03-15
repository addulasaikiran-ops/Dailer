// lib/features/contacts/presentation/screens/contacts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/contact_avatar.dart';

// ─── Mock contacts ─────────────────────────────────────────────────────────────
final contactsProvider = Provider<List<ContactModel>>((ref) {
  return const [
    ContactModel(id: '1', displayName: 'Alex Rivera', phones: ['5551112222'], isFavorite: true),
    ContactModel(id: '2', displayName: 'David Lee', phones: ['5551234567']),
    ContactModel(id: '3', displayName: 'Emma Thompson', phones: ['5559990011'], isFavorite: true),
    ContactModel(id: '4', displayName: 'James Wright', phones: ['5554445566']),
    ContactModel(id: '5', displayName: 'Mom', phones: ['5557778899'], isFavorite: true),
    ContactModel(id: '6', displayName: 'Nathan Brown', phones: ['5552223344']),
    ContactModel(id: '7', displayName: 'Olivia Chen', phones: ['5556667788']),
    ContactModel(id: '8', displayName: 'Sarah Johnson', phones: ['5559876543']),
    ContactModel(id: '9', displayName: 'Tech Support', phones: ['5556667777']),
    ContactModel(id: '10', displayName: 'Yvonne Garcia', phones: ['5558881122']),
  ];
});

final contactSearchProvider = StateProvider<String>((ref) => '');

final filteredContactsProvider = Provider<List<ContactModel>>((ref) {
  final all = ref.watch(contactsProvider);
  final query = ref.watch(contactSearchProvider).toLowerCase();
  if (query.isEmpty) return all;
  return all
      .where((c) =>
          c.displayName.toLowerCase().contains(query) ||
          c.phones.any((p) => p.contains(query)))
      .toList();
});

// ─── Screen ────────────────────────────────────────────────────────────────────

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contacts = ref.watch(filteredContactsProvider);
    final favorites =
        ref.watch(contactsProvider).where((c) => c.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search contacts...',
                  border: InputBorder.none,
                ),
                onChanged: (v) =>
                    ref.read(contactSearchProvider.notifier).state = v,
              )
            : const Text('Contacts'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchController.clear();
                ref.read(contactSearchProvider.notifier).state = '';
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push('/contacts/new'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Favorites
          if (!_isSearching && favorites.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Favorites', isDark: isDark),
            ),
            SliverToBoxAdapter(
              child: _FavoritesRow(favorites: favorites),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'All Contacts', isDark: isDark),
            ),
          ],

          // Alphabetical list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                // Insert section headers
                if (i == 0 || contacts[i].displayName[0].toUpperCase() !=
                    contacts[i - 1].displayName[0].toUpperCase()) {
                  final letter = contacts[i].displayName[0].toUpperCase();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      _ContactTile(
                          contact: contacts[i], index: i, isDark: isDark),
                    ],
                  );
                }
                return _ContactTile(
                    contact: contacts[i], index: i, isDark: isDark);
              },
              childCount: contacts.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Favorites horizontal row ──────────────────────────────────────────────────

class _FavoritesRow extends StatelessWidget {
  final List<ContactModel> favorites;
  const _FavoritesRow({required this.favorites});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: favorites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final c = favorites[i];
          return GestureDetector(
            onTap: () => context.push('/contacts/${c.id}'),
            child: Column(
              children: [
                ContactAvatar(name: c.displayName, size: 52),
                const SizedBox(height: 4),
                Text(
                  c.displayName.split(' ').first,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Contact Tile ──────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final ContactModel contact;
  final int index;
  final bool isDark;

  const _ContactTile({
    required this.contact,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: ContactAvatar(name: contact.displayName, size: 44),
      title: Text(
        contact.displayName,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        contact.primaryPhone,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contact.isFavorite)
            const Icon(Icons.star_rounded,
                color: Color(0xFFFFBE0B), size: 16),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              // Direct call
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
      onTap: () => context.push('/contacts/${contact.id}'),
    )
        .animate(delay: Duration(milliseconds: index * 30))
        .fadeIn(duration: 250.ms);
  }
}

// ─── Stub screens ──────────────────────────────────────────────────────────────

class ContactDetailScreen extends StatelessWidget {
  final String contactId;
  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
        ],
      ),
      body: const Center(child: Text('Contact detail — wire to contactsProvider')),
    );
  }
}

class AddEditContactScreen extends StatelessWidget {
  final String? contactId;
  const AddEditContactScreen({super.key, this.contactId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contactId == null ? 'New Contact' : 'Edit')),
      body: const Center(child: Text('Add / Edit contact form')),
    );
  }
}
