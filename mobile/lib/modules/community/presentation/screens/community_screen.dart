import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/community_entities.dart';
import '../providers/community_providers.dart';
import '../widgets/community_badge_ui.dart';
import '../widgets/community_feed_tile.dart';
import '../widgets/question_answer_card.dart';
import '../widgets/ranking_member_tile.dart';

List<_HowItWorksItem> _howItWorksItemsFor(PointsConfig config) => [
      _HowItWorksItem(
        icon: Icons.location_on_outlined,
        label: 'Reporta bloqueos activos',
        points: '+${config.reportReward} pts',
      ),
      _HowItWorksItem(
        icon: Icons.check_circle_outline,
        label: 'Verifica reportes de otros',
        points: '+${config.verifyReward} pts',
      ),
      _HowItWorksItem(
        icon: Icons.groups_outlined,
        label: 'Responde preguntas',
        points: '+${config.answerReward} pts',
      ),
      _HowItWorksItem(
        icon: Icons.star_outline,
        label: 'Canjea para pedir ayuda',
        points: '−${config.askCost} pts',
      ),
    ];

class _HowItWorksItem {
  const _HowItWorksItem({
    required this.icon,
    required this.label,
    required this.points,
  });

  final IconData icon;
  final String label;
  final String points;
}

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).value;
    final rankingState = ref.watch(communityRankingProvider);
    final feedState = ref.watch(communityFeedProvider);
    final pendingState = ref.watch(pendingQuestionsProvider);
    final myQuestionsState = ref.watch(myQuestionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: ChasquiTopBar(
        title: 'Comunidad',
        subtitle: 'Ayuda y sé ayudado',
        onBack: () => context.pop(),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.refresh(communityRankingProvider.future),
          ref.refresh(communityFeedProvider.future),
          ref.read(pendingQuestionsProvider.notifier).refresh(),
          ref.read(myQuestionsProvider.notifier).refresh(),
        ]),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _MyPointsCard(
              displayName: profile?.displayName ?? 'Tú',
              points: profile?.ayniPoints ?? 0,
              rank: rankingState.value?.requester.rank,
            ),
            const SizedBox(height: 16),
            _HowItWorksCard(theme: theme),
            const SizedBox(height: 20),
            Text('RANKING SEMANAL', style: theme.textTheme.labelSmall),
            const SizedBox(height: 10),
            rankingState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(
                'No pudimos cargar el ranking.',
                style: theme.textTheme.bodySmall,
              ),
              data: (ranking) {
                if (ranking.top.isEmpty) {
                  return Text(
                    'Todavía nadie tiene actividad esta semana. ¡Sé el primero!',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return Column(
                  children: [
                    for (final entry in ranking.top) ...[
                      RankingMemberTile(
                        entry: entry,
                        position: entry.rank,
                        isMe: entry.userId == profile?.id,
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text('ACTIVIDAD RECIENTE', style: theme.textTheme.labelSmall),
            const SizedBox(height: 10),
            feedState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(
                'No pudimos cargar la actividad reciente.',
                style: theme.textTheme.bodySmall,
              ),
              data: (feed) {
                if (feed.isEmpty) {
                  return Text(
                    'Todavía no hay actividad reciente en la comunidad.',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return Column(
                  children: [
                    for (final entry in feed) ...[
                      CommunityFeedTile(entry: entry),
                      const SizedBox(height: 6),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Semantics(
              label: 'Canjear puntos para pedir ayuda',
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.go(AppRoutes.routes),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: ChasquiColors.yellow100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ChasquiColors.yellow400),
                  ),
                  child: const Text(
                    'Canjear puntos para pedir ayuda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: ChasquiColors.yellow800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('PREGUNTAS PENDIENTES PARA TI', style: theme.textTheme.labelSmall),
            const SizedBox(height: 10),
            pendingState.when(
              data: (questions) => questions.isEmpty
                  ? _EmptyPendingCard(theme: theme)
                  : Column(
                      children: [
                        for (final (i, q) in questions.indexed)
                          QuestionAnswerCard(question: q, index: i),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            Text('MIS PREGUNTAS', style: theme.textTheme.labelSmall),
            const SizedBox(height: 10),
            myQuestionsState.when(
              data: (questions) => questions.isEmpty
                  ? Text(
                      'Aún no has hecho preguntas a la comunidad.',
                      style: theme.textTheme.bodySmall,
                    )
                  : Column(
                      children: [
                        for (final q in questions) _MyQuestionTile(question: q),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyPointsCard extends StatelessWidget {
  const _MyPointsCard({
    required this.displayName,
    required this.points,
    required this.rank,
  });

  final String displayName;
  final int points;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChasquiColors.yellow200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChasquiColors.yellow400),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ChasquiColors.yellow600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              communityInitials(displayName),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: ChasquiColors.neutral950,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: ChasquiColors.neutral950,
                  ),
                ),
                Text(
                  rank != null
                      ? 'Posición #$rank en la comunidad'
                      : 'Aún sin actividad esta semana',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ChasquiColors.yellow800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: ChasquiColors.neutral950,
                ),
              ),
              const Text(
                'puntos',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ChasquiColors.yellow800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends ConsumerWidget {
  const _HowItWorksCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(pointsConfigProvider);
    return ChasquiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CÓMO FUNCIONA', style: theme.textTheme.labelSmall),
          const SizedBox(height: 12),
          if (configState.value == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            for (final item in _howItWorksItemsFor(configState.value!))
              Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(item.icon, size: 14, color: ChasquiColors.warm600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ChasquiColors.neutral700,
                      ),
                    ),
                  ),
                  Text(
                    item.points,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: item.points.startsWith('−')
                          ? ChasquiColors.orange600
                          : ChasquiColors.successText,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPendingCard extends StatelessWidget {
  const _EmptyPendingCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: ChasquiColors.neutral50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.self_improvement,
            size: 36,
            color: ChasquiColors.neutral300,
          ),
          const SizedBox(height: 10),
          Text(
            'Todo tranquilo — responderás cuando alguien lo necesite',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MyQuestionTile extends StatelessWidget {
  const _MyQuestionTile({required this.question});

  final CommunityQuestion question;

  Color _statusColor() {
    switch (question.status) {
      case CommunityQuestionStatus.open:
        return ChasquiColors.warm600;
      case CommunityQuestionStatus.answered:
        return ChasquiColors.successText;
      case CommunityQuestionStatus.expired:
        return ChasquiColors.neutral500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = question.answers.isNotEmpty ? question.answers.first : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChasquiColors.neutral100),
      ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            const SizedBox(height: 6),
            Text(
              answer.content,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
