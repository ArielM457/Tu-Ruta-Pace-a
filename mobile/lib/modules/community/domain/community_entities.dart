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

enum CommunityBadge {
  hero,
  active,
  collaborator,
  member,
  newcomer;

  static CommunityBadge fromApi(String value) {
    switch (value) {
      case 'hero':
        return CommunityBadge.hero;
      case 'active':
        return CommunityBadge.active;
      case 'collaborator':
        return CommunityBadge.collaborator;
      case 'member':
        return CommunityBadge.member;
      default:
        return CommunityBadge.newcomer;
    }
  }

  String get label {
    switch (this) {
      case CommunityBadge.hero:
        return 'Héroe';
      case CommunityBadge.active:
        return 'Activo';
      case CommunityBadge.collaborator:
        return 'Colaborador';
      case CommunityBadge.member:
        return 'Miembro';
      case CommunityBadge.newcomer:
        return 'Nuevo';
    }
  }
}

const int _heroBadgeThreshold = 800;
const int _activeBadgeThreshold = 500;
const int _collaboratorBadgeThreshold = 400;
const int _memberBadgeThreshold = 250;

CommunityBadge communityBadgeForPoints(int points) {
  if (points >= _heroBadgeThreshold) return CommunityBadge.hero;
  if (points >= _activeBadgeThreshold) return CommunityBadge.active;
  if (points >= _collaboratorBadgeThreshold) return CommunityBadge.collaborator;
  if (points >= _memberBadgeThreshold) return CommunityBadge.member;
  return CommunityBadge.newcomer;
}

class CommunityRankingEntry {
  const CommunityRankingEntry({
    required this.userId,
    required this.displayName,
    required this.points,
    required this.rank,
    required this.badge,
  });

  final String userId;
  final String displayName;
  final int points;
  final int rank;
  final CommunityBadge badge;

  factory CommunityRankingEntry.fromJson(Map<String, dynamic> json) {
    return CommunityRankingEntry(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      points: json['points'] as int,
      rank: json['rank'] as int,
      badge: CommunityBadge.fromApi(json['badge'] as String),
    );
  }
}

class CommunityRanking {
  const CommunityRanking({required this.top, required this.requester});

  final List<CommunityRankingEntry> top;
  final CommunityRankingEntry requester;

  factory CommunityRanking.fromJson(Map<String, dynamic> json) {
    return CommunityRanking(
      top: (json['top'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(CommunityRankingEntry.fromJson)
          .toList(),
      requester: CommunityRankingEntry.fromJson(
        json['requester'] as Map<String, dynamic>,
      ),
    );
  }
}

class CommunityFeedEntry {
  const CommunityFeedEntry({
    required this.id,
    required this.displayName,
    required this.reason,
    required this.points,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String reason;
  final int points;
  final String createdAt;

  factory CommunityFeedEntry.fromJson(Map<String, dynamic> json) {
    return CommunityFeedEntry(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      reason: json['reason'] as String,
      points: json['points'] as int,
      createdAt: json['createdAt'] as String,
    );
  }
}

class PointsConfig {
  const PointsConfig({
    required this.reportReward,
    required this.verifyReward,
    required this.answerReward,
    required this.askCost,
  });

  final int reportReward;
  final int verifyReward;
  final int answerReward;
  final int askCost;

  factory PointsConfig.fromJson(Map<String, dynamic> json) {
    return PointsConfig(
      reportReward: json['reportReward'] as int,
      verifyReward: json['verifyReward'] as int,
      answerReward: json['answerReward'] as int,
      askCost: json['askCost'] as int,
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
