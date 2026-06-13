import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/theme_mode_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/push_remote_data_source.dart';
import '../../data/repositories/push_repository_impl.dart';
import '../../domain/repositories/push_repository.dart';

final pushRepositoryProvider = Provider<PushRepository>((ref) {
  return PushRepositoryImpl(PushRemoteDataSourceImpl(ref.watch(dioProvider)));
});

class NotifEnabledNotifier extends StateNotifier<bool> {
  NotifEnabledNotifier(this._prefs) : super(_prefs.getBool(_key) ?? true);
  static const _key = 'app.notif_enabled';
  final SharedPreferences _prefs;
  Future<void> set(bool v) async {
    state = v;
    await _prefs.setBool(_key, v);
  }
}

final notifEnabledProvider =
    StateNotifierProvider<NotifEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return NotifEnabledNotifier(prefs);
});
