import 'package:flutter/material.dart';

enum IncidentKind {
  blockade,
  protest,
  roadwork,
  officialClosure;

  String get apiValue {
    switch (this) {
      case IncidentKind.blockade:
        return 'blockade';
      case IncidentKind.protest:
        return 'protest';
      case IncidentKind.roadwork:
        return 'roadwork';
      case IncidentKind.officialClosure:
        return 'official_closure';
    }
  }

  static IncidentKind fromApi(String value) {
    switch (value) {
      case 'blockade':
        return IncidentKind.blockade;
      case 'protest':
        return IncidentKind.protest;
      case 'roadwork':
        return IncidentKind.roadwork;
      case 'official_closure':
        return IncidentKind.officialClosure;
      default:
        return IncidentKind.blockade;
    }
  }

  String get label {
    switch (this) {
      case IncidentKind.blockade:
        return 'Bloqueo';
      case IncidentKind.protest:
        return 'Protesta';
      case IncidentKind.roadwork:
        return 'Refacción';
      case IncidentKind.officialClosure:
        return 'Cierre oficial';
    }
  }

  String get emoji {
    switch (this) {
      case IncidentKind.blockade:
        return '🚧';
      case IncidentKind.protest:
        return '📣';
      case IncidentKind.roadwork:
        return '🔨';
      case IncidentKind.officialClosure:
        return '🚫';
    }
  }

  Color get markerColor {
    switch (this) {
      case IncidentKind.blockade:
        return const Color(0xFFD32F2F);
      case IncidentKind.protest:
        return const Color(0xFFF57C00);
      case IncidentKind.roadwork:
        return const Color(0xFFF9A825);
      case IncidentKind.officialClosure:
        return const Color(0xFF1565C0);
    }
  }

  double get markerHue {
    switch (this) {
      case IncidentKind.blockade:
        return 0; // red
      case IncidentKind.protest:
        return 30; // orange
      case IncidentKind.roadwork:
        return 60; // yellow
      case IncidentKind.officialClosure:
        return 210; // azure/blue
    }
  }

  Color get chipColor {
    switch (this) {
      case IncidentKind.blockade:
        return const Color(0xFFFFEBEE);
      case IncidentKind.protest:
        return const Color(0xFFFFF3E0);
      case IncidentKind.roadwork:
        return const Color(0xFFFFFDE7);
      case IncidentKind.officialClosure:
        return const Color(0xFFE3F2FD);
    }
  }

  Color get chipTextColor {
    switch (this) {
      case IncidentKind.blockade:
        return const Color(0xFFB71C1C);
      case IncidentKind.protest:
        return const Color(0xFFE65100);
      case IncidentKind.roadwork:
        return const Color(0xFFF57F17);
      case IncidentKind.officialClosure:
        return const Color(0xFF0D47A1);
    }
  }
}

enum IncidentStatus {
  pending,
  active,
  resolved,
  rejected;

  String get apiValue {
    switch (this) {
      case IncidentStatus.pending:
        return 'pending';
      case IncidentStatus.active:
        return 'active';
      case IncidentStatus.resolved:
        return 'resolved';
      case IncidentStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case IncidentStatus.pending:
        return 'Pendiente';
      case IncidentStatus.active:
        return 'Activo';
      case IncidentStatus.resolved:
        return 'Resuelto';
      case IncidentStatus.rejected:
        return 'Rechazado';
    }
  }

  static IncidentStatus fromApi(String value) {
    switch (value) {
      case 'pending':
        return IncidentStatus.pending;
      case 'active':
        return IncidentStatus.active;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'rejected':
        return IncidentStatus.rejected;
      default:
        return IncidentStatus.pending;
    }
  }
}

enum IncidentSource {
  citizen,
  official;

  static IncidentSource fromApi(String value) =>
      value == 'official' ? IncidentSource.official : IncidentSource.citizen;

  String get label =>
      this == IncidentSource.official ? 'Cierre oficial' : 'Ciudadano verificado';
}

class Incident {
  final String id;
  final IncidentKind kind;
  final IncidentStatus status;
  final IncidentSource source;
  final double lat;
  final double lng;
  final String description;
  final String? photoUrl;
  final int confirmations;
  final int denials;
  final String startsAt;
  final String expiresAt;
  final String createdAt;

  const Incident({
    required this.id,
    required this.kind,
    required this.status,
    required this.source,
    required this.lat,
    required this.lng,
    required this.description,
    this.photoUrl,
    required this.confirmations,
    required this.denials,
    required this.startsAt,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>;
    return Incident(
      id: json['id'] as String,
      kind: IncidentKind.fromApi(json['kind'] as String),
      status: IncidentStatus.fromApi(json['status'] as String),
      source: IncidentSource.fromApi(json['source'] as String),
      lat: (position['lat'] as num).toDouble(),
      lng: (position['lng'] as num).toDouble(),
      description: json['description'] as String,
      photoUrl: json['photoUrl'] as String?,
      confirmations: json['confirmations'] as int,
      denials: json['denials'] as int,
      startsAt: json['startsAt'] as String,
      expiresAt: json['expiresAt'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Incident copyWith({int? confirmations, int? denials, IncidentStatus? status}) {
    return Incident(
      id: id,
      kind: kind,
      status: status ?? this.status,
      source: source,
      lat: lat,
      lng: lng,
      description: description,
      photoUrl: photoUrl,
      confirmations: confirmations ?? this.confirmations,
      denials: denials ?? this.denials,
      startsAt: startsAt,
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }
}
