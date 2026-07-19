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
    String? phone,
    AccessibilityProfile? accessibilityProfile,
    TravelPriority? defaultPriority,
    bool? routeAlertsEnabled,
    bool? shareLocationWithFamily,
  }) {
    return _requestProfile(
      () => _apiClient.patch<dynamic>(
        '/users/me',
        data: {
          if (displayName != null) 'displayName': displayName,
          if (phone != null) 'phone': phone,
          if (accessibilityProfile != null)
            'accessibilityProfile': accessibilityProfile.apiValue,
          if (defaultPriority != null)
            'defaultPriority': defaultPriority.apiValue,
          if (routeAlertsEnabled != null)
            'routeAlertsEnabled': routeAlertsEnabled,
          if (shareLocationWithFamily != null)
            'shareLocationWithFamily': shareLocationWithFamily,
        },
      ),
    );
  }

  @override
  Future<int> getPeopleHelpedCount() async {
    try {
      final response =
          await _apiClient.get<dynamic>('/users/me/help-stats');
      final body = response.data as Map<String, dynamic>;
      return body['peopleHelped'] as int;
    } on DioException catch (exception) {
      throw toApiException(exception);
    }
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
