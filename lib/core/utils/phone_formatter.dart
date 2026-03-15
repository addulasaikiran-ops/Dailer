// lib/core/utils/phone_formatter.dart

/// Lightweight phone number formatter.
/// For production, replace with libphonenumber_plugin for full i18n support.
class PhoneFormatter {
  /// Format a raw number string into a human-readable form.
  static String format(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');

    // International E.164 with country code
    if (digits.startsWith('+')) {
      if (digits.length == 12 && digits.startsWith('+1')) {
        // +1 AAABBBCCCC → +1 (AAA) BBB-CCCC
        return '+1 (${digits.substring(2, 5)}) ${digits.substring(5, 8)}-${digits.substring(8)}';
      }
      return digits;
    }

    // US 10-digit
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    // US 11-digit with leading 1
    if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }

    // Default: return as-is
    return raw;
  }

  /// Strip all formatting from a number, returning only digits and +.
  static String normalize(String number) =>
      number.replaceAll(RegExp(r'[^\d+]'), '');

  /// Check if two numbers refer to the same subscriber.
  static bool isSame(String a, String b) {
    final na = normalize(a);
    final nb = normalize(b);
    if (na == nb) return true;
    // Strip leading country code for comparison
    final sa = na.replaceFirst(RegExp(r'^(\+1|1)'), '');
    final sb = nb.replaceFirst(RegExp(r'^(\+1|1)'), '');
    return sa == sb && sa.length >= 7;
  }

  /// Return initials from a display name or number.
  static String initials(String nameOrNumber) {
    if (nameOrNumber.isEmpty) return '?';
    final parts = nameOrNumber.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (RegExp(r'^\d').hasMatch(nameOrNumber)) return '#';
    return nameOrNumber[0].toUpperCase();
  }
}
