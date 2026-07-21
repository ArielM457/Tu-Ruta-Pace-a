import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../complaints/domain/complaint_entities.dart';
import '../../../complaints/presentation/providers/complaints_providers.dart';
import '../../../community/domain/community_entities.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../incidents/domain/incident_entities.dart';
import '../../../incidents/presentation/providers/incident_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/notification_seen_store.dart';
import '../../domain/notification_entities.dart';

final notificationSeenStoreProvider = Provider<NotificationSeenStore>(
  (ref) => NotificationSeenStore(),
);

final seenNotificationIdsProvider =
    AsyncNotifierProvider<SeenNotificationIdsNotifier, Set<String>>(
  SeenNotificationIdsNotifier.new,
);

class SeenNotificationIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.read(notificationSeenStoreProvider).load();
  }

  Future<void> markSeen(Iterable<String> ids) async {
    final current = state.value ?? <String>{};
    final updated = {...current, ...ids};
    state = AsyncData(updated);
    await ref.read(notificationSeenStoreProvider).save(updated);
  }
}

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) async {
    final profile = await ref.watch(profileControllerProvider.future);

    final results = await Future.wait([
      if (profile.routeAlertsEnabled)
        ref.watch(citywideActiveIncidentsProvider.future)
      else
        Future.value(<Incident>[]),
      ref.watch(myQuestionsProvider.future),
      ref.watch(myComplaintsProvider.future),
    ]);

    final incidents = results[0] as List<Incident>;
    final questions = results[1] as List<CommunityQuestion>;
    final complaints = results[2] as List<Complaint>;

    final notifications = <AppNotification>[
      for (final incident in incidents)
        AppNotification(
          id: 'incident:${incident.id}',
          kind: AppNotificationKind.incidentNearby,
          title: '${incident.kind.label} activo',
          subtitle: incident.description,
          createdAt: DateTime.parse(incident.createdAt),
        ),
      for (final question in questions)
        if (question.status == CommunityQuestionStatus.answered &&
            question.answeredAt != null)
          AppNotification(
            id: 'question:${question.id}',
            kind: AppNotificationKind.questionAnswered,
            title: 'Respondieron tu pregunta',
            subtitle: question.lineName != null
                ? '${question.kind.label} · ${question.lineName}'
                : question.kind.label,
            createdAt: DateTime.parse(question.answeredAt!),
          ),
      for (final complaint in complaints)
        if (complaint.status != ComplaintStatus.inReview)
          AppNotification(
            id: 'complaint:${complaint.id}',
            kind: AppNotificationKind.complaintUpdated,
            title: complaint.status == ComplaintStatus.resolved
                ? 'Tu denuncia fue resuelta'
                : 'Tu denuncia fue cerrada',
            subtitle: complaint.routeLabel ?? complaint.complaint,
            createdAt: complaint.createdAt,
          ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notifications;
  },
);

final unseenNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  final seenIds = ref.watch(seenNotificationIdsProvider).value ?? <String>{};
  return notifications.where((n) => !seenIds.contains(n.id)).length;
});
