import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../incidents/domain/incident_entities.dart';
import '../providers/government_providers.dart';

class IncidentFilterBar extends ConsumerWidget {
  const IncidentFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(incidentFilterProvider);
    final notifier = ref.read(incidentFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todos los tipos'),
                selected: filter.kind == null,
                onSelected: (_) => notifier.setKind(null),
              ),
              const Gap(6),
              for (final kind in IncidentKind.values) ...[
                ChoiceChip(
                  label: Text('${kind.emoji} ${kind.label}'),
                  selected: filter.kind == kind,
                  onSelected: (_) => notifier.setKind(kind),
                ),
                const Gap(6),
              ],
            ],
          ),
        ),
        const Gap(8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todos los estados'),
                selected: filter.status == null,
                onSelected: (_) => notifier.setStatus(null),
              ),
              const Gap(6),
              for (final status in IncidentStatus.values) ...[
                ChoiceChip(
                  label: Text(status.label),
                  selected: filter.status == status,
                  onSelected: (_) => notifier.setStatus(status),
                ),
                const Gap(6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
