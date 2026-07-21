import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/location/location_providers.dart';
import '../../../../core/types/coordinate.dart';
import '../../data/api_emergency_repository.dart';
import '../../domain/emergency_entities.dart';
import '../../domain/emergency_repository.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>(
  (ref) => ApiEmergencyRepository(ref.watch(apiClientProvider)),
);

final emergencyContactsProvider = FutureProvider<List<EmergencyContact>>(
  (ref) => ref.watch(emergencyRepositoryProvider).getContacts(),
);

final nearbyFacilitiesProvider =
    FutureProvider.family.autoDispose<List<HealthFacility>, String?>(
  (ref, kind) async {
    final position = await ref.watch(currentPositionProvider.future);
    if (position == null) return [];
    return ref
        .watch(emergencyRepositoryProvider)
        .getFacilitiesNear(position, kind: kind);
  },
);

class EmergencyRouteNotifier
    extends AsyncNotifier<EmergencyRouteResponse?> {
  @override
  Future<EmergencyRouteResponse?> build() async => null;

  Future<void> buildRoute(Coordinate origin) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(emergencyRepositoryProvider).buildRoute(origin),
    );
  }

  void selectAlternative(EmergencyRouteCandidate candidate) {
    final current = state.value;
    if (current == null) return;
    // Swap selected candidate to recommended position
    final combined = <EmergencyRouteCandidate>[
      current.recommended,
      ...current.alternatives,
    ];
    final remaining = combined
        .where((c) => c.facility.id != candidate.facility.id)
        .toList();
    state = AsyncData(
      EmergencyRouteResponse(
        recommended: candidate,
        alternatives: remaining,
      ),
    );
  }
}

final emergencyRouteProvider =
    AsyncNotifierProvider<EmergencyRouteNotifier, EmergencyRouteResponse?>(
  EmergencyRouteNotifier.new,
);
