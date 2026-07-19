import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/api/api_client.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/api_community_repository.dart';
import '../../domain/community_entities.dart';
import '../../domain/community_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => ApiCommunityRepository(ref.watch(apiClientProvider)),
);

final lineActivityProvider =
    FutureProvider.autoDispose.family<LineActivity, String>(
  (ref, lineId) => ref.read(communityRepositoryProvider).getLineActivity(lineId),
);

/// Questions that need help from the current user as a collaborator.
final pendingQuestionsProvider =
    AsyncNotifierProvider<PendingQuestionsNotifier, List<CommunityQuestion>>(
  PendingQuestionsNotifier.new,
);

class PendingQuestionsNotifier extends AsyncNotifier<List<CommunityQuestion>> {
  @override
  Future<List<CommunityQuestion>> build() {
    return ref.read(communityRepositoryProvider).getPendingQuestions();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(communityRepositoryProvider).getPendingQuestions(),
    );
  }

  void removeLocally(String questionId) {
    final current = state.value ?? [];
    state = AsyncData(current.where((q) => q.id != questionId).toList());
  }
}

/// Questions the current user has asked.
final myQuestionsProvider =
    AsyncNotifierProvider<MyQuestionsNotifier, List<CommunityQuestion>>(
  MyQuestionsNotifier.new,
);

class MyQuestionsNotifier extends AsyncNotifier<List<CommunityQuestion>> {
  @override
  Future<List<CommunityQuestion>> build() {
    return ref.read(communityRepositoryProvider).getMyQuestions();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(communityRepositoryProvider).getMyQuestions(),
    );
  }
}

/// Tracks whether the "someone needs help" popup was dismissed this
/// session, so it doesn't reappear until the app restarts (FR-004).
final helpPopupDismissedProvider = StateProvider<bool>((ref) => false);

class AskQuestionController extends AsyncNotifier<CommunityQuestion?> {
  @override
  Future<CommunityQuestion?> build() async => null;

  Future<bool> ask({
    required String lineId,
    required CommunityQuestionKind kind,
    String? content,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(communityRepositoryProvider).askQuestion(
            lineId: lineId,
            kind: kind,
            content: content,
          ),
    );
    if (!state.hasError) {
      ref.read(myQuestionsProvider.notifier).refresh();
    }
    return !state.hasError;
  }
}

final askQuestionControllerProvider =
    AsyncNotifierProvider<AskQuestionController, CommunityQuestion?>(
  AskQuestionController.new,
);

class AnswerQuestionController extends AsyncNotifier<AnswerQuestionResult?> {
  @override
  Future<AnswerQuestionResult?> build() async => null;

  Future<bool> answer(String questionId, String content) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(communityRepositoryProvider).answerQuestion(
            questionId,
            content: content,
          ),
    );
    final result = state.value;
    if (result != null) {
      ref.read(profileControllerProvider.notifier).applyAyniBalance(
            result.newBalance,
          );
      ref.read(pendingQuestionsProvider.notifier).removeLocally(questionId);
    }
    return !state.hasError;
  }
}

final answerQuestionControllerProvider =
    AsyncNotifierProvider<AnswerQuestionController, AnswerQuestionResult?>(
  AnswerQuestionController.new,
);
