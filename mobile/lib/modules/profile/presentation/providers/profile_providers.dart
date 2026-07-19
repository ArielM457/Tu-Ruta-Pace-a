import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../data/api_profile_repository.dart';
import '../../domain/profile_repository.dart';
import '../../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ApiProfileRepository(ref.watch(apiClientProvider)),
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
    AccessibilityProfile? accessibilityProfile,
    TravelPriority? defaultPriority,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updateMyProfile(
            displayName: displayName,
            accessibilityProfile: accessibilityProfile,
            defaultPriority: defaultPriority,
          ),
    );
    return !state.hasError;
  }

  /// Applies a fresh Ayni points balance locally (e.g. after sharing
  /// location or answering a question) so the badge updates instantly
  /// without refetching the whole profile.
  void applyAyniBalance(int balance) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(ayniPoints: balance));
    }
  }
}
