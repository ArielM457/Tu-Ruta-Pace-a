import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/government_entities.dart';
import '../providers/government_providers.dart';
import '../widgets/daily_activity_chart.dart';
import '../widgets/government_incident_tile.dart';
import '../widgets/incident_filter_bar.dart';
import '../widgets/kind_distribution_bars.dart';
import '../widgets/metric_card.dart';

class GovernmentScreen extends ConsumerWidget {
  const GovernmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(congestionSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(child: Text('Panel de Gobierno GAMLP')),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Rol oficial',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo[700],
                ),
              ),
            ),
          ],
        ),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
      ),
      body: summaryState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(congestionSummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(congestionSummaryProvider);
            ref.invalidate(filteredGovernmentIncidentsProvider);
            ref.invalidate(governmentMapIncidentsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMetricsRow(summary),
              const Gap(28),
              _buildSectionTitle(context, 'Actividad por tipo'),
              const Gap(12),
              KindDistributionBars(byKind: summary.byKind),
              const Gap(24),
              _buildSectionTitle(context, 'Actividad diaria (7 días)'),
              const Gap(12),
              DailyActivityChart(dailySeries: summary.dailySeries),
              const Gap(28),
              _buildSectionTitle(context, 'Incidentes recientes'),
              const Gap(10),
              const IncidentFilterBar(),
              const Gap(12),
              _buildIncidentsList(ref),
              const Gap(28),
              _buildSectionTitle(context, 'Mapa de incidentes'),
              const Gap(10),
              _buildMap(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildMetricsRow(CongestionSummary summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        MetricCard(
          value: summary.totalIncidents,
          label: 'Total incidentes · 7 días',
          icon: Icons.report_outlined,
          color: Colors.indigo,
          index: 0,
        ),
        MetricCard(
          value: summary.statusCount('active'),
          label: 'Activos ahora',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFD32F2F),
          index: 1,
        ),
        MetricCard(
          value: summary.sourceCount('citizen'),
          label: 'Reportados por ciudadanos',
          icon: Icons.people_outline,
          color: const Color(0xFF00897B),
          index: 2,
        ),
        MetricCard(
          value: summary.kindCount('official_closure'),
          label: 'Cierres oficiales',
          icon: Icons.verified_outlined,
          color: const Color(0xFF1565C0),
          index: 3,
        ),
      ],
    );
  }

  Widget _buildIncidentsList(WidgetRef ref) {
    final incidentsState = ref.watch(filteredGovernmentIncidentsProvider);
    return incidentsState.when(
      data: (incidents) {
        if (incidents.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Sin incidentes para este filtro',
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        }
        return Column(
          children: [
            for (final (index, incident) in incidents.indexed)
              GovernmentIncidentTile(incident: incident, index: index),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No se pudieron cargar los incidentes',
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildMap(WidgetRef ref) {
    final mapState = ref.watch(governmentMapIncidentsProvider);
    return mapState.when(
      data: (incidents) {
        final markers = <Marker>{
          for (final incident in incidents)
            Marker(
              markerId: MarkerId('gov_incident_${incident.id}'),
              position: LatLng(incident.lat, incident.lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(incident.kind.markerHue),
              infoWindow: InfoWindow(
                title: '${incident.kind.emoji} ${incident.kind.label}',
              ),
            ),
        };
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 260,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-16.4957, -68.1335),
                zoom: 12,
              ),
              markers: markers,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              trafficEnabled: true,
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).scaleXY(begin: 0.97, curve: Curves.easeOut);
      },
      loading: () => const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => SizedBox(
        height: 120,
        child: Center(
          child: Text('No se pudo cargar el mapa', style: TextStyle(color: Colors.grey[500])),
        ),
      ),
    );
  }
}
