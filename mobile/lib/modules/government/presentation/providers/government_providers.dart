import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../incidents/domain/incident_entities.dart';
import '../../../incidents/presentation/providers/incident_providers.dart';
import '../../data/api_government_repository.dart';
import '../../domain/government_entities.dart';
import '../../domain/government_repository.dart';

const Duration _summaryWindow = Duration(days: 7);

final governmentRepositoryProvider = Provider<GovernmentRepository>(
  (ref) => ApiGovernmentRepository(ref.watch(apiClientProvider)),
);

final congestionSummaryProvider =
    FutureProvider.autoDispose<CongestionSummary>((ref) {
  final now = DateTime.now();
  return ref.read(governmentRepositoryProvider).getCongestionSummary(
        from: now.subtract(_summaryWindow),
        to: now,
      );
});

class IncidentFilter {
  const IncidentFilter({this.status, this.kind});

  final IncidentStatus? status;
  final IncidentKind? kind;

  IncidentFilter copyWith({
    IncidentStatus? Function()? status,
    IncidentKind? Function()? kind,
  }) {
    return IncidentFilter(
      status: status != null ? status() : this.status,
      kind: kind != null ? kind() : this.kind,
    );
  }
}

class IncidentFilterNotifier extends Notifier<IncidentFilter> {
  @override
  IncidentFilter build() => const IncidentFilter();

  void setStatus(IncidentStatus? status) {
    state = state.copyWith(status: () => status);
  }

  void setKind(IncidentKind? kind) {
    state = state.copyWith(kind: () => kind);
  }
}

final incidentFilterProvider =
    NotifierProvider<IncidentFilterNotifier, IncidentFilter>(
  IncidentFilterNotifier.new,
);

final filteredGovernmentIncidentsProvider =
    FutureProvider.autoDispose<List<Incident>>((ref) {
  final filter = ref.watch(incidentFilterProvider);
  return ref.read(governmentRepositoryProvider).getIncidents(
        status: filter.status,
        kind: filter.kind,
      );
});

/// All active incidents citywide, for the government heat map (no bbox).
final governmentMapIncidentsProvider =
    FutureProvider.autoDispose<List<Incident>>((ref) async {
  return ref.read(incidentRepositoryProvider).getActive();
});
