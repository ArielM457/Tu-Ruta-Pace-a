import 'user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> bootstrap({String? displayName});

  Future<UserProfile> getMyProfile();

  Future<UserProfile> updateMyProfile({
    String? displayName,
    AccessibilityProfile? accessibilityProfile,
    TravelPriority? defaultPriority,
  });
}
