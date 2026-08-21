import 'package:equatable/equatable.dart';

enum OrgRole {
  orgAdmin('org_admin'),
  member('member');

  final String value;
  const OrgRole(this.value);

  static OrgRole fromString(String val) {
    if (val == 'org_admin') return OrgRole.orgAdmin;
    return OrgRole.member;
  }
}

class OrgMember extends Equatable {
  final String orgId;
  final String userId;
  final OrgRole role;

  const OrgMember({
    required this.orgId,
    required this.userId,
    required this.role,
  });

  bool get isAdmin => role == OrgRole.orgAdmin;

  @override
  List<Object?> get props => [orgId, userId, role];
}
