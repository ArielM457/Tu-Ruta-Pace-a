enum UserRole {
  citizen('citizen'),
  government('government');

  const UserRole(this.apiValue);

  final String apiValue;

  static UserRole fromApi(String value) => UserRole.values.firstWhere(
        (role) => role.apiValue == value,
        orElse: () => UserRole.citizen,
      );
}

enum AccessibilityProfile {
  none('none'),
  visual('visual'),
  reducedMobility('reduced_mobility');

  const AccessibilityProfile(this.apiValue);

  final String apiValue;

  static AccessibilityProfile fromApi(String value) =>
      AccessibilityProfile.values.firstWhere(
        (profile) => profile.apiValue == value,
        orElse: () => AccessibilityProfile.none,
      );
}

enum TravelPriority {
  time('time'),
  cost('cost'),
  safety('safety');

  const TravelPriority(this.apiValue);

  final String apiValue;

  static TravelPriority fromApi(String value) =>
      TravelPriority.values.firstWhere(
        (priority) => priority.apiValue == value,
        orElse: () => TravelPriority.time,
      );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.role,
    required this.accessibilityProfile,
    required this.defaultPriority,
    required this.ayniPoints,
    required this.routeAlertsEnabled,
    required this.shareLocationWithFamily,
    required this.createdAt,
  });

  final String id;
  final String? displayName;
  final String? phone;
  final UserRole role;
  final AccessibilityProfile accessibilityProfile;
  final TravelPriority defaultPriority;
  final int ayniPoints;
  final bool routeAlertsEnabled;
  final bool shareLocationWithFamily;
  final DateTime createdAt;

  UserProfile copyWith({
    int? ayniPoints,
    bool? routeAlertsEnabled,
    bool? shareLocationWithFamily,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName,
      phone: phone,
      role: role,
      accessibilityProfile: accessibilityProfile,
      defaultPriority: defaultPriority,
      ayniPoints: ayniPoints ?? this.ayniPoints,
      routeAlertsEnabled: routeAlertsEnabled ?? this.routeAlertsEnabled,
      shareLocationWithFamily:
          shareLocationWithFamily ?? this.shareLocationWithFamily,
      createdAt: createdAt,
    );
  }
}
