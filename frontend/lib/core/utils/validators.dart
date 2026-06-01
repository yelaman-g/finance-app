/// Pure validators. Return null when valid, or a localized-ready message key
/// when invalid. UI maps these to user-facing copy.
class Validators {
  Validators._();

  static final _emailRe = RegExp(
    r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$",
  );

  static String? email(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRe.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? raw) {
    final v = raw ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) return 'Add a letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Add a number';
    return null;
  }

  static String? confirmPassword(String? raw, String original) {
    if (raw != original) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  static String? code(String? raw, {int length = 6}) {
    final v = raw?.trim() ?? '';
    if (v.length != length) return 'Enter $length-digit code';
    if (!RegExp(r'^\d+$').hasMatch(v)) return 'Digits only';
    return null;
  }
}
