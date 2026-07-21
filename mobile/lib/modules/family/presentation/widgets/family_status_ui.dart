import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/family_entities.dart';

const Duration _recentlySeenThreshold = Duration(minutes: 60);

class FamilyMemberDisplayStatus {
  const FamilyMemberDisplayStatus({
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String subtitle;
  final Color color;
}

FamilyMemberDisplayStatus familyMemberDisplayStatus(FamilyMember member) {
  switch (member.status) {
    case FamilyMemberStatus.onTrip:
      return FamilyMemberDisplayStatus(
        label: 'En ruta',
        subtitle: member.currentLineName ?? 'En camino',
        color: ChasquiColors.successText,
      );
    case FamilyMemberStatus.pending:
      return const FamilyMemberDisplayStatus(
        label: 'Invitación pendiente',
        subtitle: 'Comparte el código para que se una',
        color: ChasquiColors.warm600,
      );
    case FamilyMemberStatus.hidden:
      return const FamilyMemberDisplayStatus(
        label: 'Sin compartir',
        subtitle: 'No activó compartir ubicación con la familia',
        color: ChasquiColors.neutral400,
      );
    case FamilyMemberStatus.inactive:
      final lastPingAt = member.lastPingAt;
      if (lastPingAt == null) {
        return const FamilyMemberDisplayStatus(
          label: 'Desconectada',
          subtitle: 'Sin actividad registrada',
          color: ChasquiColors.neutral400,
        );
      }
      final isRecentlySeen =
          DateTime.now().difference(lastPingAt.toLocal()) <=
              _recentlySeenThreshold;
      return FamilyMemberDisplayStatus(
        label: isRecentlySeen ? 'En casa' : 'Desconectada',
        subtitle: 'Última vez: ${_relativeTime(lastPingAt)}',
        color: isRecentlySeen
            ? ChasquiColors.warm600
            : ChasquiColors.neutral400,
      );
  }
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inMinutes < 1) return 'hace instantes';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return 'hace ${diff.inDays} d';
}
