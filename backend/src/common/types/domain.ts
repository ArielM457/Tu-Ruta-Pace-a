export enum TravelPriority {
  Time = 'time',
  Cost = 'cost',
  Safety = 'safety',
}

export enum AccessibilityProfile {
  None = 'none',
  Visual = 'visual',
  ReducedMobility = 'reduced_mobility',
}

export enum UserRole {
  Citizen = 'citizen',
  Government = 'government',
}

export enum TransportMode {
  Walk = 'walk',
  CableCar = 'cable_car',
  Pumakatari = 'pumakatari',
  Minibus = 'minibus',
  Micro = 'micro',
  Trufi = 'trufi',
  Taxi = 'taxi',
}

export enum TransportKind {
  CableCar = 'cable_car',
  Pumakatari = 'pumakatari',
  Minibus = 'minibus',
  Micro = 'micro',
  Trufi = 'trufi',
  RadiotaxiZone = 'radiotaxi_zone',
}

export enum IncidentKind {
  Blockade = 'blockade',
  Protest = 'protest',
  Roadwork = 'roadwork',
  OfficialClosure = 'official_closure',
}

export enum IncidentStatus {
  Pending = 'pending',
  Active = 'active',
  Resolved = 'resolved',
  Rejected = 'rejected',
}

export enum IncidentSource {
  Citizen = 'citizen',
  Official = 'official',
  News = 'news',
}

export enum IncidentVote {
  Confirm = 'confirm',
  Deny = 'deny',
}

export enum TripStatus {
  Active = 'active',
  Finished = 'finished',
  Cancelled = 'cancelled',
}

export enum CommunityQuestionKind {
  Availability = 'availability',
  ArrivalTime = 'arrival_time',
  Seats = 'seats',
}

export enum CommunityQuestionStatus {
  Open = 'open',
  Answered = 'answered',
  Expired = 'expired',
}

export enum ComplaintTransportKind {
  CableCar = 'cable_car',
  Pumakatari = 'pumakatari',
  Minibus = 'minibus',
  Micro = 'micro',
  Trufi = 'trufi',
  Taxi = 'taxi',
}

export enum ComplaintType {
  AggressiveDriver = 'aggressive_driver',
  Overcharge = 'overcharge',
  RouteNotRespected = 'route_not_respected',
  PoorVehicleCondition = 'poor_vehicle_condition',
  Harassment = 'harassment',
  Other = 'other',
}

export enum ComplaintStatus {
  InReview = 'in_review',
  Resolved = 'resolved',
  Closed = 'closed',
}

export interface Coordinate {
  lat: number;
  lng: number;
}

export interface AuthenticatedUser {
  userId: string;
  role: UserRole;
}
