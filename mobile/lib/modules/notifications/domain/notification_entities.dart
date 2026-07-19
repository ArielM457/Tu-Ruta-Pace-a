enum AppNotificationKind {
  incidentNearby,
  questionAnswered,
  complaintUpdated;

  String get emoji {
    switch (this) {
      case AppNotificationKind.incidentNearby:
        return '🚧';
      case AppNotificationKind.questionAnswered:
        return '💬';
      case AppNotificationKind.complaintUpdated:
        return '📋';
    }
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.createdAt,
  });

  final String id;
  final AppNotificationKind kind;
  final String title;
  final String subtitle;
  final DateTime createdAt;
}
