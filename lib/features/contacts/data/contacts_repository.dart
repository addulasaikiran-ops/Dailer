// lib/features/contacts/data/contacts_repository.dart

import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';

class ContactsRepository {
  /// Request permission and fetch all device contacts.
  Future<bool> requestPermission() async {
    return await fc.FlutterContacts.requestPermission();
  }

  Future<List<ContactModel>> getAll() async {
    final hasPermission = await fc.FlutterContacts.requestPermission();
    if (!hasPermission) return [];

    final contacts = await fc.FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
      withThumbnail: true,
    );

    return contacts.map(_toModel).where((c) => c.phones.isNotEmpty).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  Future<ContactModel?> getById(String id) async {
    final contact = await fc.FlutterContacts.getContact(id);
    if (contact == null) return null;
    return _toModel(contact);
  }

  Future<ContactModel?> findByNumber(String number) async {
    final normalized = _normalize(number);
    final contacts = await getAll();
    for (final c in contacts) {
      for (final phone in c.phones) {
        if (_normalize(phone) == normalized) return c;
      }
    }
    return null;
  }

  Future<List<ContactModel>> search(String query) async {
    if (query.isEmpty) return [];
    final all = await getAll();
    final q = query.toLowerCase();
    return all
        .where((c) =>
            c.displayName.toLowerCase().contains(q) ||
            c.phones.any((p) => p.contains(q)))
        .take(20)
        .toList();
  }

  static ContactModel _toModel(fc.Contact c) {
    return ContactModel(
      id: c.id,
      displayName: c.displayName.isNotEmpty
          ? c.displayName
          : c.phones.isNotEmpty
              ? c.phones.first.number
              : 'Unknown',
      phones: c.phones.map((p) => p.number).toList(),
      photoUri: c.photoOrThumbnail != null
          ? 'contact_thumbnail:${c.id}'
          : null,
    );
  }

  static String _normalize(String number) {
    return number.replaceAll(RegExp(r'[^\d]'), '');
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return ContactsRepository();
});

final deviceContactsProvider = FutureProvider<List<ContactModel>>((ref) {
  return ref.watch(contactsRepositoryProvider).getAll();
});

final contactSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedContactsProvider = FutureProvider<List<ContactModel>>((ref) {
  final query = ref.watch(contactSearchQueryProvider);
  final repo = ref.watch(contactsRepositoryProvider);
  if (query.isEmpty) return Future.value([]);
  return repo.search(query);
});
