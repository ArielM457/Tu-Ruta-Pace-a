import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../domain/government_entities.dart';

const _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

class DailyActivityChart extends StatelessWidget {
  const DailyActivityChart({super.key, required this.dailySeries});

  final List<DailyCount> dailySeries;

  @override
  Widget build(BuildContext context) {
    if (dailySeries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Sin actividad registrada en este período',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ),
      );
    }

    final maxCount = dailySeries.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (index, day) in dailySeries.indexed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DayBar(day: day, maxCount: maxCount, index: index),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.day, required this.maxCount, required this.index});

  final DailyCount day;
  final int maxCount;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = maxCount == 0 ? 0.0 : day.count / maxCount;
    final date = DateTime.tryParse(day.date);
    final weekdayLabel = date != null ? _weekdayLabels[date.weekday - 1] : '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${day.count}', style: theme.textTheme.labelSmall),
        const Gap(4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction.clamp(0.03, 1.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.indigo[400],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              )
                  .animate()
                  .scaleY(
                    begin: 0,
                    end: 1,
                    alignment: Alignment.bottomCenter,
                    duration: 500.ms,
                    delay: (index * 80).ms,
                    curve: Curves.easeOut,
                  ),
            ),
          ),
        ),
        const Gap(6),
        Text(
          weekdayLabel,
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
        ),
      ],
    );
  }
}
