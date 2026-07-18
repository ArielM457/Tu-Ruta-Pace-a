import 'community_entities.dart';

abstract class CommunityRepository {
  Future<LineActivity> getLineActivity(String lineId);

  Future<CommunityQuestion> askQuestion({
    required String lineId,
    required CommunityQuestionKind kind,
    String? content,
  });

  Future<List<CommunityQuestion>> getMyQuestions();

  Future<List<CommunityQuestion>> getPendingQuestions();

  Future<AnswerQuestionResult> answerQuestion(
    String questionId, {
    required String content,
  });
}
