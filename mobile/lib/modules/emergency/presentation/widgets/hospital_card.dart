import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../../../core/widgets/chasqui_tag.dart';
import '../../domain/emergency_entities.dart';

class HospitalCard extends StatelessWidget {
  const HospitalCard({
    super.key,
    required this.candidate,
    required this.isRecommended,
    this.onTap,
    this.index = 0,
  });

  final EmergencyRouteCandidate candidate;
  final bool isRecommended;
  final VoidCallback? onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ChasquiCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: ChasquiColors.successSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: ChasquiColors.successText,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  candidate.facility.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ChasquiColors.neutral950,
                  ),
                ),
              ),
              if (isRecommended)
                const ChasquiTag(
                  label: 'MÁS RÁPIDO',
                  background: ChasquiColors.yellow600,
                  foreground: ChasquiColors.neutral950,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetricChip(
                icon: Icons.timer_outlined,
                value: '${candidate.durationMinutes} min',
              ),
              const SizedBox(width: 12),
              _MetricChip(
                icon: Icons.place_outlined,
                value: '${candidate.distanceKm.toStringAsFixed(1)} km',
              ),
              if (candidate.affectedByIncidents) ...[
                const SizedBox(width: 12),
                const ChasquiTag(
                  label: 'Tráfico',
                  background: ChasquiColors.warm200,
                  foreground: ChasquiColors.orange700,
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ],
          ),
        ],
      ),
    )
        .animate(delay: (index * 100).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ChasquiColors.neutral400),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ChasquiColors.neutral950,
          ),
        ),
      ],
    );
  }
}
