enum FamilyMemberStatus {
  onTrip('on_trip'),
  inactive('inactive'),
  hidden('hidden'),
  pending('pending');

  const FamilyMemberStatus(this.apiValue);

  final String apiValue;

  static FamilyMemberStatus fromApi(String value) =>
      FamilyMemberStatus.values.firstWhere(
        (status) => status.apiValue == value,
        orElse: () => FamilyMemberStatus.hidden,
      );
}

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.relationshipLabel,
    required this.status,
    required this.currentLineName,
    required this.lastPingAt,
    required this.inviteCode,
  });

  final String id;
  final String? userId;
  final String? displayName;
  final String? relationshipLabel;
  final FamilyMemberStatus status;
  final String? currentLineName;
  final DateTime? lastPingAt;
  final String? inviteCode;

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      displayName: json['displayName'] as String?,
      relationshipLabel: json['relationshipLabel'] as String?,
      status: FamilyMemberStatus.fromApi(json['status'] as String),
      currentLineName: json['currentLineName'] as String?,
      lastPingAt: json['lastPingAt'] == null
          ? null
          : DateTime.parse(json['lastPingAt'] as String),
      inviteCode: json['inviteCode'] as String?,
    );
  }
}

class FamilyGroup {
  const FamilyGroup({
    required this.id,
    required this.name,
    required this.members,
  });

  final String id;
  final String name;
  final List<FamilyMember> members;

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      members: (json['members'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(FamilyMember.fromJson)
          .toList(),
    );
  }
}

class FamilyInvite {
  const FamilyInvite({
    required this.id,
    required this.code,
    required this.invitedEmail,
    required this.relationshipLabel,
  });

  final String id;
  final String code;
  final String? invitedEmail;
  final String? relationshipLabel;

  factory FamilyInvite.fromJson(Map<String, dynamic> json) {
    return FamilyInvite(
      id: json['id'] as String,
      code: json['code'] as String,
      invitedEmail: json['invitedEmail'] as String?,
      relationshipLabel: json['relationshipLabel'] as String?,
    );
  }
}
