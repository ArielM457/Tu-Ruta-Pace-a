import '../../../core/types/coordinate.dart';
import 'chat_entities.dart';

class ChatReply {
  const ChatReply({required this.reply, required this.isCommunityEstimate});

  final String reply;
  final bool isCommunityEstimate;
}

abstract class AssistantRepository {
  Future<ChatReply> sendChat(String message, {Coordinate? location});
  Future<VoiceRouteResult> requestVoiceRoute(
    String transcript, {
    Coordinate? location,
  });
}
