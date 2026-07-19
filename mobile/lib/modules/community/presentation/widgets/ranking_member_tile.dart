import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/community_entities.dart';
import 'community_badge_ui.dart';

class RankingMemberTile extends StatelessWidget {
  const RankingMemberTile({
    super.key,
    required this.entry,
    required this.position,
    required this.isMe,
  });

  final CommunityRankingEntry entry;
  final int position;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final accent = entry.badge.accentColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? ChasquiColors.yellow100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? ChasquiColors.yellow400 : ChasquiColors.neutral100,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$position',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: position <= 3
                    ? ChasquiColors.orange600
                    : ChasquiColors.neutral400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              communityInitials(entry.displayName),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ChasquiColors.neutral950,
                  ),
                ),
                Text(
                  entry.badge.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: ChasquiColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.points}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
