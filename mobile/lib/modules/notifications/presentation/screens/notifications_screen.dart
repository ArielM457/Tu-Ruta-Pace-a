import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/notification_entities.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);

    ref.listen(notificationsProvider, (previous, next) {
      final notifications = next.value;
      if (notifications != null && notifications.isNotEmpty) {
        ref
            .read(seenNotificationIdsProvider.notifier)
            .markSeen(notifications.map((n) => n.id));
      }
    });

    return Scaffold(
      appBar: ChasquiTopBar(
        title: 'Notificaciones',
        onBack: () => context.pop(),
      ),
      body: notificationsState.when(
        loading: () => const LoadingView(message: 'Cargando notificaciones…'),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 80),
                Icon(
                  Icons.notifications_none_rounded,
                  size: 48,
                  color: ChasquiColors.neutral300,
                ),
                SizedBox(height: 12),
                Text(
                  'No tienes notificaciones por ahora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ChasquiColors.neutral500),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _NotificationTile(notification: notifications[index]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  Color get _accentColor {
    switch (notification.kind) {
      case AppNotificationKind.incidentNearby:
        return ChasquiColors.orange600;
      case AppNotificationKind.questionAnswered:
        return ChasquiColors.yellow600;
      case AppNotificationKind.complaintUpdated:
        return ChasquiColors.neutral700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${notification.title}. ${notification.subtitle}',
      child: ChasquiCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notification.kind.emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ChasquiColors.neutral950,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ChasquiColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
