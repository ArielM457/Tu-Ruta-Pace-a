import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/router.dart';
import '../../../../core/location/location_providers.dart';
import '../../../../core/types/coordinate.dart';
import '../../../community/presentation/providers/collaboration_providers.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../community/presentation/widgets/ayni_badge.dart';
import '../../../community/presentation/widgets/help_popup.dart';
import '../../../community/presentation/widgets/sharing_chip.dart';
import '../../../emergency/presentation/widgets/sos_fab.dart';
import '../../../incidents/domain/incident_entities.dart';
import '../../../incidents/presentation/providers/incident_providers.dart';
import '../../../incidents/presentation/widgets/incident_detail_sheet.dart';
import '../../../incidents/presentation/widgets/report_fab.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/preference_options.dart';
import '../providers/routing_providers.dart';

const CameraPosition _laPazInitialCamera = CameraPosition(
  target: LatLng(-16.4957, -68.1335),
  zoom: 13,
);

class HomeMapScreen extends ConsumerWidget {
  const HomeMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGovernment = ref.watch(
      profileControllerProvider.select(
        (state) => state.value?.role == UserRole.government,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayni Ruta'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AyniBadge(onTap: () => context.push(AppRoutes.community)),
          ),
          if (isGovernment)
            IconButton(
              tooltip: 'Panel de gobierno',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.push(AppRoutes.government),
            ),
          IconButton(
            tooltip: 'Asistente',
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () => context.push(AppRoutes.assistant),
          ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.person),
            onPressed: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
      body: const _HomeMapView(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          ReportFab(),
          SizedBox(height: 10),
          SosFab(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _HomeMapView extends ConsumerStatefulWidget {
  const _HomeMapView();

  @override
  ConsumerState<_HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends ConsumerState<_HomeMapView> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingNear();
      _maybeShowHelpPopup();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadPendingNear() async {
    final pos = ref.read(currentPositionProvider).value;
    if (pos != null) {
      await ref.read(pendingIncidentsProvider.notifier).refresh(pos);
    }
  }

  Future<void> _maybeShowHelpPopup() async {
    if (ref.read(helpPopupDismissedProvider)) return;
    final questions = await ref.read(pendingQuestionsProvider.future);
    if (questions.isEmpty || !mounted) return;

    final wantsToHelp = await HelpPopup.show(context, questions: questions);
    ref.read(helpPopupDismissedProvider.notifier).state = true;
    if (wantsToHelp == true && mounted) {
      context.push(AppRoutes.pendingQuestions);
    }
  }

  Future<void> _onCameraIdle() async {
    final controller = _mapController;
    if (controller == null) return;
    final bounds = await controller.getVisibleRegion();
    // Backend expects: minLng,minLat,maxLng,maxLat
    final bbox =
        '${bounds.southwest.longitude},${bounds.southwest.latitude},${bounds.northeast.longitude},${bounds.northeast.latitude}';
    await ref.read(activeIncidentsProvider.notifier).refresh(bbox);
  }

  void _showIncidentDetail(Incident incident) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => IncidentDetailSheet(incident: incident),
    );
  }

  Set<Marker> _buildIncidentMarkers(
    List<Incident> active,
    List<Incident> pending,
  ) {
    final markers = <Marker>{};

    for (final incident in active) {
      markers.add(
        Marker(
          markerId: MarkerId('incident_${incident.id}'),
          position: LatLng(incident.lat, incident.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(incident.kind.markerHue),
          infoWindow: InfoWindow(
            title: '${incident.kind.emoji} ${incident.kind.label}',
            snippet: incident.description.length > 40
                ? '${incident.description.substring(0, 40)}…'
                : incident.description,
          ),
          onTap: () => _showIncidentDetail(incident),
        ),
      );
    }

    for (final incident in pending) {
      markers.add(
        Marker(
          markerId: MarkerId('incident_${incident.id}'),
          position: LatLng(incident.lat, incident.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: '? ${incident.kind.label} — pendiente',
            snippet: '${incident.confirmations}/3 confirmaciones',
          ),
          onTap: () => _showIncidentDetail(incident),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = ref.watch(currentPositionProvider);
    final routeRequest = ref.watch(routeRequestProvider);
    final destination = routeRequest.destination;

    final activeIncidents = ref.watch(activeIncidentsProvider).value ?? [];
    final pendingIncidents = ref.watch(pendingIncidentsProvider).value ?? [];
    final isSharing = ref.watch(activeShareProvider) != null;

    final incidentMarkers = _buildIncidentMarkers(activeIncidents, pendingIncidents);

    final destinationMarker = destination != null
        ? <Marker>{
            Marker(
              markerId: const MarkerId('destination'),
              position: LatLng(destination.lat, destination.lng),
              infoWindow: const InfoWindow(title: 'Tu destino'),
            ),
          }
        : <Marker>{};

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _laPazInitialCamera,
          trafficEnabled: true,
          myLocationEnabled: currentPosition.value != null,
          myLocationButtonEnabled: currentPosition.value != null,
          zoomControlsEnabled: false,
          onMapCreated: (c) => _mapController = c,
          onCameraIdle: _onCameraIdle,
          onLongPress: (position) {
            ref.read(routeRequestProvider.notifier).setDestination(
                  Coordinate(
                    lat: position.latitude,
                    lng: position.longitude,
                  ),
                );
          },
          markers: {...destinationMarker, ...incidentMarkers},
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            children: [
              if (isSharing) ...[
                const Align(alignment: Alignment.centerLeft, child: SharingChip()),
                const SizedBox(height: 8),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.search),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          destination == null
                              ? '¿A dónde vas? Mantén presionado el mapa para elegir tu destino'
                              : 'Destino elegido — ajusta con otro toque largo',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (destination != null)
                        IconButton(
                          tooltip: 'Quitar destino',
                          icon: const Icon(Icons.close),
                          onPressed: () => ref
                              .read(routeRequestProvider.notifier)
                              .clearDestination(),
                        ),
                    ],
                  ),
                ),
              ),
              if (currentPosition.hasValue && currentPosition.value == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Usamos tu ubicación solo para calcular rutas desde donde estás. Nunca se comparte sin que lo pidas.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.my_location),
                          label: const Text('Activar mi ubicación'),
                          onPressed: () =>
                              ref.invalidate(currentPositionProvider),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (destination != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: _RoutePlanPanel(
              hasOrigin: currentPosition.value != null,
              priority: routeRequest.priority,
              onSearch: () {
                final origin = currentPosition.value;
                if (origin == null) return;
                ref.read(routeRequestProvider.notifier).setOrigin(origin);
                context.go(AppRoutes.routeOptions);
              },
            ),
          ),
      ],
    );
  }
}

class _RoutePlanPanel extends ConsumerWidget {
  const _RoutePlanPanel({
    required this.hasOrigin,
    required this.priority,
    required this.onSearch,
  });

  final bool hasOrigin;
  final TravelPriority priority;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Qué priorizas hoy?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final option in TravelPriority.values)
                  ChoiceChip(
                    avatar: Icon(option.icon, size: 18),
                    label: Text(option.label),
                    selected: option == priority,
                    onSelected: (_) => ref
                        .read(routeRequestProvider.notifier)
                        .setPriority(option),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.route),
              label: const Text('Ver opciones de ruta'),
              onPressed: hasOrigin ? onSearch : null,
            ),
            if (!hasOrigin) ...[
              const SizedBox(height: 8),
              Text(
                'Activa tu ubicación para calcular la ruta desde donde estás',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
