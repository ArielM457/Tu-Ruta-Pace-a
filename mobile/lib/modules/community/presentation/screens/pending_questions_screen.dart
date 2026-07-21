import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/error_view.dart';
import '../providers/community_providers.dart';
import '../widgets/question_answer_card.dart';

class PendingQuestionsScreen extends ConsumerWidget {
  const PendingQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingState = ref.watch(pendingQuestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda a la comunidad'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
      ),
      body: pendingState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(pendingQuestionsProvider.notifier).refresh(),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.self_improvement, size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay preguntas pendientes por ahora',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(pendingQuestionsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) => QuestionAnswerCard(
                question: questions[index],
                index: index,
              ),
            ),
          );
        },
      ),
    );
  }
}
