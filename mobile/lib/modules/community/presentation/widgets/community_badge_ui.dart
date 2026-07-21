import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/community_entities.dart';

extension CommunityBadgeUi on CommunityBadge {
  Color get accentColor => switch (this) {
        CommunityBadge.hero => ChasquiColors.orange600,
        CommunityBadge.active => ChasquiColors.warm600,
        CommunityBadge.collaborator => ChasquiColors.successText,
        CommunityBadge.member => ChasquiColors.yellow700,
        CommunityBadge.newcomer => ChasquiColors.neutral500,
      };
}

String communityFeedActionLabel(String reason) {
  switch (reason) {
    case 'verified_report':
      return 'reportó un bloqueo verificado';
    case 'confirmed_incident':
      return 'verificó un reporte activo';
    case 'answered_question':
      return 'respondió una pregunta de la comunidad';
    default:
      return 'colaboró con la comunidad';
  }
}

String communityRelativeTime(DateTime date) {
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inMinutes < 1) return 'hace instantes';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return 'hace ${diff.inDays} d';
}

String communityInitials(String displayName) {
  final words = displayName.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return '?';
  final first = words.first.characters.first;
  final second = words.length > 1 && words[1].isNotEmpty
      ? words[1].characters.first
      : '';
  return (first + second).toUpperCase();
}
