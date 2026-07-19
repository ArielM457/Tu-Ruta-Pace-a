// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) =>
    _UserProfileModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      accessibilityProfile: json['accessibilityProfile'] as String,
      defaultPriority: json['defaultPriority'] as String,
      ayniPoints: (json['ayniPoints'] as num).toInt(),
      routeAlertsEnabled: json['routeAlertsEnabled'] as bool,
      shareLocationWithFamily: json['shareLocationWithFamily'] as bool,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$UserProfileModelToJson(_UserProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'phone': instance.phone,
      'role': instance.role,
      'accessibilityProfile': instance.accessibilityProfile,
      'defaultPriority': instance.defaultPriority,
      'ayniPoints': instance.ayniPoints,
      'routeAlertsEnabled': instance.routeAlertsEnabled,
      'shareLocationWithFamily': instance.shareLocationWithFamily,
      'createdAt': instance.createdAt,
    };
