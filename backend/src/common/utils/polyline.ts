import { Coordinate } from '../types/domain';

export function encodePolyline(points: Coordinate[]): string {
  let previousLatitude = 0;
  let previousLongitude = 0;
  let encoded = '';
  for (const point of points) {
    const latitude = Math.round(point.lat * 1e5);
    const longitude = Math.round(point.lng * 1e5);
    encoded += encodeSignedNumber(latitude - previousLatitude);
    encoded += encodeSignedNumber(longitude - previousLongitude);
    previousLatitude = latitude;
    previousLongitude = longitude;
  }
  return encoded;
}

function encodeSignedNumber(value: number): string {
  let shifted = value << 1;
  if (value < 0) {
    shifted = ~shifted;
  }
  let output = '';
  while (shifted >= 0x20) {
    output += String.fromCharCode((0x20 | (shifted & 0x1f)) + 63);
    shifted >>= 5;
  }
  output += String.fromCharCode(shifted + 63);
  return output;
}
