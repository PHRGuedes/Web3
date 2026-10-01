/// Model DTO para envio de credenciais de login.
class LoginRequest {
  final String email;
  final String senha;

  const LoginRequest({
    required this.email,
    required this.senha,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: (json['email'] ?? '') as String,
      senha: (json['senha'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'senha': senha,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginRequest &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          senha == other.senha;

  @override
  int get hashCode => email.hashCode ^ senha.hashCode;
}
