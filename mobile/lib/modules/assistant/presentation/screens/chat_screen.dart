import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
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
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Buscar en mapa',
          textColor: ChasquiColors.yellow500,
          onPressed: () {
            ref.read(routeRequestProvider.notifier).clearDestination();
            context.push(AppRoutes.map);
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
      backgroundColor: Colors.white,
      appBar: _ChaskiHeader(onVoiceRoute: _startVoiceRoute),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PREGUNTAS FRECUENTES',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ChasquiColors.yellow200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 30,
                color: ChasquiColors.yellow800,
              ),
            ),
            const Gap(16),
            Text(
              'Hola, soy Chaski. Puedo ayudarte a encontrar rutas, resolver dudas sobre tarifas y más.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ChasquiColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(VoiceInputStatus voiceStatus) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ChasquiColors.neutral100)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_) => _sendText(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu pregunta...',
                  ),
                ),
              ),
              const Gap(8),
              MicButton(
                status: voiceStatus,
                onStartListening: _startListening,
                onStopListening: _stopListening,
              ),
              const Gap(8),
              Semantics(
                label: 'Enviar mensaje',
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _sendText,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ChasquiColors.yellow600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: ChasquiColors.neutral950,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChaskiHeader extends StatelessWidget implements PreferredSizeWidget {
  const _ChaskiHeader({required this.onVoiceRoute});

  final VoidCallback onVoiceRoute;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ChasquiColors.neutral100)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Semantics(
                  label: 'Volver',
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ChasquiColors.neutral50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: ChasquiColors.neutral900,
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: ChasquiColors.yellow600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: ChasquiColors.neutral950,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chaski',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ChasquiColors.neutral950,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: ChasquiColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(4),
                          const Text(
                            'En línea',
                            style: TextStyle(
                              fontSize: 10,
                              color: ChasquiColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pedir ruta por voz',
                  icon: const Icon(
                    Icons.assistant_navigation,
                    color: ChasquiColors.neutral700,
                  ),
                  onPressed: onVoiceRoute,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
