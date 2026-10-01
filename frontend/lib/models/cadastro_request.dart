/// Model DTO para criação de uma nova conta de usuário.
class CadastroRequest {
  final String nome;
  final String email;
  final String senha;

  const CadastroRequest({
    required this.nome,
    required this.email,
    required this.senha,
  });

  factory CadastroRequest.fromJson(Map<String, dynamic> json) {
    return CadastroRequest(
      nome: (json['nome'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      senha: (json['senha'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'senha': senha,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CadastroRequest &&
          runtimeType == other.runtimeType &&
          nome == other.nome &&
          email == other.email &&
          senha == other.senha;

  @override
  int get hashCode => nome.hashCode ^ email.hashCode ^ senha.hashCode;
}
