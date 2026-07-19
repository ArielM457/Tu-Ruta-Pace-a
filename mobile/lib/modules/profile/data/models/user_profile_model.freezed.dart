// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint

part of 'user_profile_model.dart';

mixin _$UserProfileModel {
  String get id;
  String? get displayName;
  String? get phone;
  String get role;
  String get accessibilityProfile;
  String get defaultPriority;
  int get ayniPoints;
  bool get routeAlertsEnabled;
  bool get shareLocationWithFamily;
  String get createdAt;

  Map<String, dynamic> toJson();

  @override
  String toString() {
    return 'UserProfileModel(id: $id, displayName: $displayName, phone: $phone, role: $role, '
        'accessibilityProfile: $accessibilityProfile, defaultPriority: $defaultPriority, '
        'ayniPoints: $ayniPoints, routeAlertsEnabled: $routeAlertsEnabled, '
        'shareLocationWithFamily: $shareLocationWithFamily, createdAt: $createdAt)';
  }
}

class _UserProfileModel extends UserProfileModel {
  const _UserProfileModel({
    required this.id,
    this.displayName,
    this.phone,
    required this.role,
    required this.accessibilityProfile,
    required this.defaultPriority,
    required this.ayniPoints,
    required this.routeAlertsEnabled,
    required this.shareLocationWithFamily,
    required this.createdAt,
  }) : super._();

  factory _UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  @override
  final String id;
  @override
  final String? displayName;
  @override
  final String? phone;
  @override
  final String role;
  @override
  final String accessibilityProfile;
  @override
  final String defaultPriority;
  @override
  final int ayniPoints;
  @override
  final bool routeAlertsEnabled;
  @override
  final bool shareLocationWithFamily;
  @override
  final String createdAt;

  @override
  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UserProfileModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.accessibilityProfile, accessibilityProfile) ||
                other.accessibilityProfile == accessibilityProfile) &&
            (identical(other.defaultPriority, defaultPriority) ||
                other.defaultPriority == defaultPriority) &&
            (identical(other.ayniPoints, ayniPoints) ||
                other.ayniPoints == ayniPoints) &&
            (identical(other.routeAlertsEnabled, routeAlertsEnabled) ||
                other.routeAlertsEnabled == routeAlertsEnabled) &&
            (identical(
                    other.shareLocationWithFamily, shareLocationWithFamily) ||
                other.shareLocationWithFamily == shareLocationWithFamily) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      displayName,
      phone,
      role,
      accessibilityProfile,
      defaultPriority,
      ayniPoints,
      routeAlertsEnabled,
      shareLocationWithFamily,
      createdAt);
}
