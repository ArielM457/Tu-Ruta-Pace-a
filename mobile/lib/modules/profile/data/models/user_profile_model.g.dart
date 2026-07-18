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
      role: json['role'] as String,
      accessibilityProfile: json['accessibilityProfile'] as String,
      defaultPriority: json['defaultPriority'] as String,
      ayniPoints: (json['ayniPoints'] as num).toInt(),
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$UserProfileModelToJson(_UserProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'role': instance.role,
      'accessibilityProfile': instance.accessibilityProfile,
      'defaultPriority': instance.defaultPriority,
      'ayniPoints': instance.ayniPoints,
      'createdAt': instance.createdAt,
    };
