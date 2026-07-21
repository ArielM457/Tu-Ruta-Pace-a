import '../../../core/types/coordinate.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.description,
    required this.placeId,
    required this.coordinate,
  });

  final String description;
  final String placeId;
  final Coordinate coordinate;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      description: json['description'] as String,
      placeId: json['placeId'] as String,
      coordinate: Coordinate(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      ),
    );
  }
}
