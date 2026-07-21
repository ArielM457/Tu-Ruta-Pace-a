import '../types/coordinate.dart';

List<Coordinate> decodePolyline(String encoded) {
  final points = <Coordinate>[];
  final reader = _PolylineReader(encoded);
  int latitude = 0;
  int longitude = 0;
  while (reader.hasMore) {
    latitude += reader.readSignedNumber();
    longitude += reader.readSignedNumber();
    points.add(Coordinate(lat: latitude / 1e5, lng: longitude / 1e5));
  }
  return points;
}

class _PolylineReader {
  _PolylineReader(this._encoded);

  final String _encoded;
  int _index = 0;

  bool get hasMore => _index < _encoded.length;

  int readSignedNumber() {
    int result = 0;
    int shift = 0;
    int byte;
    do {
      byte = _encoded.codeUnitAt(_index) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
      _index++;
    } while (byte >= 0x20);
    final isNegative = (result & 1) == 1;
    final value = result >> 1;
    return isNegative ? ~value : value;
  }
}
