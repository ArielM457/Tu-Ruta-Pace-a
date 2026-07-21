import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/chasqui_card.dart';
import '../../../../core/widgets/chasqui_tag.dart';
import '../../domain/route_entities.dart';
import 'route_option_display.dart';
import 'transport_mode_ui.dart';

class RouteOptionCard extends StatelessWidget {
  const RouteOptionCard({
    super.key,
    required this.option,
    required this.tag,
    required this.onTap,
  });

  final RouteOption option;
  final RouteOptionTagKind tag;
  final VoidCallback onTap;

  IconData get _leadingIcon {
    final primaryTransitLeg = option.legs.firstWhere(
      (leg) => leg.mode != TransportMode.walk,
      orElse: () => option.legs.first,
    );
    return primaryTransitLeg.mode.icon;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = compositeRouteName(option);
    final transfers = countRouteTransfers(option);

    return Semantics(
      button: true,
      label:
          '$name, ${tag.label}, ${option.totalDurationMinutes} minutos, ${formatCostBs(option.totalCostBs)}'
          '${transfers > 0 ? ', $transfers transbordo${transfers > 1 ? 's' : ''}' : ''}',
      child: ChasquiCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ChasquiColors.yellow100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _leadingIcon,
                    size: 16,
                    color: ChasquiColors.yellow800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ChasquiTag(
                        label: tag.label,
                        background: tag.background,
                        foreground: tag.foreground,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: ChasquiColors.neutral300,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: ChasquiColors.neutral400,
                ),
                const SizedBox(width: 5),
                Text(
                  '${option.totalDurationMinutes} min',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ChasquiColors.neutral950,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  formatCostBs(option.totalCostBs),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: ChasquiColors.yellow700,
                  ),
                ),
                if (transfers > 0) ...[
                  const SizedBox(width: 16),
                  Text(
                    '$transfers transbordo${transfers > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ChasquiColors.neutral500,
                    ),
                  ),
                ],
              ],
            ),
            if (option.avoidsAnyIncident) ...[
              const SizedBox(height: 8),
              const ChasquiTag(
                label: 'Evita bloqueos activos',
                background: ChasquiColors.neutral100,
                foreground: ChasquiColors.neutral700,
                icon: Icons.alt_route,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
