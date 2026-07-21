import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/theme.dart';
import '../../../../core/types/coordinate.dart';
import '../../../../core/utils/polyline_decoder.dart';
import '../../domain/emergency_entities.dart';
import '../providers/emergency_providers.dart';
import 'hospital_card.dart';

class EmergencyRouteSheet extends ConsumerWidget {
  const EmergencyRouteSheet({super.key, required this.origin});

  final Coordinate origin;

  static Future<void> show(BuildContext context, {required Coordinate origin}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EmergencyRouteSheet(origin: origin),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(emergencyRouteProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ChasquiColors.neutral200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: routeState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No se pudo calcular la ruta. Llama al 110 o 165 para asistencia inmediata.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              data: (response) {
                if (response == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Text(
                      'Ruta más rápida',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 200,
                        child: _RouteMap(origin: origin, response: response),
                      ),
                    ),
                    const SizedBox(height: 16),
                    HospitalCard(
                      candidate: response.recommended,
                      isRecommended: true,
                    ),
                    if (response.alternatives.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'ALTERNATIVAS',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      for (final (i, candidate)
                          in response.alternatives.take(2).indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HospitalCard(
                            candidate: candidate,
                            isRecommended: false,
                            index: i + 1,
                            onTap: () => ref
                                .read(emergencyRouteProvider.notifier)
                                .selectAlternative(candidate),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.origin, required this.response});

  final Coordinate origin;
  final EmergencyRouteResponse response;

  @override
  Widget build(BuildContext context) {
    final destination = response.recommended.facility.position;
    final polylinePoints = decodePolyline(response.recommended.polyline)
        .map((c) => LatLng(c.lat, c.lng))
        .toList();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          (origin.lat + destination.lat) / 2,
          (origin.lng + destination.lng) / 2,
        ),
        zoom: 13,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(origin.lat, origin.lng),
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(destination.lat, destination.lng),
          infoWindow: InfoWindow(title: response.recommended.facility.name),
        ),
      },
      polylines: polylinePoints.length >= 2
          ? {
              Polyline(
                polylineId: const PolylineId('emergency_route'),
                points: polylinePoints,
                color: ChasquiColors.orange600,
                width: 5,
              ),
            }
          : const {},
      zoomControlsEnabled: false,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      trafficEnabled: true,
    );
  }
}
