import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adapter that lets `GoRouter.refreshListenable` react to a Riverpod
/// provider stream. Used by router redirects (e.g., auth state changes).
class RouterRefreshNotifier<T> extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref, ProviderListenable<T> provider) {
    _sub = ref.listen<T>(provider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription<T> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
