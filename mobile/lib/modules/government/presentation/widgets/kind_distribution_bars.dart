import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../incidents/domain/incident_entities.dart';

class KindDistributionBars extends StatelessWidget {
  const KindDistributionBars({super.key, required this.byKind});

  final Map<String, int> byKind;

  @override
  Widget build(BuildContext context) {
    final maxValue = byKind.values.isEmpty
        ? 0
        : byKind.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, kind) in IncidentKind.values.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BarRow(
              label: '${kind.emoji} ${kind.label}',
              value: byKind[kind.apiValue] ?? 0,
              maxValue: maxValue,
              color: kind.markerColor,
              index: index,
            ),
          ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.index,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = maxValue == 0 ? 0.0 : value / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              '$value',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const Gap(6),
        LayoutBuilder(
          builder: (context, constraints) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 10,
                width: constraints.maxWidth,
                color: Colors.grey[200],
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: Duration(milliseconds: 600 + index * 80),
                  curve: Curves.easeOut,
                  builder: (context, animatedFraction, child) => Container(
                    height: 10,
                    width: constraints.maxWidth * animatedFraction,
                    color: color,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: (index * 80).ms);
  }
}
