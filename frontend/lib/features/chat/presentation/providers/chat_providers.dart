import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/core/storage/secure_storage.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/features/chat/data/chat_socket.dart';
import 'package:aifb/features/chat/data/data_sources/chat_remote_data_source.dart';
import 'package:aifb/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:aifb/features/chat/domain/repositories/chat_repository.dart';
import 'package:aifb/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/controllers/auth_controller.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    ChatRemoteDataSourceImpl(ref.watch(dioProvider)),
  );
});

// ── Token helper ──────────────────────────────────────────────────────────────

/// Reads the raw JWT access token from secure storage.
/// Returns null when not authenticated.
final _accessTokenProvider = FutureProvider.autoDispose<String?>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) return null;
  return ref.watch(secureStorageProvider).readAccess();
});

// ── ChatSocket provider ───────────────────────────────────────────────────────

/// A connected [ChatSocket] for the current user's household.
///
/// Returns null when:
///   - the user is not authenticated,
///   - the token is missing, or
///   - the user has no household.
///
/// Tests can override [chatSocketProvider] with a fake [ChatSocket].
final chatSocketProvider =
    FutureProvider.autoDispose<ChatSocket?>((ref) async {
  // 1. Token
  final tokenAsync = await ref.watch(_accessTokenProvider.future);
  if (tokenAsync == null) return null;

  // 2. Household
  final household = await ref.watch(myHouseholdProvider.future);
  if (household == null) return null;

  // 3. WS URL from env
  final apiBase = dotenv.isInitialized
      ? (dotenv.env['API_BASE_URL'] ?? 'http://localhost:9090/api/v1')
      : 'http://localhost:9090/api/v1';

  final socket = StompChatSocket(
    apiBaseUrl: apiBase,
    token: tokenAsync,
    householdId: household.id,
  );

  // Connect before handing back the socket.
  await socket.connect();

  // Dispose the socket when the provider is no longer watched.
  ref.onDispose(socket.dispose);

  return socket;
});
