import 'package:equatable/equatable.dart';
import 'user.dart';
import 'org_member.dart';

class UserSession extends Equatable {
  final User user;
  final OrgMember memberInfo;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiry;

  const UserSession({
    required this.user,
    required this.memberInfo,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiry,
  });

  bool get isExpired => DateTime.now().isAfter(accessTokenExpiry);
  bool get isAdmin => memberInfo.isAdmin;
  String get orgId => memberInfo.orgId;

  UserSession copyWith({
    User? user,
    OrgMember? memberInfo,
    String? accessToken,
    String? refreshToken,
    DateTime? accessTokenExpiry,
  }) {
    return UserSession(
      user: user ?? this.user,
      memberInfo: memberInfo ?? this.memberInfo,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessTokenExpiry: accessTokenExpiry ?? this.accessTokenExpiry,
    );
  }

  @override
  List<Object?> get props => [user, memberInfo, accessToken, refreshToken, accessTokenExpiry];
}
