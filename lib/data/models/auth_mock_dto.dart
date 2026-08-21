class TestCredentialDto {
  final String email;
  final String password;
  final String orgId;
  final String role;

  TestCredentialDto({
    required this.email,
    required this.password,
    required this.orgId,
    required this.role,
  });

  factory TestCredentialDto.fromJson(Map<String, dynamic> json) {
    return TestCredentialDto(
      email: json['email'] as String,
      password: json['password'] as String,
      orgId: json['org_id'] as String,
      role: json['role'] as String,
    );
  }
}

class MockLoginResponseDto {
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
  final int refreshTokenExpiresInSeconds;

  MockLoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
  });

  factory MockLoginResponseDto.fromJson(Map<String, dynamic> json) {
    return MockLoginResponseDto(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresInSeconds: json['access_token_expires_in_seconds'] as int,
      refreshTokenExpiresInSeconds: json['refresh_token_expires_in_seconds'] as int,
    );
  }
}
