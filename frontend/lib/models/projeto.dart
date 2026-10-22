/// Modelo representativo da entidade Projeto do sistema ReqFlow.
/// REGRA ARQUITETURAL: Camada de modelo pura (DTO/Entidade), sem chamadas de rede ou lógica de UI.
class Projeto {
  final int id;
  final String nome;
  final String? descricao;
  final int usuarioId;
  final DateTime createdAt;

  const Projeto({
    required this.id,
    required this.nome,
    this.descricao,
    required this.usuarioId,
    required this.createdAt,
  });

  factory Projeto.fromJson(Map<String, dynamic> json) {
    return Projeto(
      id: json['id'] as int,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      usuarioId: json['usuario_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'usuario_id': usuarioId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Projeto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          descricao == other.descricao &&
          usuarioId == other.usuarioId &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      nome.hashCode ^
      descricao.hashCode ^
      usuarioId.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'Projeto(id: $id, nome: $nome, descricao: $descricao, usuarioId: $usuarioId, createdAt: $createdAt)';
}
