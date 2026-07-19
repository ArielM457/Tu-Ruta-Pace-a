import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/community_entities.dart';
import '../providers/collaboration_providers.dart';
import '../providers/community_providers.dart';
import '../widgets/ayni_movement_tile.dart';
import '../widgets/question_answer_card.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(
      profileControllerProvider.select((s) => s.value?.ayniPoints ?? 0),
    );
    final pendingState = ref.watch(pendingQuestionsProvider);
    final myQuestionsState = ref.watch(myQuestionsProvider);
    final historyState = ref.watch(ayniHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Comunidad Ayni'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(pendingQuestionsProvider.notifier).refresh(),
            ref.read(myQuestionsProvider.notifier).refresh(),
            ref.refresh(ayniHistoryProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBalanceCard(context, points),
            const Gap(28),
            _buildSectionTitle(context, 'Preguntas pendientes para ti'),
            const Gap(8),
            pendingState.when(
              data: (questions) => questions.isEmpty
                  ? _buildEmptyPending(context)
                  : Column(
                      children: [
                        for (final (i, q) in questions.indexed)
                          QuestionAnswerCard(question: q, index: i),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Gap(24),
            _buildSectionTitle(context, 'Mis preguntas'),
            const Gap(8),
            myQuestionsState.when(
              data: (questions) => questions.isEmpty
                  ? Text(
                      'Aún no has hecho preguntas a la comunidad.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : Column(
                      children: [
                        for (final q in questions) _MyQuestionTile(question: q),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Gap(24),
            _buildSectionTitle(context, 'Historial de puntos'),
            const Gap(8),
            historyState.when(
              data: (page) => page.movements.isEmpty
                  ? Text(
                      'Todavía no tienes movimientos de puntos Ayni.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : Card(
                      child: Column(
                        children: [
                          for (final (i, m) in page.movements.indexed)
                            AyniMovementTile(movement: m, index: i),
                        ],
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildEmptyPending(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.self_improvement, size: 40, color: Colors.grey[400]),
          const Gap(10),
          Text(
            'Todo tranquilo — responderás cuando alguien lo necesite',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, int points) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[700]!, Colors.indigo[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.hexagon, color: Color(0xFFFFD54F), size: 32),
          const Gap(8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: points),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Text(
              '$value',
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Gap(4),
          const Text(
            'puntos Ayni',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scaleXY(begin: 0.95, curve: Curves.easeOut);
  }
}

class _MyQuestionTile extends StatelessWidget {
  const _MyQuestionTile({required this.question});

  final CommunityQuestion question;

  Color _statusColor() {
    switch (question.status) {
      case CommunityQuestionStatus.open:
        return const Color(0xFFF57C00);
      case CommunityQuestionStatus.answered:
        return const Color(0xFF2E7D32);
      case CommunityQuestionStatus.expired:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = question.answers.isNotEmpty ? question.answers.first : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${question.kind.emoji} ${question.lineName ?? question.kind.label}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question.status.label,
                    style: TextStyle(
                      color: _statusColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (answer != null) ...[
              const Gap(6),
              Text(
                answer.content,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
