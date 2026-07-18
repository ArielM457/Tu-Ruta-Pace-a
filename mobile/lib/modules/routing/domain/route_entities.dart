import '../../../core/types/coordinate.dart';
import '../../../core/utils/polyline_decoder.dart';

enum TransportMode {
  walk('walk'),
  cableCar('cable_car'),
  pumakatari('pumakatari'),
  minibus('minibus'),
  micro('micro'),
  trufi('trufi'),
  taxi('taxi');

  const TransportMode(this.apiValue);

  final String apiValue;

  static TransportMode fromApi(String value) => TransportMode.values.firstWhere(
        (mode) => mode.apiValue == value,
        orElse: () => TransportMode.walk,
      );
}

class StopRef {
  const StopRef({required this.id, required this.name});

  final String id;
  final String name;
}

class RouteLeg {
  const RouteLeg({
    required this.mode,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.costBs,
    required this.polyline,
    required this.instruction,
    this.lineId,
    this.lineName,
    this.lineColor,
    this.boardStop,
    this.alightStop,
  });

  final TransportMode mode;
  final int durationMinutes;
  final int distanceMeters;
  final double costBs;
  final String polyline;
  final String instruction;
  final String? lineId;
  final String? lineName;
  final String? lineColor;
  final StopRef? boardStop;
  final StopRef? alightStop;

  List<Coordinate> get path => decodePolyline(polyline);
}

class RouteOption {
  const RouteOption({
    required this.id,
    required this.totalDurationMinutes,
    required this.totalDistanceMeters,
    required this.totalCostBs,
    required this.safetyScore,
    required this.avoidsIncidents,
    required this.legs,
  });

  final String id;
  final int totalDurationMinutes;
  final int totalDistanceMeters;
  final double totalCostBs;
  final double safetyScore;
  final List<String> avoidsIncidents;
  final List<RouteLeg> legs;

  bool get avoidsAnyIncident => avoidsIncidents.isNotEmpty;
}

class RouteRecommendation {
  const RouteRecommendation({
    required this.options,
    required this.activeIncidentsConsidered,
  });

  final List<RouteOption> options;
  final int activeIncidentsConsidered;
}
