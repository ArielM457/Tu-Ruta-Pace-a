import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme.dart';
import '../../../community/domain/collaboration_entities.dart';

class AyniMovementTile extends StatelessWidget {
  const AyniMovementTile({super.key, required this.movement, required this.index});

  final AyniMovement movement;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isPositive = movement.amount >= 0;
    final date = DateTime.tryParse(movement.createdAt);
    final dateLabel = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChasquiColors.neutral100),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPositive
                  ? ChasquiColors.successSurface
                  : ChasquiColors.warm200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(movement.reason.emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.reason.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ChasquiColors.neutral950,
                  ),
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ChasquiColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${movement.amount}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isPositive
                  ? ChasquiColors.successText
                  : ChasquiColors.orange700,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms);
  }
}
