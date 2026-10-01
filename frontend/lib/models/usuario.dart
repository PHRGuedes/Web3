/// Model de dados de Usuário puro.
/// Representa o schema público retornado pela API FastAPI.
class Usuario {
  final int id;
  final String nome;
  final String email;
  final DateTime? createdAt;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nome: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Usuario &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ nome.hashCode ^ email.hashCode;

  @override
  String toString() => 'Usuario(id: $id, nome: $nome, email: $email)';
}
