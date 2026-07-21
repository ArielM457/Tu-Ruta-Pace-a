import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../data/api_profile_repository.dart';
import '../../domain/profile_repository.dart';
import '../../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ApiProfileRepository(ref.watch(apiClientProvider)),
);

final peopleHelpedCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.read(profileRepositoryProvider).getPeopleHelpedCount(),
);

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() {
    return ref.watch(profileRepositoryProvider).getMyProfile();
  }

  Future<bool> updatePreferences({
    String? displayName,
    String? phone,
    AccessibilityProfile? accessibilityProfile,
    TravelPriority? defaultPriority,
    bool? routeAlertsEnabled,
    bool? shareLocationWithFamily,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updateMyProfile(
            displayName: displayName,
            phone: phone,
            accessibilityProfile: accessibilityProfile,
            defaultPriority: defaultPriority,
            routeAlertsEnabled: routeAlertsEnabled,
            shareLocationWithFamily: shareLocationWithFamily,
          ),
    );
    return !state.hasError;
  }

  void applyAyniBalance(int balance) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(ayniPoints: balance));
    }
  }
}
