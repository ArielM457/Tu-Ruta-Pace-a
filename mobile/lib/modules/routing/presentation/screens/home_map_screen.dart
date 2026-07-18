import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/router.dart';
import '../../../../core/location/location_providers.dart';
import '../../../../core/types/coordinate.dart';
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
    final profileState = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayni Ruta'),
        actions: [
          if (profileState.hasValue)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.handshake, size: 18),
                label: Text('${profileState.value!.ayniPoints} pts'),
              ),
            ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.person),
            onPressed: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
      body: const _HomeMapView(),
    );
  }
}

class _HomeMapView extends ConsumerWidget {
  const _HomeMapView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPosition = ref.watch(currentPositionProvider);
    final routeRequest = ref.watch(routeRequestProvider);
    final destination = routeRequest.destination;
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _laPazInitialCamera,
          trafficEnabled: true,
          myLocationEnabled: currentPosition.value != null,
          myLocationButtonEnabled: currentPosition.value != null,
          zoomControlsEnabled: false,
          onLongPress: (position) {
            ref.read(routeRequestProvider.notifier).setDestination(
                  Coordinate(
                    lat: position.latitude,
                    lng: position.longitude,
                  ),
                );
          },
          markers: {
            if (destination != null)
              Marker(
                markerId: const MarkerId('destination'),
                position: LatLng(destination.lat, destination.lng),
                infoWindow: const InfoWindow(title: 'Tu destino'),
              ),
          },
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            children: [
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
                if (origin == null) {
                  return;
                }
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
