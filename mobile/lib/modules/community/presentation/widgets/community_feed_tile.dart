import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/community_entities.dart';
import 'community_badge_ui.dart';

class CommunityFeedTile extends StatelessWidget {
  const CommunityFeedTile({super.key, required this.entry});

  final CommunityFeedEntry entry;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(entry.createdAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChasquiColors.neutral100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.timeline_rounded,
              size: 14,
              color: ChasquiColors.warm600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: ChasquiColors.neutral900,
                    ),
                    children: [
                      TextSpan(
                        text: entry.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' ${communityFeedActionLabel(entry.reason)}',
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      communityRelativeTime(createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: ChasquiColors.neutral500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '+${entry.points}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: ChasquiColors.successText,
            ),
          ),
        ],
      ),
    );
  }
}
