import '../../../core/types/coordinate.dart';

class Favorite {
  const Favorite({
    required this.id,
    required this.name,
    required this.coordinate,
    required this.createdAt,
  });

  final String id;
  final String name;
  final Coordinate coordinate;
  final DateTime createdAt;

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String,
      name: json['name'] as String,
      coordinate: Coordinate(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
