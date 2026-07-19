enum CommunityQuestionKind {
  availability,
  arrivalTime,
  seats;

  String get apiValue {
    switch (this) {
      case CommunityQuestionKind.availability:
        return 'availability';
      case CommunityQuestionKind.arrivalTime:
        return 'arrival_time';
      case CommunityQuestionKind.seats:
        return 'seats';
    }
  }

  static CommunityQuestionKind fromApi(String value) {
    switch (value) {
      case 'availability':
        return CommunityQuestionKind.availability;
      case 'arrival_time':
        return CommunityQuestionKind.arrivalTime;
      case 'seats':
        return CommunityQuestionKind.seats;
      default:
        return CommunityQuestionKind.availability;
    }
  }

  String get label {
    switch (this) {
      case CommunityQuestionKind.availability:
        return '¿Viene el transporte?';
      case CommunityQuestionKind.arrivalTime:
        return '¿En cuánto tiempo llega?';
      case CommunityQuestionKind.seats:
        return '¿Hay asientos?';
    }
  }

  String get emoji {
    switch (this) {
      case CommunityQuestionKind.availability:
        return '🚌';
      case CommunityQuestionKind.arrivalTime:
        return '⏱️';
      case CommunityQuestionKind.seats:
        return '💺';
    }
  }
}

enum CommunityQuestionStatus {
  open,
  answered,
  expired;

  static CommunityQuestionStatus fromApi(String value) {
    switch (value) {
      case 'open':
        return CommunityQuestionStatus.open;
      case 'answered':
        return CommunityQuestionStatus.answered;
      case 'expired':
        return CommunityQuestionStatus.expired;
      default:
        return CommunityQuestionStatus.open;
    }
  }

  String get label {
    switch (this) {
      case CommunityQuestionStatus.open:
        return 'En espera';
      case CommunityQuestionStatus.answered:
        return 'Respondida';
      case CommunityQuestionStatus.expired:
        return 'Reembolsada';
    }
  }
}

class CommunityAnswer {
  const CommunityAnswer({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String content;
  final String createdAt;

  factory CommunityAnswer.fromJson(Map<String, dynamic> json) {
    return CommunityAnswer(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

class CommunityQuestion {
  const CommunityQuestion({
    required this.id,
    required this.lineId,
    this.lineName,
    required this.kind,
    this.content,
    required this.pointsCost,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.answeredAt,
    required this.answers,
  });

  final String id;
  final String lineId;
  final String? lineName;
  final CommunityQuestionKind kind;
  final String? content;
  final int pointsCost;
  final CommunityQuestionStatus status;
  final String createdAt;
  final String expiresAt;
  final String? answeredAt;
  final List<CommunityAnswer> answers;

  factory CommunityQuestion.fromJson(Map<String, dynamic> json) {
    return CommunityQuestion(
      id: json['id'] as String,
      lineId: json['lineId'] as String,
      lineName: json['lineName'] as String?,
      kind: CommunityQuestionKind.fromApi(json['kind'] as String),
      content: json['content'] as String?,
      pointsCost: json['pointsCost'] as int,
      status: CommunityQuestionStatus.fromApi(json['status'] as String),
      createdAt: json['createdAt'] as String,
      expiresAt: json['expiresAt'] as String,
      answeredAt: json['answeredAt'] as String?,
      answers: (json['answers'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CommunityAnswer.fromJson)
          .toList(),
    );
  }
}

class LineActivity {
  const LineActivity({required this.lineId, required this.activePeople});

  final String lineId;
  final int activePeople;

  factory LineActivity.fromJson(Map<String, dynamic> json) {
    return LineActivity(
      lineId: json['lineId'] as String,
      activePeople: json['activePeople'] as int,
    );
  }
}

class AnswerQuestionResult {
  const AnswerQuestionResult({
    required this.answer,
    required this.pointsAwarded,
    required this.newBalance,
  });

  final CommunityAnswer answer;
  final int pointsAwarded;
  final int newBalance;

  factory AnswerQuestionResult.fromJson(Map<String, dynamic> json) {
    return AnswerQuestionResult(
      answer:
          CommunityAnswer.fromJson(json['answer'] as Map<String, dynamic>),
      pointsAwarded: json['pointsAwarded'] as int,
      newBalance: json['newBalance'] as int,
    );
  }
}
