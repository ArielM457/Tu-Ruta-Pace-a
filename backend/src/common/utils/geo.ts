import { Coordinate } from '../types/domain';

const EARTH_RADIUS_METERS = 6371000;

export function haversineMeters(from: Coordinate, to: Coordinate): number {
  const latitudeDelta = toRadians(to.lat - from.lat);
  const longitudeDelta = toRadians(to.lng - from.lng);
  const halfChord =
    Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(toRadians(from.lat)) *
      Math.cos(toRadians(to.lat)) *
      Math.sin(longitudeDelta / 2) ** 2;
  const angularDistance =
    2 * Math.atan2(Math.sqrt(halfChord), Math.sqrt(1 - halfChord));
  return Math.round(EARTH_RADIUS_METERS * angularDistance);
}

export function pathMeters(points: Coordinate[]): number {
  let total = 0;
  for (let index = 1; index < points.length; index += 1) {
    total += haversineMeters(points[index - 1], points[index]);
  }
  return total;
}

export function midpoint(from: Coordinate, to: Coordinate): Coordinate {
  return { lat: (from.lat + to.lat) / 2, lng: (from.lng + to.lng) / 2 };
}

function toRadians(degrees: number): number {
  return (degrees * Math.PI) / 180;
}
