import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/collaboration_entities.dart';

class AyniMovementTile extends StatelessWidget {
  const AyniMovementTile({super.key, required this.movement, required this.index});

  final AyniMovement movement;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = movement.amount >= 0;
    final date = DateTime.tryParse(movement.createdAt);
    final dateLabel = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        child: Text(movement.reason.emoji, style: const TextStyle(fontSize: 16)),
      ),
      title: Text(movement.reason.label, style: theme.textTheme.bodyMedium),
      subtitle: Text(dateLabel, style: theme.textTheme.bodySmall),
      trailing: Text(
        '${isPositive ? '+' : ''}${movement.amount}',
        style: theme.textTheme.titleMedium?.copyWith(
          color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          fontWeight: FontWeight.w700,
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms);
  }
}
