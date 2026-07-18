enum MessageRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.isCommunityEstimate = false,
    this.isError = false,
    required this.timestamp,
  });

  final String id;
  final MessageRole role;
  final String content;
  final bool isCommunityEstimate;
  final bool isError;
  final DateTime timestamp;
}

class VoiceRouteResult {
  const VoiceRouteResult({
    required this.confirmedDestination,
    required this.spokenReply,
  });

  final String? confirmedDestination;
  final String spokenReply;
}
