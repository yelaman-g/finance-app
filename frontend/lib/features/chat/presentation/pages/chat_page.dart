import 'dart:async';

import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/features/chat/data/dto/chat_message.dart';
import 'package:aifb/features/chat/domain/repositories/chat_repository.dart';
import 'package:aifb/features/chat/presentation/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messages = <ChatMessage>[];
  final _seen = <String>{};
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _historyLoading = true;
  String? _historyError;
  StreamSubscription<ChatMessage>? _sub;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _attachSocket();
  }

  Future<void> _loadHistory() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final msgs = await repo.history();
      if (!mounted) return;
      setState(() {
        for (final m in msgs) {
          if (_seen.add(m.id)) _messages.add(m);
        }
        _historyLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = 'Не удалось загрузить историю: $e';
        _historyLoading = false;
      });
    }
  }

  void _attachSocket() {
    // We listen to the socketProvider and re-attach whenever it resolves.
    ref.listenManual(chatSocketProvider, (_, next) {
      next.whenData((socket) {
        _sub?.cancel();
        if (socket == null) return;
        _sub = socket.messages.listen((msg) {
          if (!mounted) return;
          if (_seen.add(msg.id)) {
            setState(() => _messages.add(msg));
            _scrollToBottom();
          }
        });
      });
    }, fireImmediately: true);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final socketAsync = ref.read(chatSocketProvider);
    socketAsync.whenData((socket) => socket?.send(text));
    _controller.clear();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final currentUserId =
        auth is AuthAuthenticated ? auth.user.id : '';
    final socketAsync = ref.watch(chatSocketProvider);

    // No household
    if (socketAsync.hasValue && socketAsync.value == null && !_historyLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Семейный чат')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Создайте/вступите в семью, чтобы общаться',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Семейный чат'),
        actions: [
          if (socketAsync.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(currentUserId)),
          _buildInput(socketAsync.value),
        ],
      ),
    );
  }

  Widget _buildBody(String currentUserId) {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyError != null) {
      return Center(child: Text(_historyError!));
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text('Нет сообщений. Напишите первым!'),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) =>
          _MessageBubble(msg: _messages[i], isMe: _messages[i].senderId == currentUserId),
    );
  }

  Widget _buildInput(dynamic socket) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Сообщение…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded),
              tooltip: 'Отправить',
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.isMe});

  final ChatMessage msg;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('HH:mm').format(msg.createdAt.toLocal());
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isMe
                      ? cs.onPrimary.withOpacity(0.8)
                      : cs.onSurfaceVariant,
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 11,
                color: isMe
                    ? cs.onPrimary.withOpacity(0.7)
                    : cs.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
