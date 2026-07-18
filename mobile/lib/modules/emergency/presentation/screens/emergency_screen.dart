import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/types/coordinate.dart';
import '../../../../core/utils/polyline_decoder.dart';
import '../../domain/emergency_entities.dart';
import '../providers/emergency_providers.dart';
import '../widgets/emergency_contact_card.dart';
import '../widgets/hospital_card.dart';

// La Paz city center as fallback
const _laPazCenter = Coordinate(lat: -16.5000, lng: -68.1500);

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  Coordinate? _userPosition;

  static const _emergencyBg = Color(0xFFB71C1C);
  static const _emergencySurface = Color(0xFFC62828);
  static const _emergencyAccent = Color(0xFFFFEB3B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final position = await ref.read(locationServiceProvider).getCurrentCoordinate();
    final origin = position ?? _laPazCenter;
    setState(() => _userPosition = origin);
    await ref.read(emergencyRouteProvider.notifier).buildRoute(origin);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _emergencyBg,
        colorScheme: const ColorScheme.dark(
          primary: _emergencyAccent,
          surface: _emergencySurface,
        ),
      ),
      child: Scaffold(
        backgroundColor: _emergencyBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDisclaimer(),
                      const Gap(16),
                      _buildRouteSection(),
                      const Gap(16),
                      _buildMapSection(),
                      const Gap(24),
                      _buildContactsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF8B0000),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.emergency, color: Colors.white, size: 28),
          const Gap(12),
          const Expanded(
            child: Text(
              'MODO URGENCIA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white70),
            tooltip: 'Salir de urgencia',
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF7B0000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF9A9A).withOpacity(0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFFFCDD2), size: 18),
          Gap(10),
          Expanded(
            child: Text(
              'Esta app ayuda a navegar; no despacha ambulancias.',
              style: TextStyle(
                color: Color(0xFFFFCDD2),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildRouteSection() {
    final routeState = ref.watch(emergencyRouteProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HOSPITAL MÁS CERCANO',
          style: TextStyle(
            color: Color(0xFFFFCDD2),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const Gap(10),
        routeState.when(
          data: (response) {
            if (response == null) {
              return _buildRouteLoading();
            }
            return Column(
              children: [
                HospitalCard(
                  candidate: response.recommended,
                  isRecommended: true,
                  index: 0,
                ),
                if (response.alternatives.isNotEmpty) ...[
                  const Gap(12),
                  const Text(
                    'ALTERNATIVAS',
                    style: TextStyle(
                      color: Color(0xFFFFCDD2),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Gap(8),
                  ...response.alternatives
                      .take(2)
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HospitalCard(
                            candidate: entry.value,
                            isRecommended: false,
                            index: entry.key + 1,
                            onTap: () => ref
                                .read(emergencyRouteProvider.notifier)
                                .selectAlternative(entry.value),
                          ),
                        ),
                      ),
                ],
              ],
            );
          },
          loading: _buildRouteLoading,
          error: (err, _) => _buildRouteError(err.toString()),
        ),
      ],
    );
  }

  Widget _buildRouteLoading() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFC62828),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFFFEB3B)),
            Gap(12),
            Text(
              'Buscando hospital más cercano...',
              style: TextStyle(color: Color(0xFFFFCDD2), fontSize: 13),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: Colors.white12,
        );
  }

  Widget _buildRouteError(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7B0000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 32),
          const Gap(8),
          const Text(
            'No se pudo calcular la ruta.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const Gap(4),
          const Text(
            'Llama al 911 para asistencia inmediata.',
            style: TextStyle(color: Color(0xFFFFCDD2), fontSize: 13),
          ),
          const Gap(12),
          OutlinedButton.icon(
            onPressed: _init,
            icon: const Icon(Icons.refresh, color: Color(0xFFFFEB3B)),
            label: const Text(
              'Reintentar',
              style: TextStyle(color: Color(0xFFFFEB3B)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFEB3B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    final routeState = ref.watch(emergencyRouteProvider);
    final routeResponse = routeState.value;
    if (routeResponse == null) return const SizedBox.shrink();

    final origin = _userPosition ?? _laPazCenter;
    final destination = routeResponse.recommended.facility.position;
    final polylinePoints = decodePolyline(routeResponse.recommended.polyline)
        .map((c) => LatLng(c.lat, c.lng))
        .toList();

    final markers = {
      Marker(
        markerId: const MarkerId('origin'),
        position: LatLng(origin.lat, origin.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
      ),
      Marker(
        markerId: const MarkerId('hospital_recommended'),
        position: LatLng(destination.lat, destination.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: routeResponse.recommended.facility.name),
      ),
      ...routeResponse.alternatives.map(
        (alt) => Marker(
          markerId: MarkerId('hospital_${alt.facility.id}'),
          position: LatLng(alt.facility.position.lat, alt.facility.position.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: alt.facility.name),
          onTap: () => ref
              .read(emergencyRouteProvider.notifier)
              .selectAlternative(alt),
        ),
      ),
    };

    final polylines = polylinePoints.isNotEmpty
        ? {
            Polyline(
              polylineId: const PolylineId('emergency_route'),
              points: polylinePoints,
              color: const Color(0xFFFFEB3B),
              width: 5,
            ),
          }
        : <Polyline>{};

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              (origin.lat + destination.lat) / 2,
              (origin.lng + destination.lng) / 2,
            ),
            zoom: 13,
          ),
          markers: markers,
          polylines: polylines,
          zoomControlsEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          trafficEnabled: true,
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms).scaleXY(begin: 0.95);
  }

  Widget _buildContactsSection() {
    final contactsState = ref.watch(emergencyContactsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LLAMA AHORA',
          style: TextStyle(
            color: Color(0xFFFFCDD2),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const Gap(10),
        contactsState.when(
          data: (contacts) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: contacts.length,
            itemBuilder: (_, i) => EmergencyContactCard(
              contact: contacts[i],
              index: i,
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFEB3B)),
          ),
          error: (_, __) => _buildFallbackContacts(),
        ),
      ],
    );
  }

  // Fallback hardcodeado si el backend falla (seguridad mínima)
  Widget _buildFallbackContacts() {
    const fallback = [
      EmergencyContact(name: 'Emergencias generales', number: '911'),
      EmergencyContact(name: 'Ambulancias', number: '165'),
      EmergencyContact(name: 'Ambulancias SAMU', number: '160'),
      EmergencyContact(name: 'Red 114 GAMLP', number: '114'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: fallback.length,
      itemBuilder: (_, i) =>
          EmergencyContactCard(contact: fallback[i], index: i),
    );
  }
}
