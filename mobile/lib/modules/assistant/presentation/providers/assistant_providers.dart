import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/location/location_providers.dart';
import '../../data/api_assistant_repository.dart';
import '../../domain/assistant_repository.dart';
import '../../domain/chat_entities.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => ApiAssistantRepository(ref.watch(apiClientProvider)),
);

final flutterTtsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  tts.setLanguage('es-BO');
  tts.setSpeechRate(0.48);
  ref.onDispose(() => tts.stop());
  return tts;
});

final speechToTextProvider = Provider<stt.SpeechToText>((ref) {
  return stt.SpeechToText();
});

int _messageCounter = 0;
String _nextMessageId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${_messageCounter++}';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isTyping = false,
  });

  final List<ChatMessage> messages;
  final bool isTyping;

  ChatState copyWith({List<ChatMessage>? messages, bool? isTyping}) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> sendMessage(String text, {bool speakReply = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = ChatMessage(
      id: _nextMessageId(),
      role: MessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    try {
      final location = ref.read(currentPositionProvider).value;
      final repo = ref.read(assistantRepositoryProvider);
      final reply = await repo.sendChat(trimmed, location: location);

      final assistantMessage = ChatMessage(
        id: _nextMessageId(),
        role: MessageRole.assistant,
        content: reply.reply,
        isCommunityEstimate: reply.isCommunityEstimate,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isTyping: false,
      );

      if (speakReply) {
        final tts = ref.read(flutterTtsProvider);
        await tts.speak(reply.reply);
      }
    } catch (e) {
      final errorText = e is ApiException
          ? 'El asistente no está disponible ahora. Intenta en unos minutos.'
          : 'El asistente no está disponible ahora. Intenta en unos minutos.';
      final errorMessage = ChatMessage(
        id: _nextMessageId(),
        role: MessageRole.assistant,
        content: errorText,
        isError: true,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isTyping: false,
      );
    }
  }

  /// Sends a voice command specifically for route requests (HU-5.1).
  /// Returns the confirmed destination name, or null if the agent
  /// couldn't understand the destination.
  Future<String?> sendVoiceRoute(String transcript) async {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty) return null;

    final userMessage = ChatMessage(
      id: _nextMessageId(),
      role: MessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    try {
      final location = ref.read(currentPositionProvider).value;
      final repo = ref.read(assistantRepositoryProvider);
      final result = await repo.requestVoiceRoute(trimmed, location: location);

      final assistantMessage = ChatMessage(
        id: _nextMessageId(),
        role: MessageRole.assistant,
        content: result.spokenReply,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isTyping: false,
      );

      final tts = ref.read(flutterTtsProvider);
      await tts.speak(result.spokenReply);

      return result.confirmedDestination;
    } catch (e) {
      const errorText =
          'El asistente no está disponible ahora. Intenta en unos minutos.';
      final errorMessage = ChatMessage(
        id: _nextMessageId(),
        role: MessageRole.assistant,
        content: errorText,
        isError: true,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isTyping: false,
      );
      return null;
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

// ── Voice input state machine ──────────────────────────────────────────────

enum VoiceInputStatus { idle, listening, processing, deniedPermission }

class VoiceInputNotifier extends Notifier<VoiceInputStatus> {
  @override
  VoiceInputStatus build() => VoiceInputStatus.idle;

  Future<String?> startListening() async {
    final speech = ref.read(speechToTextProvider);
    final available = await speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (state == VoiceInputStatus.listening) {
            state = VoiceInputStatus.processing;
          }
        }
      },
      onError: (_) => state = VoiceInputStatus.deniedPermission,
    );
    if (!available) {
      state = VoiceInputStatus.deniedPermission;
      return null;
    }

    state = VoiceInputStatus.listening;
    String finalText = '';
    await speech.listen(
      localeId: 'es_BO',
      onResult: (result) {
        finalText = result.recognizedWords;
      },
    );
    return finalText;
  }

  Future<String> stopListening() async {
    final speech = ref.read(speechToTextProvider);
    final lastWords = speech.lastRecognizedWords;
    await speech.stop();
    state = VoiceInputStatus.idle;
    return lastWords;
  }

  void reset() => state = VoiceInputStatus.idle;
}

final voiceInputProvider =
    NotifierProvider<VoiceInputNotifier, VoiceInputStatus>(
  VoiceInputNotifier.new,
);
