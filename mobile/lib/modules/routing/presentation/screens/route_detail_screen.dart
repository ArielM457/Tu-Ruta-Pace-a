import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/router.dart';
import '../../../trips/presentation/providers/trips_providers.dart';
import '../../data/route_recommendation_mapper.dart';
import '../../domain/route_entities.dart';
import '../providers/routing_providers.dart';
import '../widgets/transport_mode_ui.dart';

class RouteDetailScreen extends ConsumerWidget {
  const RouteDetailScreen({super.key});

  Future<void> _startTrip(
    BuildContext context,
    WidgetRef ref,
    RouteOption option,
  ) async {
    final started = await ref
        .read(startTripControllerProvider.notifier)
        .startTrip(routeOptionToJson(option));
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (started) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Viaje iniciado. ¡Buen viaje!'),
        ),
      );
      context.go(AppRoutes.home);
      return;
    }
    final error = ref.read(startTripControllerProvider).error;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error?.toString() ?? 'No se pudo iniciar el viaje. Intenta de nuevo.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final option = ref.watch(selectedRouteOptionProvider);
    final startTripState = ref.watch(startTripControllerProvider);
    if (option == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de ruta')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.routeOptions),
            child: const Text('Volver a las opciones'),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de ruta'),
        leading: BackButton(
          onPressed: () => context.go(AppRoutes.routeOptions),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 240,
            child: _RouteMap(option: option),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Text(
                      '${option.totalDurationMinutes} min',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatCostBs(option.totalCostBs),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(formatDistance(option.totalDistanceMeters)),
                  ],
                ),
                if (option.avoidsAnyIncident)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Esta ruta evita bloqueos activos en la ciudad',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                for (final leg in option.legs) _LegTile(leg: leg),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: startTripState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Iniciar viaje'),
                onPressed: startTripState.isLoading
                    ? null
                    : () => _startTrip(context, ref, option),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.option});

  final RouteOption option;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final legPaths = [
      for (final leg in option.legs)
        (leg: leg, path: leg.path.map((point) => LatLng(point.lat, point.lng)).toList()),
    ];
    final allPoints = [
      for (final legPath in legPaths) ...legPath.path,
    ];
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: allPoints.isEmpty
            ? const LatLng(-16.4957, -68.1335)
            : allPoints[allPoints.length ~/ 2],
        zoom: 13,
      ),
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      onMapCreated: (controller) {
        final bounds = _boundsFor(allPoints);
        if (bounds != null) {
          controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 40));
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
    if (points.length < 2) {
      return null;
    }
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

class _LegTile extends StatelessWidget {
  const _LegTile({required this.leg});

  final RouteLeg leg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final legColor = routeLegColor(leg, theme.colorScheme);
    final lineDetail = [
      if (leg.lineName != null) leg.lineName!,
      if (leg.boardStop != null) 'Sube en ${leg.boardStop!.name}',
      if (leg.alightStop != null) 'Baja en ${leg.alightStop!.name}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: legColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(leg.mode.icon, size: 20, color: legColor),
              ),
              Container(width: 3, height: 28, color: legColor),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(leg.instruction, style: theme.textTheme.bodyLarge),
                if (lineDetail.isNotEmpty)
                  Text(lineDetail, style: theme.textTheme.bodySmall),
                Text(
                  '${leg.durationMinutes} min · ${formatCostBs(leg.costBs)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
