import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/types/coordinate.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../domain/emergency_entities.dart';

String _formatDistanceMeters(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

class NearbyFacilityTile extends StatelessWidget {
  const NearbyFacilityTile({
    super.key,
    required this.facility,
    required this.origin,
    required this.index,
    this.onTap,
  });

  final HealthFacility facility;
  final Coordinate? origin;
  final int index;
  final VoidCallback? onTap;

  bool get _isHospital => facility.kind == 'hospital';

  @override
  Widget build(BuildContext context) {
    final distanceMeters = origin == null
        ? null
        : Geolocator.distanceBetween(
            origin!.lat,
            origin!.lng,
            facility.position.lat,
            facility.position.lng,
          );

    return ChasquiCard(
      onTap: _isHospital ? onTap : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isHospital
                  ? ChasquiColors.successSurface
                  : ChasquiColors.yellow100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isHospital ? Icons.local_hospital_rounded : Icons.shield_rounded,
              size: 17,
              color: _isHospital
                  ? ChasquiColors.successText
                  : ChasquiColors.yellow800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ChasquiColors.neutral950,
                  ),
                ),
                if (distanceMeters != null)
                  Text(
                    '${_formatDistanceMeters(distanceMeters)} de distancia',
                    style: const TextStyle(
                      fontSize: 11,
                      color: ChasquiColors.neutral500,
                    ),
                  ),
              ],
            ),
          ),
          if (facility.phone != null)
            Semantics(
              label: 'Llamar a ${facility.name}, ${facility.phone}',
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _call(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ChasquiColors.yellow100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 12,
                        color: ChasquiColors.neutral950,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        facility.phone!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: ChasquiColors.neutral950,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate(delay: (index * 60).ms).fadeIn(duration: 250.ms);
  }

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: facility.phone);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Llama al ${facility.phone}')),
        );
      }
    }
  }
}
