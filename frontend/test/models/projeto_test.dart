import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/projeto.dart';

void main() {
  group('Projeto Model Unit Tests', () {
    test('Projeto serializa e deserializa corretamente via fromJson e toJson', () {
      final json = {
        'id': 42,
        'nome': 'Sistema de Gestão de Requisitos',
        'descricao': 'Especificação funcional e rastreabilidade ágil.',
        'usuario_id': 7,
        'created_at': '2026-10-22T12:00:00.000Z',
      };

      final projeto = Projeto.fromJson(json);

      expect(projeto.id, 42);
      expect(projeto.nome, 'Sistema de Gestão de Requisitos');
      expect(projeto.descricao, 'Especificação funcional e rastreabilidade ágil.');
      expect(projeto.usuarioId, 7);
      expect(projeto.createdAt, DateTime.parse('2026-10-22T12:00:00.000Z'));

      final outputJson = projeto.toJson();
      expect(outputJson['id'], 42);
      expect(outputJson['nome'], 'Sistema de Gestão de Requisitos');
      expect(outputJson['descricao'], 'Especificação funcional e rastreabilidade ágil.');
      expect(outputJson['usuario_id'], 7);
      expect(outputJson['created_at'], '2026-10-22T12:00:00.000Z');
    });

    test('Projeto aceita descricao nula', () {
      final json = {
        'id': 1,
        'nome': 'Projeto Sem Descrição',
        'descricao': null,
        'usuario_id': 2,
        'created_at': '2026-10-22T10:00:00.000Z',
      };

      final projeto = Projeto.fromJson(json);
      expect(projeto.descricao, isNull);
      expect(projeto.toJson()['descricao'], isNull);
    });

    test('Operador de igualdade e hashCode comparam por valores', () {
      final p1 = Projeto(
        id: 1,
        nome: 'Projeto A',
        descricao: 'Desc',
        usuarioId: 10,
        createdAt: DateTime(2026, 10, 22),
      );

      final p2 = Projeto(
        id: 1,
        nome: 'Projeto A',
        descricao: 'Desc',
        usuarioId: 10,
        createdAt: DateTime(2026, 10, 22),
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
