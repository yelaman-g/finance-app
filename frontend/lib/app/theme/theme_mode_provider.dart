import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-selected theme mode, persisted to SharedPreferences.
/// Defaults to [ThemeMode.system].
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_decode(_prefs.getString(_key)));

  static const _key = 'app.theme_mode';
  final SharedPreferences _prefs;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }

  static ThemeMode _decode(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

/// Async-loaded preferences instance.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((_) {
  return SharedPreferences.getInstance();
});

/// Theme mode controller. Throws while prefs are loading; consumers should
/// gate on [sharedPreferencesProvider] (handled in `AifbApp`).
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return ThemeModeNotifier(prefs);
});
