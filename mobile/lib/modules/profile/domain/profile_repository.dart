import 'user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> bootstrap({String? displayName});

  Future<UserProfile> getMyProfile();

  Future<UserProfile> updateMyProfile({
    String? displayName,
    String? phone,
    AccessibilityProfile? accessibilityProfile,
    TravelPriority? defaultPriority,
    bool? routeAlertsEnabled,
    bool? shareLocationWithFamily,
  });

  Future<int> getPeopleHelpedCount();
}
