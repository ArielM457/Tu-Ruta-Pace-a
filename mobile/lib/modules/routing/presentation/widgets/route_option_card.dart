import 'package:flutter/material.dart';

import '../../domain/route_entities.dart';
import 'transport_mode_ui.dart';

class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({super.key, required this.option, required this.onTap});

  final RouteOption option;
  final VoidCallback onTap;

  List<TransportMode> get _modeSequence {
    final sequence = <TransportMode>[];
    for (final leg in option.legs) {
      if (sequence.isEmpty || sequence.last != leg.mode) {
        sequence.add(leg.mode);
      }
    }
    return sequence;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modes = _modeSequence;
    return Semantics(
      button: true,
      label:
          'Opción de ${option.totalDurationMinutes} minutos por ${formatCostBs(option.totalCostBs)} usando ${modes.map((mode) => mode.label).join(', ')}',
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (int index = 0; index < modes.length; index++) ...[
                      if (index > 0)
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                      Icon(modes[index].icon, size: 22),
                    ],
                    const Spacer(),
                    Text(
                      '${option.totalDurationMinutes} min',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      formatCostBs(option.totalCostBs),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatDistance(option.totalDistanceMeters),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (option.avoidsAnyIncident) ...[
                  const SizedBox(height: 8),
                  Chip(
                    avatar: const Icon(Icons.alt_route, size: 16),
                    label: const Text('Evita bloqueos activos'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
