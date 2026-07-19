import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/user_profile.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
abstract class UserProfileModel with _$UserProfileModel {
  const UserProfileModel._();

  const factory UserProfileModel({
    required String id,
    String? displayName,
    String? phone,
    required String role,
    required String accessibilityProfile,
    required String defaultPriority,
    required int ayniPoints,
    required bool routeAlertsEnabled,
    required bool shareLocationWithFamily,
    required String createdAt,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  UserProfile toEntity() => UserProfile(
        id: id,
        displayName: displayName,
        phone: phone,
        role: UserRole.fromApi(role),
        accessibilityProfile: AccessibilityProfile.fromApi(accessibilityProfile),
        defaultPriority: TravelPriority.fromApi(defaultPriority),
        ayniPoints: ayniPoints,
        routeAlertsEnabled: routeAlertsEnabled,
        shareLocationWithFamily: shareLocationWithFamily,
        createdAt: DateTime.parse(createdAt),
      );
}
