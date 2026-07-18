import '../domain/route_entities.dart';

RouteRecommendation routeRecommendationFromJson(Map<String, dynamic> json) {
  final options = (json['options'] as List<dynamic>? ?? [])
      .map((option) => routeOptionFromJson(option as Map<String, dynamic>))
      .toList();
  return RouteRecommendation(
    options: options,
    activeIncidentsConsidered:
        (json['activeIncidentsConsidered'] as num?)?.toInt() ?? 0,
  );
}

RouteOption routeOptionFromJson(Map<String, dynamic> json) {
  return RouteOption(
    id: json['id'] as String,
    totalDurationMinutes: (json['totalDurationMinutes'] as num).toInt(),
    totalDistanceMeters: (json['totalDistanceMeters'] as num).toInt(),
    totalCostBs: (json['totalCostBs'] as num).toDouble(),
    safetyScore: (json['safetyScore'] as num?)?.toDouble() ?? 0,
    avoidsIncidents: (json['avoidsIncidents'] as List<dynamic>? ?? [])
        .map((incidentId) => incidentId as String)
        .toList(),
    legs: (json['legs'] as List<dynamic>? ?? [])
        .map((leg) => _routeLegFromJson(leg as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> routeOptionToJson(RouteOption option) {
  return {
    'id': option.id,
    'totalDurationMinutes': option.totalDurationMinutes,
    'totalDistanceMeters': option.totalDistanceMeters,
    'totalCostBs': option.totalCostBs,
    'safetyScore': option.safetyScore,
    'avoidsIncidents': option.avoidsIncidents,
    'legs': option.legs.map(_routeLegToJson).toList(),
  };
}

RouteLeg _routeLegFromJson(Map<String, dynamic> json) {
  return RouteLeg(
    mode: TransportMode.fromApi(json['mode'] as String),
    durationMinutes: (json['durationMinutes'] as num).toInt(),
    distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
    costBs: (json['costBs'] as num?)?.toDouble() ?? 0,
    polyline: json['polyline'] as String? ?? '',
    instruction: json['instruction'] as String? ?? '',
    lineId: json['lineId'] as String?,
    lineName: json['lineName'] as String?,
    lineColor: json['lineColor'] as String?,
    boardStop: _stopRefFromJson(json['boardStop'] as Map<String, dynamic>?),
    alightStop: _stopRefFromJson(json['alightStop'] as Map<String, dynamic>?),
  );
}

Map<String, dynamic> _routeLegToJson(RouteLeg leg) {
  return {
    'mode': leg.mode.apiValue,
    'durationMinutes': leg.durationMinutes,
    'distanceMeters': leg.distanceMeters,
    'costBs': leg.costBs,
    'polyline': leg.polyline,
    'instruction': leg.instruction,
    if (leg.lineId != null) 'lineId': leg.lineId,
    if (leg.lineName != null) 'lineName': leg.lineName,
    if (leg.lineColor != null) 'lineColor': leg.lineColor,
    if (leg.boardStop != null)
      'boardStop': {'id': leg.boardStop!.id, 'name': leg.boardStop!.name},
    if (leg.alightStop != null)
      'alightStop': {'id': leg.alightStop!.id, 'name': leg.alightStop!.name},
  };
}

StopRef? _stopRefFromJson(Map<String, dynamic>? json) {
  if (json == null) {
    return null;
  }
  return StopRef(id: json['id'] as String, name: json['name'] as String);
}
