import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/types/coordinate.dart';
import '../../data/api_incident_repository.dart';
import '../../domain/incident_entities.dart';
import '../../domain/incident_repository.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return ApiIncidentRepository(
    ref.watch(apiClientProvider),
    Supabase.instance.client,
  );
});

// ── Active incidents (loaded by visible bbox) ──────────────────────────────

class ActiveIncidentsNotifier extends AsyncNotifier<List<Incident>> {
  @override
  Future<List<Incident>> build() async => [];

  Future<void> refresh(String bbox) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(incidentRepositoryProvider).getActive(bbox: bbox),
    );
  }

  void addOptimistic(Incident incident) {
    final current = state.value ?? [];
    state = AsyncData([incident, ...current]);
  }

  void applyVote(Incident updated) {
    final current = state.value ?? [];
    state = AsyncData(
      current.map((i) => i.id == updated.id ? updated : i).toList(),
    );
  }
}

final activeIncidentsProvider =
    AsyncNotifierProvider<ActiveIncidentsNotifier, List<Incident>>(
  ActiveIncidentsNotifier.new,
);

// ── Pending incidents near user ────────────────────────────────────────────

class PendingIncidentsNotifier extends AsyncNotifier<List<Incident>> {
  @override
  Future<List<Incident>> build() async => [];

  Future<void> refresh(Coordinate pos) async {
    state = await AsyncValue.guard(
      () => ref.read(incidentRepositoryProvider).getPendingNear(pos),
    );
  }

  void applyVote(Incident updated) {
    final current = state.value ?? [];
    if (updated.status == IncidentStatus.active ||
        updated.status == IncidentStatus.resolved) {
      // No longer pending — remove from list
      state = AsyncData(current.where((i) => i.id != updated.id).toList());
    } else {
      state = AsyncData(
        current.map((i) => i.id == updated.id ? updated : i).toList(),
      );
    }
  }
}

final pendingIncidentsProvider =
    AsyncNotifierProvider<PendingIncidentsNotifier, List<Incident>>(
  PendingIncidentsNotifier.new,
);
