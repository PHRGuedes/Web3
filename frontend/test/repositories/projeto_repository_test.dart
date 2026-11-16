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

    test('criarProjeto (POST) envia dados com token no cabeçalho e retorna Projeto criado', () async {
      final jsonResponse = jsonEncode({
        'id': 10,
        'nome': 'Novo Projeto de Teste',
        'descricao': 'Descrição do novo projeto',
        'usuario_id': 1,
        'created_at': '2026-11-16T15:00:00.000Z',
      });

      when(() => mockClient.post(
            Uri.parse('$baseUrl/projetos/'),
            headers: any(
              named: 'headers',
              that: containsPair('Authorization', 'Bearer token_teste_123'),
            ),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonResponse, 201));

      final resultado = await repository.criarProjeto(
        token: 'token_teste_123',
        nome: 'Novo Projeto de Teste',
        descricao: 'Descrição do novo projeto',
      );

      expect(resultado.id, 10);
      expect(resultado.nome, 'Novo Projeto de Teste');
      expect(resultado.descricao, 'Descrição do novo projeto');

      verify(() => mockClient.post(
            Uri.parse('$baseUrl/projetos/'),
            headers: any(
              named: 'headers',
              that: containsPair('Authorization', 'Bearer token_teste_123'),
            ),
            body: jsonEncode({
              'nome': 'Novo Projeto de Teste',
              'descricao': 'Descrição do novo projeto',
            }),
          )).called(1);
    });

    test('criarProjeto lança ApiException com status 409 e frase da API em caso de nome duplicado', () async {
      when(() => mockClient.post(
            Uri.parse('$baseUrl/projetos/'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'erro': 'RN01_NOME_DUPLICADO',
              'mensagem': "Já existe um projeto cadastrado com o nome 'ReqFlow' para este usuário (RN01).",
            }),
            409,
          ));

      expect(
        () => repository.criarProjeto(
          token: 'token_teste_123',
          nome: 'ReqFlow',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.message, 'message',
                equals("Já existe um projeto cadastrado com o nome 'ReqFlow' para este usuário (RN01)."))),
      );
    });

    test('criarProjeto lança ApiException com status 422 e frase da API em caso de dados inválidos', () async {
      when(() => mockClient.post(
            Uri.parse('$baseUrl/projetos/'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'erro': 'VALIDACAO_FALHOU',
              'mensagem': 'Falha na validação dos dados de entrada.',
              'detalhes': [
                {'campo': 'nome', 'mensagem': 'String should have at least 2 characters'}
              ]
            }),
            422,
          ));

      expect(
        () => repository.criarProjeto(
          token: 'token_teste_123',
          nome: 'A',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.message, 'message',
                equals('String should have at least 2 characters'))),
      );
    });

    test('atualizarProjeto (PATCH) envia dados com token no cabeçalho e retorna Projeto atualizado', () async {
      final jsonResponse = jsonEncode({
        'id': 10,
        'nome': 'Nome Atualizado',
        'descricao': 'Nova Descrição',
        'usuario_id': 1,
        'created_at': '2026-11-16T15:00:00.000Z',
      });

      when(() => mockClient.patch(
            Uri.parse('$baseUrl/projetos/10'),
            headers: any(
              named: 'headers',
              that: containsPair('Authorization', 'Bearer token_teste_123'),
            ),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonResponse, 200));

      final resultado = await repository.atualizarProjeto(
        token: 'token_teste_123',
        projetoId: 10,
        nome: 'Nome Atualizado',
        descricao: 'Nova Descrição',
      );

      expect(resultado.id, 10);
      expect(resultado.nome, 'Nome Atualizado');
      expect(resultado.descricao, 'Nova Descrição');

      verify(() => mockClient.patch(
            Uri.parse('$baseUrl/projetos/10'),
            headers: any(
              named: 'headers',
              that: containsPair('Authorization', 'Bearer token_teste_123'),
            ),
            body: jsonEncode({
              'nome': 'Nome Atualizado',
              'descricao': 'Nova Descrição',
            }),
          )).called(1);
    });

    test('deletarProjeto (DELETE) envia requisição com token e completa com sucesso em 204', () async {
      when(() => mockClient.delete(
            Uri.parse('$baseUrl/projetos/10'),
            headers: any(
              named: 'headers',
              that: containsPair('Authorization', 'Bearer token_teste_123'),
            ),
          )).thenAnswer((_) async => http.Response('', 204));

      await repository.deletarProjeto(
        token: 'token_teste_123',
        projetoId: 10,
      );

      verify(() => mockClient.delete(
            Uri.parse('$baseUrl/projetos/10'),
            headers: any(
              named: 'headers',
              that: containsPair('Authorization', 'Bearer token_teste_123'),
            ),
          )).called(1);
    });
  });
}
