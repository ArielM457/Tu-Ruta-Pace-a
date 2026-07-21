import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/location/location_providers.dart';
import '../../../../core/types/coordinate.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../../../core/widgets/chasqui_top_bar.dart';
import '../../../community/presentation/providers/collaboration_providers.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../community/presentation/widgets/help_popup.dart';
import '../../../community/presentation/widgets/sharing_chip.dart';
import '../../../incidents/domain/incident_entities.dart';
import '../../../incidents/presentation/providers/incident_providers.dart';
import '../../../incidents/presentation/widgets/incident_detail_sheet.dart';
import '../../../incidents/presentation/widgets/report_fab.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/presentation/widgets/preference_options.dart';
import '../../../trips/presentation/providers/trips_providers.dart';
import '../../domain/route_entities.dart';
import '../providers/routing_providers.dart';
import '../widgets/transport_mode_ui.dart';

const CameraPosition _laPazInitialCamera = CameraPosition(
  target: LatLng(-16.4957, -68.1335),
  zoom: 13,
);

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrip = ref.watch(activeTripProvider);
    return Scaffold(
      appBar: ChasquiTopBar(
        title: activeTrip != null ? 'Viaje en curso' : 'Mapa de La Paz',
        subtitle: activeTrip != null
            ? null
            : 'Tráfico e incidentes en vivo',
        onBack: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
      ),
      body: activeTrip != null
          ? _TripInProgressView(activeTrip: activeTrip)
          : const _MapView(),
      floatingActionButton: const ReportFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _TripInProgressView extends ConsumerWidget {
  const _TripInProgressView({required this.activeTrip});

  final ActiveTrip activeTrip;

  Future<void> _finishTrip(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final finished = await ref
        .read(finishTripControllerProvider.notifier)
        .finishTrip(activeTrip.trip.id);
    if (!finished) {
      final error = ref.read(finishTripControllerProvider).error;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error?.toString() ?? 'No se pudo finalizar el viaje. Intenta de nuevo.',
          ),
        ),
      );
      return;
    }
    if (ref.read(activeShareProvider) != null) {
      await ref.read(activeShareProvider.notifier).stop();
    }
    ref.read(activeTripProvider.notifier).clear();
    ref.read(routeRequestProvider.notifier).clearDestination();
    ref.invalidate(recentTripsProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Viaje finalizado. ¡Gracias por viajar con Chasqui!')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final option = activeTrip.option;
    final isSharing = ref.watch(activeShareProvider) != null;
    final finishState = ref.watch(finishTripControllerProvider);
    final nextLeg = option.legs.first;

    return Stack(
      children: [
        _TripRouteMap(option: option),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: isSharing
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: SharingChip(),
                )
              : const SizedBox.shrink(),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          child: ChasquiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRÓXIMO PASO',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ChasquiColors.yellow100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        nextLeg.mode.icon,
                        size: 16,
                        color: ChasquiColors.yellow800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nextLeg.instruction,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ChasquiColors.neutral950,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: finishState.isLoading
                      ? null
                      : () => _finishTrip(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: ChasquiColors.orange600,
                    foregroundColor: Colors.white,
                  ),
                  child: finishState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Finalizar viaje'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TripRouteMap extends StatelessWidget {
  const _TripRouteMap({required this.option});

  final RouteOption option;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final legPaths = [
      for (final leg in option.legs)
        (
          leg: leg,
          path: leg.path.map((point) => LatLng(point.lat, point.lng)).toList(),
        ),
    ];
    final allPoints = [for (final legPath in legPaths) ...legPath.path];

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: allPoints.isEmpty
            ? const LatLng(-16.4957, -68.1335)
            : allPoints[allPoints.length ~/ 2],
        zoom: 14,
      ),
      zoomControlsEnabled: false,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      onMapCreated: (controller) {
        final bounds = _boundsFor(allPoints);
        if (bounds != null) {
          controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
        }
      },
      polylines: {
        for (int index = 0; index < legPaths.length; index++)
          if (legPaths[index].path.length >= 2)
            Polyline(
              polylineId: PolylineId('leg-$index'),
              points: legPaths[index].path,
              color: routeLegColor(legPaths[index].leg, colorScheme),
              width: 5,
              patterns: legPaths[index].leg.mode == TransportMode.walk
                  ? [PatternItem.dot, PatternItem.gap(8)]
                  : const [],
            ),
      },
      markers: {
        if (allPoints.isNotEmpty)
          Marker(
            markerId: const MarkerId('origin'),
            position: allPoints.first,
            infoWindow: const InfoWindow(title: 'Origen'),
          ),
        if (allPoints.length > 1)
          Marker(
            markerId: const MarkerId('destination'),
            position: allPoints.last,
            infoWindow: const InfoWindow(title: 'Destino'),
          ),
      },
    );
  }

  LatLngBounds? _boundsFor(List<LatLng> points) {
    if (points.length < 2) return null;
    var south = points.first.latitude;
    var north = points.first.latitude;
    var west = points.first.longitude;
    var east = points.first.longitude;
    for (final point in points) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }
}

class _MapView extends ConsumerStatefulWidget {
  const _MapView();

  @override
  ConsumerState<_MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<_MapView> {
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
                context.push(AppRoutes.routeOptions);
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
