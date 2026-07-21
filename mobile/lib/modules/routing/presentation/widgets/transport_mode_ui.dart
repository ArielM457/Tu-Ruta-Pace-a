import 'package:flutter/material.dart';

import '../../domain/route_entities.dart';

extension TransportModeUi on TransportMode {
  String get label => switch (this) {
        TransportMode.walk => 'Caminar',
        TransportMode.cableCar => 'Teleférico',
        TransportMode.pumakatari => 'PumaKatari',
        TransportMode.minibus => 'Minibús',
        TransportMode.micro => 'Micro',
        TransportMode.trufi => 'Trufi',
        TransportMode.taxi => 'Taxi',
      };

  IconData get icon => switch (this) {
        TransportMode.walk => Icons.directions_walk,
        TransportMode.cableCar => Icons.tram,
        TransportMode.pumakatari => Icons.directions_bus,
        TransportMode.minibus => Icons.airport_shuttle,
        TransportMode.micro => Icons.directions_bus_filled,
        TransportMode.trufi => Icons.airport_shuttle,
        TransportMode.taxi => Icons.local_taxi,
      };
}

Color routeLegColor(RouteLeg leg, ColorScheme colorScheme) {
  final parsedLineColor = _parseHexColor(leg.lineColor);
  if (parsedLineColor != null) {
    return parsedLineColor;
  }
  return switch (leg.mode) {
    TransportMode.walk => colorScheme.outline,
    TransportMode.taxi => colorScheme.tertiary,
    _ => colorScheme.primary,
  };
}

Color? _parseHexColor(String? hexColor) {
  if (hexColor == null) {
    return null;
  }
  final normalized = hexColor.replaceFirst('#', '');
  if (normalized.length != 6) {
    return null;
  }
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return null;
  }
  return Color(0xFF000000 | value);
}

String formatCostBs(double costBs) {
  return 'Bs. ${costBs.toStringAsFixed(2)}';
}

String formatDistance(int distanceMeters) {
  if (distanceMeters < 1000) {
    return '$distanceMeters m';
  }
  return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
}
