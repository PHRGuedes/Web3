/// Model que encapsula o token JWT retornado no login.
class AuthToken {
  final String accessToken;
  final String tokenType;

  const AuthToken({
    required this.accessToken,
    this.tokenType = 'bearer',
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: (json['access_token'] ?? json['accessToken'] ?? '') as String,
      tokenType: (json['token_type'] ?? json['tokenType'] ?? 'bearer') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthToken &&
          runtimeType == other.runtimeType &&
          accessToken == other.accessToken &&
          tokenType == other.tokenType;

  @override
  int get hashCode => accessToken.hashCode ^ tokenType.hashCode;

  @override
  String toString() => 'AuthToken(tokenType: $tokenType, accessToken: ${accessToken.substring(0, accessToken.length > 10 ? 10 : accessToken.length)}...)';
}
