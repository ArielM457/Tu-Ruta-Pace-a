import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/route_entities.dart';
import 'transport_mode_ui.dart';

enum RouteOptionTagKind { fastest, cheapest, combined }

extension RouteOptionTagKindUi on RouteOptionTagKind {
  String get label => switch (this) {
        RouteOptionTagKind.fastest => 'Más rápido',
        RouteOptionTagKind.cheapest => 'Más barato',
        RouteOptionTagKind.combined => 'Recomendado',
      };

  Color get background => switch (this) {
        RouteOptionTagKind.fastest => ChasquiColors.successSurface,
        RouteOptionTagKind.cheapest => ChasquiColors.warm200,
        RouteOptionTagKind.combined => ChasquiColors.yellow200,
      };

  Color get foreground => switch (this) {
        RouteOptionTagKind.fastest => ChasquiColors.successText,
        RouteOptionTagKind.cheapest => ChasquiColors.warm800,
        RouteOptionTagKind.combined => ChasquiColors.yellow800,
      };
}

Map<String, RouteOptionTagKind> classifyRouteOptionTags(
  List<RouteOption> options,
) {
  if (options.isEmpty) return {};

  final fastestId = options
      .reduce((a, b) =>
          a.totalDurationMinutes <= b.totalDurationMinutes ? a : b)
      .id;
  final cheapestId =
      options.reduce((a, b) => a.totalCostBs <= b.totalCostBs ? a : b).id;

  return {
    for (final option in options)
      option.id: option.id == fastestId
          ? RouteOptionTagKind.fastest
          : option.id == cheapestId
              ? RouteOptionTagKind.cheapest
              : RouteOptionTagKind.combined,
  };
}

int countRouteTransfers(RouteOption option) {
  final transitLegCount =
      option.legs.where((leg) => leg.mode != TransportMode.walk).length;
  return transitLegCount > 0 ? transitLegCount - 1 : 0;
}

String compositeRouteName(RouteOption option) {
  final segmentNames = <String>[];
  for (final leg in option.legs) {
    if (leg.mode == TransportMode.walk) continue;
    final name = leg.lineName ?? leg.mode.label;
    if (segmentNames.isEmpty || segmentNames.last != name) {
      segmentNames.add(name);
    }
  }
  if (segmentNames.isEmpty) return TransportMode.walk.label;
  return segmentNames.join(' + ');
}
