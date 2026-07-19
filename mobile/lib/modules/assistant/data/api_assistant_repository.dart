import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/types/coordinate.dart';
import '../domain/assistant_repository.dart';
import '../domain/chat_entities.dart';

const Duration _chatTimeout = Duration(seconds: 30);

class ApiAssistantRepository implements AssistantRepository {
  const ApiAssistantRepository(this._dio);

  final Dio _dio;

  @override
  Future<ChatReply> sendChat(String message, {Coordinate? location}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/assistant/chat',
        data: {
          'message': message,
          if (location != null) 'location': location.toJson(),
        },
        options: Options(sendTimeout: _chatTimeout, receiveTimeout: _chatTimeout),
      );
      final data = response.data as Map<String, dynamic>;
      return ChatReply(
        reply: data['reply'] as String,
        isCommunityEstimate: data['isCommunityEstimate'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<VoiceRouteResult> requestVoiceRoute(
    String transcript, {
    Coordinate? location,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/assistant/voice-route',
        data: {
          'transcript': transcript,
          if (location != null) 'location': location.toJson(),
        },
        options: Options(sendTimeout: _chatTimeout, receiveTimeout: _chatTimeout),
      );
      final data = response.data as Map<String, dynamic>;
      return VoiceRouteResult(
        confirmedDestination: data['confirmedDestination'] as String?,
        spokenReply: data['spokenReply'] as String,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
