import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../data/api_family_repository.dart';
import '../../domain/family_entities.dart';
import '../../domain/family_repository.dart';

final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => ApiFamilyRepository(ref.watch(apiClientProvider)),
);

final familyGroupProvider =
    AsyncNotifierProvider<FamilyGroupNotifier, FamilyGroup?>(
  FamilyGroupNotifier.new,
);

class FamilyGroupNotifier extends AsyncNotifier<FamilyGroup?> {
  @override
  Future<FamilyGroup?> build() {
    return ref.read(familyRepositoryProvider).getMyGroup();
  }

  Future<bool> createGroup(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(familyRepositoryProvider).createGroup(name),
    );
    return !state.hasError;
  }

  Future<bool> acceptInvitation(String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(familyRepositoryProvider).acceptInvitation(code),
    );
    return !state.hasError;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(familyRepositoryProvider).getMyGroup(),
    );
  }
}

class InviteFamilyMemberController extends AsyncNotifier<FamilyInvite?> {
  @override
  Future<FamilyInvite?> build() async => null;

  Future<bool> invite({String? email, String? relationshipLabel}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(familyRepositoryProvider).inviteMember(
            email: email,
            relationshipLabel: relationshipLabel,
          ),
    );
    if (!state.hasError) {
      ref.read(familyGroupProvider.notifier).refresh();
    }
    return !state.hasError;
  }
}

final inviteFamilyMemberControllerProvider =
    AsyncNotifierProvider<InviteFamilyMemberController, FamilyInvite?>(
  InviteFamilyMemberController.new,
);
