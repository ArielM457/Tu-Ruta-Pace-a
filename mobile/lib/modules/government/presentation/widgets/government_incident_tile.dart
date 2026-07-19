import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../incidents/domain/incident_entities.dart';

class GovernmentIncidentTile extends StatelessWidget {
  const GovernmentIncidentTile({super.key, required this.incident, required this.index});

  final Incident incident;
  final int index;

  Color _statusColor() {
    switch (incident.status) {
      case IncidentStatus.pending:
        return const Color(0xFF9E9E9E);
      case IncidentStatus.active:
        return const Color(0xFF2E7D32);
      case IncidentStatus.resolved:
        return const Color(0xFF1565C0);
      case IncidentStatus.rejected:
        return const Color(0xFFC62828);
    }
  }

  String _relativeTime() {
    final createdAt = DateTime.tryParse(incident.createdAt);
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(incident.kind.emoji, style: const TextStyle(fontSize: 18)),
                const Gap(8),
                Expanded(
                  child: Text(incident.kind.label, style: theme.textTheme.titleSmall),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    incident.status.label,
                    style: TextStyle(
                      color: _statusColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(6),
            Text(incident.description, style: theme.textTheme.bodyMedium),
            const Gap(8),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: Colors.grey[500]),
                const Gap(4),
                Text('${incident.confirmations}', style: theme.textTheme.bodySmall),
                const Gap(12),
                Icon(Icons.cancel_outlined, size: 14, color: Colors.grey[500]),
                const Gap(4),
                Text('${incident.denials}', style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(
                  _relativeTime(),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms, delay: (index * 60).ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
