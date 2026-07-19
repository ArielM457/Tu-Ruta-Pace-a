class LocationShare {
  const LocationShare({
    required this.id,
    required this.tripId,
    required this.lineId,
    required this.startedAt,
    this.endedAt,
    this.pointsAwarded,
    this.newBalance,
  });

  final String id;
  final String tripId;
  final String lineId;
  final String startedAt;
  final String? endedAt;
  final int? pointsAwarded;
  final int? newBalance;

  bool get isActive => endedAt == null;

  factory LocationShare.fromJson(Map<String, dynamic> json) {
    return LocationShare(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      lineId: json['lineId'] as String,
      startedAt: json['startedAt'] as String,
      endedAt: json['endedAt'] as String?,
      pointsAwarded: json['pointsAwarded'] as int?,
      newBalance: json['newBalance'] as int?,
    );
  }
}

enum AyniReason {
  sharedLocation,
  queriedVehicle,
  askedQuestion,
  answeredQuestion,
  questionRefunded,
  verifiedReport,
  confirmedIncident,
  bonus;

  static AyniReason fromApi(String value) {
    switch (value) {
      case 'shared_location':
        return AyniReason.sharedLocation;
      case 'queried_vehicle':
        return AyniReason.queriedVehicle;
      case 'asked_question':
        return AyniReason.askedQuestion;
      case 'answered_question':
        return AyniReason.answeredQuestion;
      case 'question_refunded':
        return AyniReason.questionRefunded;
      case 'verified_report':
        return AyniReason.verifiedReport;
      case 'confirmed_incident':
        return AyniReason.confirmedIncident;
      default:
        return AyniReason.bonus;
    }
  }

  String get label {
    switch (this) {
      case AyniReason.sharedLocation:
        return 'Compartiste tu ubicación';
      case AyniReason.queriedVehicle:
        return 'Consultaste un vehículo';
      case AyniReason.askedQuestion:
        return 'Preguntaste a la comunidad';
      case AyniReason.answeredQuestion:
        return 'Respondiste una pregunta';
      case AyniReason.questionRefunded:
        return 'Reembolso — nadie respondió';
      case AyniReason.verifiedReport:
        return 'Tu reporte fue verificado';
      case AyniReason.confirmedIncident:
        return 'Verificaste un reporte activo';
      case AyniReason.bonus:
        return 'Bono de Puntos Chass';
    }
  }

  String get emoji {
    switch (this) {
      case AyniReason.sharedLocation:
        return '📍';
      case AyniReason.queriedVehicle:
        return '🔎';
      case AyniReason.askedQuestion:
        return '❓';
      case AyniReason.answeredQuestion:
        return '💬';
      case AyniReason.questionRefunded:
        return '↩️';
      case AyniReason.verifiedReport:
        return '🚧';
      case AyniReason.confirmedIncident:
        return '✅';
      case AyniReason.bonus:
        return '🎁';
    }
  }
}

class AyniMovement {
  const AyniMovement({
    required this.id,
    required this.amount,
    required this.reason,
    this.referenceId,
    required this.createdAt,
  });

  final String id;
  final int amount;
  final AyniReason reason;
  final String? referenceId;
  final String createdAt;

  factory AyniMovement.fromJson(Map<String, dynamic> json) {
    return AyniMovement(
      id: json['id'] as String,
      amount: json['amount'] as int,
      reason: AyniReason.fromApi(json['reason'] as String),
      referenceId: json['referenceId'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

class AyniHistoryPage {
  const AyniHistoryPage({
    required this.balance,
    required this.movements,
    required this.page,
    required this.pageSize,
  });

  final int balance;
  final List<AyniMovement> movements;
  final int page;
  final int pageSize;

  factory AyniHistoryPage.fromJson(Map<String, dynamic> json) {
    return AyniHistoryPage(
      balance: json['balance'] as int,
      movements: (json['movements'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(AyniMovement.fromJson)
          .toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }
}
