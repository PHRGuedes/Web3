import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/repositories/projeto_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late ProjetoRepository repository;
  const baseUrl = 'http://localhost:8000';

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost:8000'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    repository = ProjetoRepository(baseUrl: baseUrl, client: mockClient);
  });

  group('ProjetoRepository Unit Tests', () {
    test('listarProjetos retorna lista de Projetos ao receber 200 OK', () async {
      final jsonResponse = jsonEncode([
        {
          'id': 1,
          'nome': 'Projeto Alfa',
          'descricao': 'Descrição Alfa',
          'usuario_id': 10,
          'created_at': '2026-10-22T10:00:00.000Z',
        },
        {
          'id': 2,
          'nome': 'Projeto Beta',
          'descricao': null,
          'usuario_id': 10,
          'created_at': '2026-10-22T11:00:00.000Z',
        }
      ]);

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonResponse, 200));

      final resultado = await repository.listarProjetos(token: 'jwt_token_123');

      expect(resultado.length, 2);
      expect(resultado[0].id, 1);
      expect(resultado[0].nome, 'Projeto Alfa');
      expect(resultado[1].id, 2);
      expect(resultado[1].descricao, isNull);
    });

    test('listarProjetos anexa token de autorização nos cabeçalhos', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('[]', 200));

      await repository.listarProjetos(token: 'token_secreto_777', searchNome: 'Filtro');

      verify(() => mockClient.get(
            any(that: predicate<Uri>((uri) => uri.queryParameters['nome'] == 'Filtro')),
            headers: any(
              named: 'headers',
              that: containsPair('Authorization', 'Bearer token_secreto_777'),
            ),
          )).called(1);
    });

    test('listarProjetos lança ApiException com status 401 ao receber Unauthorized', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'detail': 'Token inválido ou expirado'}),
            401,
          ));

      expect(
        () => repository.listarProjetos(token: 'token_expirado'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', contains('Token inválido'))),
      );
    });

    test('obterProjeto retorna Projeto específico ao receber 200 OK', () async {
      final jsonResponse = jsonEncode({
        'id': 42,
        'nome': 'Projeto Específico',
        'descricao': 'Detalhes específicos',
        'usuario_id': 5,
        'created_at': '2026-10-22T14:00:00.000Z',
      });

      when(() => mockClient.get(
            Uri.parse('$baseUrl/projetos/42'),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonResponse, 200));

      final projeto = await repository.obterProjeto(token: 'token_valido', projetoId: 42);

      expect(projeto.id, 42);
      expect(projeto.nome, 'Projeto Específico');
      expect(projeto.descricao, 'Detalhes específicos');
    });

    test('obterProjeto lança ApiException com status 404 quando o projeto não for encontrado', () async {
      when(() => mockClient.get(
            Uri.parse('$baseUrl/projetos/999'),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'detail': 'Projeto não encontrado'}),
            404,
          ));

      expect(
        () => repository.obterProjeto(token: 'token_valido', projetoId: 999),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', contains('Projeto não encontrado'))),
      );
    });
  });
}
