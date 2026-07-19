import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../domain/family_entities.dart';
import '../domain/family_repository.dart';

class ApiFamilyRepository implements FamilyRepository {
  const ApiFamilyRepository(this._apiClient);

  final Dio _apiClient;

  @override
  Future<FamilyGroup?> getMyGroup() async {
    try {
      final response = await _apiClient.get<dynamic>('/family/groups/me');
      if (response.data == null) return null;
      return FamilyGroup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<FamilyGroup> createGroup(String name) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/family/groups',
        data: {'name': name},
      );
      return FamilyGroup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<FamilyInvite> inviteMember({
    String? email,
    String? relationshipLabel,
  }) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/family/invitations',
        data: {
          if (email != null) 'email': email,
          if (relationshipLabel != null) 'relationshipLabel': relationshipLabel,
        },
      );
      return FamilyInvite.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<FamilyGroup> acceptInvitation(String code) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/family/invitations/accept',
        data: {'code': code},
      );
      return FamilyGroup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
