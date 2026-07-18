import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRecommended
              ? const Color(0xFFFFEB3B)
              : const Color(0xFFC62828),
          borderRadius: BorderRadius.circular(16),
          border: isRecommended
              ? null
              : Border.all(color: const Color(0xFFEF9A9A), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _HospitalIcon(isRecommended: isRecommended),
                const Gap(12),
                Expanded(
                  child: Text(
                    candidate.facility.name,
                    style: TextStyle(
                      color: isRecommended ? Colors.black87 : Colors.white,
                      fontSize: isRecommended ? 16 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB71C1C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'MÁS RÁPIDO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                _MetricChip(
                  icon: Icons.timer_outlined,
                  value: '${candidate.durationMinutes} min',
                  isRecommended: isRecommended,
                ),
                const Gap(12),
                _MetricChip(
                  icon: Icons.place_outlined,
                  value: '${candidate.distanceKm.toStringAsFixed(1)} km',
                  isRecommended: isRecommended,
                ),
                if (candidate.affectedByIncidents) ...[
                  const Gap(12),
                  _IncidentChip(isRecommended: isRecommended),
                ],
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 100).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}

class _HospitalIcon extends StatelessWidget {
  const _HospitalIcon({required this.isRecommended});

  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final color = isRecommended ? const Color(0xFFB71C1C) : Colors.white;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isRecommended ? Colors.white : const Color(0xFFB71C1C),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.local_hospital, color: color, size: 22),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: isRecommended ? 1.15 : 1.0,
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.value,
    required this.isRecommended,
  });

  final IconData icon;
  final String value;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isRecommended
              ? Colors.black54
              : const Color(0xFFFFCDD2),
        ),
        const Gap(4),
        Text(
          value,
          style: TextStyle(
            color: isRecommended ? Colors.black87 : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ).animate().scale(
          begin: const Offset(0.7, 0.7),
          duration: 500.ms,
          curve: Curves.elasticOut,
        );
  }
}

class _IncidentChip extends StatelessWidget {
  const _IncidentChip({required this.isRecommended});

  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isRecommended
            ? const Color(0xFFF57F17)
            : const Color(0xFFB71C1C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '⚠️ Tráfico',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
