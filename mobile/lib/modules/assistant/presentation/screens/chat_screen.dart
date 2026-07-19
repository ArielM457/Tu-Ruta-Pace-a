import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../routing/presentation/providers/routing_providers.dart';
import '../providers/assistant_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/faq_chips.dart';
import '../widgets/mic_button.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _voiceRouteMode = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendText() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _sendFaq(String question) async {
    await ref.read(chatProvider.notifier).sendMessage(question);
    _scrollToBottom();
  }

  Future<void> _startListening() async {
    _voiceRouteMode = false;
    await ref.read(voiceInputProvider.notifier).startListening();
  }

  Future<void> _stopListening() async {
    final transcript = await ref.read(voiceInputProvider.notifier).stopListening();
    if (transcript.trim().isEmpty) return;

    if (_voiceRouteMode) {
      final destination = await ref.read(chatProvider.notifier).sendVoiceRoute(transcript);
      _scrollToBottom();
      if (destination != null && mounted) {
        _showDestinationConfirmation(destination);
      }
    } else {
      _textController.text = transcript;
      await ref.read(chatProvider.notifier).sendMessage(transcript, speakReply: true);
      _scrollToBottom();
    }
  }

  void _showDestinationConfirmation(String destinationName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Destino entendido: $destinationName'),
        backgroundColor: Colors.indigo[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Buscar en mapa',
          textColor: Colors.amberAccent,
          onPressed: () {
            ref.read(routeRequestProvider.notifier).clearDestination();
            context.go(AppRoutes.home);
          },
        ),
      ),
    );
  }

  Future<void> _startVoiceRoute() async {
    _voiceRouteMode = true;
    await ref.read(voiceInputProvider.notifier).startListening();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mantén presionado el micrófono y di tu destino'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final voiceStatus = ref.watch(voiceInputProvider);
    final theme = Theme.of(context);

    ref.listen(voiceInputProvider, (previous, next) {
      if (next == VoiceInputStatus.deniedPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Necesitas dar permiso al micrófono'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final hasMessages = chatState.messages.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy_outlined),
            const Gap(8),
            const Text('Asistente Ayni'),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'IA · GPT-5',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo[700],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pedir ruta por voz',
            icon: const Icon(Icons.assistant_navigation),
            onPressed: _startVoiceRoute,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: hasMessages
                ? ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount:
                        chatState.messages.length + (chatState.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length) {
                        return const TypingIndicator();
                      }
                      return ChatBubble(message: chatState.messages[index]);
                    },
                  )
                : _buildEmptyState(theme),
          ),
          if (!hasMessages) ...[
            FaqChips(onSelect: _sendFaq),
            const Gap(12),
          ],
          _buildInputRow(voiceStatus),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: Colors.indigo[100]),
            const Gap(16),
            Text(
              'Pregúntame sobre transporte,\nrutas o cómo usar la app',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(VoiceInputStatus voiceStatus) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _sendText(),
                decoration: InputDecoration(
                  hintText: 'Pregunta algo...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Gap(8),
            MicButton(
              status: voiceStatus,
              onStartListening: _startListening,
              onStopListening: _stopListening,
            ),
            const Gap(6),
            IconButton(
              icon: const Icon(Icons.send),
              color: Colors.indigo[700],
              onPressed: _sendText,
            ),
          ],
        ),
      ),
    );
  }
}
