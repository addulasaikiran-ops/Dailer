// lib/features/dialpad/presentation/providers/dialpad_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/models.dart';

class DialpadState {
  final String rawNumber;
  final int selectedSim;
  final ContactModel? matchedContact;

  const DialpadState({
    this.rawNumber = '',
    this.selectedSim = 0,
    this.matchedContact,
  });

  String get displayNumber => rawNumber;

  String get formattedNumber {
    final digits = rawNumber.replaceAll(RegExp(r'[^\d+*#]'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    return rawNumber;
  }

  DialpadState copyWith({
    String? rawNumber,
    int? selectedSim,
    ContactModel? matchedContact,
    bool clearContact = false,
  }) {
    return DialpadState(
      rawNumber: rawNumber ?? this.rawNumber,
      selectedSim: selectedSim ?? this.selectedSim,
      matchedContact: clearContact ? null : matchedContact ?? this.matchedContact,
    );
  }
}

class DialpadNotifier extends StateNotifier<DialpadState> {
  DialpadNotifier() : super(const DialpadState());

  void appendKey(String key) {
    final newNumber = state.rawNumber + key;
    state = state.copyWith(rawNumber: newNumber);
    _lookupContact(newNumber);
  }

  void backspace() {
    if (state.rawNumber.isEmpty) return;
    final newNumber =
        state.rawNumber.substring(0, state.rawNumber.length - 1);
    state = state.copyWith(
      rawNumber: newNumber,
      clearContact: newNumber.isEmpty,
    );
    if (newNumber.isNotEmpty) _lookupContact(newNumber);
  }

  void clear() {
    state = const DialpadState();
  }

  void setNumber(String number) {
    state = state.copyWith(rawNumber: number);
    _lookupContact(number);
  }

  void selectSim(int slot) {
    state = state.copyWith(selectedSim: slot);
  }

  void _lookupContact(String number) {
    // TODO: lookup from contacts repository
    // This would be injected via the provider in production
  }
}

final dialpadProvider =
    StateNotifierProvider<DialpadNotifier, DialpadState>((ref) {
  return DialpadNotifier();
});

final t9SuggestionsProvider =
    Provider<List<ContactModel>>((ref) {
  final input = ref.watch(dialpadProvider).rawNumber;
  if (input.length < 2) return [];
  // In production: perform T9 lookup from contacts repo
  return [];
});
