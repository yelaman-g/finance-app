import 'dart:async';
import 'dart:convert';

import 'package:aifb/features/chat/data/dto/chat_message.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

// ── Abstract contract ─────────────────────────────────────────────────────────

/// Platform-agnostic STOMP/WS chat socket interface.
/// Tests can replace this with a fake implementation.
abstract class ChatSocket {
  /// Stream of incoming [ChatMessage] objects broadcast by the server.
  Stream<ChatMessage> get messages;

  /// Open the WebSocket connection and subscribe to the household topic.
  Future<void> connect();

  /// Send a text message to the server.
  void send(String text);

  /// Close the socket and release resources.
  Future<void> dispose();
}

// ── STOMP implementation ──────────────────────────────────────────────────────

/// Derives the WebSocket URL from the REST API base URL:
/// - strips `/api/v1` suffix
/// - swaps `https` → `wss` / `http` → `ws`
/// - appends `/ws`
///
/// Example: `https://host.example.com/api/v1` → `wss://host.example.com/ws`
String deriveWsUrl(String apiBaseUrl) {
  var url = apiBaseUrl;
  // Strip trailing /api/v1 (with or without trailing slash)
  final suffixRe = RegExp(r'/api/v1/?$');
  url = url.replaceFirst(suffixRe, '');
  // Swap scheme
  if (url.startsWith('https://')) {
    url = 'wss://${url.substring('https://'.length)}';
  } else if (url.startsWith('http://')) {
    url = 'ws://${url.substring('http://'.length)}';
  }
  return '$url/ws';
}

/// Production [ChatSocket] backed by `stomp_dart_client`.
class StompChatSocket implements ChatSocket {
  StompChatSocket({
    required String apiBaseUrl,
    required String token,
    required String householdId,
  })  : _wsUrl = deriveWsUrl(apiBaseUrl),
        _token = token,
        _householdId = householdId;

  final String _wsUrl;
  final String _token;
  final String _householdId;

  late StompClient _client;
  final _controller = StreamController<ChatMessage>.broadcast();
  final _connectedCompleter = Completer<void>();

  @override
  Stream<ChatMessage> get messages => _controller.stream;

  @override
  Future<void> connect() {
    _client = StompClient(
      config: StompConfig(
        url: _wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $_token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
        onConnect: _onConnect,
        onDisconnect: (_) {},
        onStompError: (frame) {
          if (!_connectedCompleter.isCompleted) {
            _connectedCompleter.completeError(
              Exception('STOMP error: ${frame.body}'),
            );
          }
        },
        onWebSocketError: (err) {
          if (!_connectedCompleter.isCompleted) {
            final error = err is Object
                ? err
                : Exception('WebSocket error');
            _connectedCompleter.completeError(error);
          }
        },
        // Reconnect every 5 s if the socket drops unexpectedly.
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client.activate();
    return _connectedCompleter.future;
  }

  void _onConnect(StompFrame frame) {
    _client.subscribe(
      destination: '/topic/household.$_householdId',
      callback: (f) {
        final body = f.body;
        if (body == null) return;
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          _controller.add(ChatMessage.fromJson(json));
        } catch (_) {
          // Malformed frame — skip silently.
        }
      },
    );
    if (!_connectedCompleter.isCompleted) {
      _connectedCompleter.complete();
    }
  }

  @override
  void send(String text) {
    _client.send(
      destination: '/app/chat.send',
      body: jsonEncode({'text': text}),
    );
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
    _client.deactivate();
  }
}
