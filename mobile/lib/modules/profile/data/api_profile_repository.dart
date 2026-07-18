import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';
import 'models/user_profile_model.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._apiClient);

  final Dio _apiClient;

  @override
  Future<UserProfile> bootstrap({String? displayName}) {
    return _requestProfile(
      () => _apiClient.post<dynamic>(
        '/users/me/bootstrap',
        data: {if (displayName != null) 'displayName': displayName},
      ),
    );
  }

  @override
  Future<UserProfile> getMyProfile() {
    return _requestProfile(() => _apiClient.get<dynamic>('/users/me'));
  }

  @override
  Future<UserProfile> updateMyProfile({
    String? displayName,
    AccessibilityProfile? accessibilityProfile,
    TravelPriority? defaultPriority,
  }) {
    return _requestProfile(
      () => _apiClient.patch<dynamic>(
        '/users/me',
        data: {
          if (displayName != null) 'displayName': displayName,
          if (accessibilityProfile != null)
            'accessibilityProfile': accessibilityProfile.apiValue,
          if (defaultPriority != null)
            'defaultPriority': defaultPriority.apiValue,
        },
      ),
    );
  }

  Future<UserProfile> _requestProfile(
    Future<Response<dynamic>> Function() sendRequest,
  ) async {
    try {
      final response = await sendRequest();
      return UserProfileModel.fromJson(response.data as Map<String, dynamic>)
          .toEntity();
    } on DioException catch (exception) {
      throw toApiException(exception);
    }
  }
}
