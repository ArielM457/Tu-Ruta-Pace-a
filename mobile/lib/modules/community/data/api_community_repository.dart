import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../domain/community_entities.dart';
import '../domain/community_repository.dart';

class ApiCommunityRepository implements CommunityRepository {
  const ApiCommunityRepository(this._dio);

  final Dio _dio;

  @override
  Future<LineActivity> getLineActivity(String lineId) async {
    try {
      final response =
          await _dio.get<dynamic>('/community/lines/$lineId/activity');
      return LineActivity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CommunityQuestion> askQuestion({
    required String lineId,
    required CommunityQuestionKind kind,
    String? content,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/community/questions',
        data: {
          'lineId': lineId,
          'kind': kind.apiValue,
          if (content != null && content.isNotEmpty) 'content': content,
        },
      );
      return CommunityQuestion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<List<CommunityQuestion>> getMyQuestions() async {
    try {
      final response = await _dio.get<dynamic>('/community/questions/mine');
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CommunityQuestion.fromJson)
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<List<CommunityQuestion>> getPendingQuestions() async {
    try {
      final response =
          await _dio.get<dynamic>('/community/questions/pending');
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CommunityQuestion.fromJson)
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<AnswerQuestionResult> answerQuestion(
    String questionId, {
    required String content,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/community/questions/$questionId/answers',
        data: {'content': content},
      );
      return AnswerQuestionResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CommunityRanking> getRanking() async {
    try {
      final response = await _dio.get<dynamic>(
        '/community/ranking',
        queryParameters: {'period': 'week'},
      );
      return CommunityRanking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<List<CommunityFeedEntry>> getFeed() async {
    try {
      final response = await _dio.get<dynamic>('/community/feed');
      return (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CommunityFeedEntry.fromJson)
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<PointsConfig> getPointsConfig() async {
    try {
      final response = await _dio.get<dynamic>('/community/points-config');
      return PointsConfig.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
