class Coordinate {
  const Coordinate({required this.lat, required this.lng});

  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}
