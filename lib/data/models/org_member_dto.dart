import '../../domain/entities/org_member.dart';

class OrgMemberDto {
  final String orgId;
  final String userId;
  final String role;

  OrgMemberDto({
    required this.orgId,
    required this.userId,
    required this.role,
  });

  factory OrgMemberDto.fromJson(Map<String, dynamic> json) {
    return OrgMemberDto(
      orgId: json['org_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'org_id': orgId,
      'user_id': userId,
      'role': role,
    };
  }

  OrgMember toEntity() {
    return OrgMember(
      orgId: orgId,
      userId: userId,
      role: OrgRole.fromString(role),
    );
  }
}
