class MemberModel {
  const MemberModel({
    required this.userId,
    required this.fullName,
    required this.role,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
      );

  final String userId;
  final String fullName;
  final String role;
}

class HouseholdModel {
  const HouseholdModel({
    required this.id,
    required this.name,
    required this.myRole,
    required this.members,
    this.inviteCode,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) => HouseholdModel(
        id: json['id'] as String,
        name: json['name'] as String,
        myRole: json['myRole'] as String,
        inviteCode: json['inviteCode'] as String?,
        members: (json['members'] as List)
            .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final String name;
  final String myRole;
  final String? inviteCode;
  final List<MemberModel> members;

  bool get isOwner => myRole == 'OWNER';
}
