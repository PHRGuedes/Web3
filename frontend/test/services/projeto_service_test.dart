import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/models/projeto.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/repositories/projeto_repository.dart';
import '../../lib/services/projeto_service.dart';
import '../../lib/services/sessao_service.dart';

class MockProjetoRepository extends Mock implements IProjetoRepository {}
class MockSessaoService extends Mock implements SessaoService {}

void main() {
  late MockProjetoRepository mockProjetoRepo;
  late MockSessaoService mockSessaoService;
  late ProjetoService projetoService;

  setUp(() {
    mockProjetoRepo = MockProjetoRepository();
    mockSessaoService = MockSessaoService();
    projetoService = ProjetoService(
      projetoRepository: mockProjetoRepo,
      sessaoService: mockSessaoService,
    );
  });

  group('ProjetoService Unit Tests', () {
    test('listarProjetos delega para repositório quando há token ativo na sessão', () async {
      when(() => mockSessaoService.token).thenReturn('token_sessao_123');

      final listaEsperada = [
        Projeto(
          id: 1,
          nome: 'ReqFlow Web',
          descricao: 'Desc',
          usuarioId: 10,
          createdAt: DateTime(2026, 10, 22),
        ),
      ];

      when(() => mockProjetoRepo.listarProjetos(
            token: 'token_sessao_123',
            searchNome: null,
          )).thenAnswer((_) async => listaEsperada);

      final resultado = await projetoService.listarProjetos();

      expect(resultado, equals(listaEsperada));
      verify(() => mockProjetoRepo.listarProjetos(
            token: 'token_sessao_123',
            searchNome: null,
          )).called(1);
    });

    test('listarProjetos sem token dispara fuga de sessão e lança 401', () async {
      when(() => mockSessaoService.token).thenReturn(null);
      when(() => mockSessaoService.tratarFugaSessao401()).thenAnswer((_) async {});

      expect(
        () => projetoService.listarProjetos(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      verify(() => mockSessaoService.tratarFugaSessao401()).called(1);
      verifyNever(() => mockProjetoRepo.listarProjetos(token: any(named: 'token')));
    });

    test('listarProjetos aciona tratarFugaSessao401 ao capturar ApiException 401 do repositório', () async {
      when(() => mockSessaoService.token).thenReturn('token_expirado');
      when(() => mockSessaoService.tratarFugaSessao401()).thenAnswer((_) async {});

      when(() => mockProjetoRepo.listarProjetos(
            token: 'token_expirado',
            searchNome: any(named: 'searchNome'),
          )).thenThrow(const ApiException('Token JWT inválido ou expirado', 401));

      expect(
        () => projetoService.listarProjetos(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      verify(() => mockSessaoService.tratarFugaSessao401()).called(1);
    });

    test('obterProjeto delega ao repositório com token válido', () async {
      when(() => mockSessaoService.token).thenReturn('token_valido');

      final projeto = Projeto(
        id: 10,
        nome: 'Projeto Teste',
        descricao: 'Detalhe',
        usuarioId: 2,
        createdAt: DateTime(2026, 10, 22),
      );

      when(() => mockProjetoRepo.obterProjeto(
            token: 'token_valido',
            projetoId: 10,
          )).thenAnswer((_) async => projeto);

      final resultado = await projetoService.obterProjeto(10);

      expect(resultado, equals(projeto));
      verify(() => mockProjetoRepo.obterProjeto(
            token: 'token_valido',
            projetoId: 10,
          )).called(1);
    });

    test('obterProjeto rejeita ID inválido (menor ou igual a zero)', () async {
      expect(
        () => projetoService.obterProjeto(0),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('inválido'))),
      );

      verifyNever(() => mockProjetoRepo.obterProjeto(
            token: any(named: 'token'),
            projetoId: any(named: 'projetoId'),
          ));
    });

    test('criarProjeto delega para repositório passando o token da sessão', () async {
      when(() => mockSessaoService.token).thenReturn('token_sessao_123');

      final novoProjeto = Projeto(
        id: 50,
        nome: 'Projeto Criado',
        descricao: 'Desc',
        usuarioId: 1,
        createdAt: DateTime(2026, 11, 16),
      );

      when(() => mockProjetoRepo.criarProjeto(
            token: 'token_sessao_123',
            nome: 'Projeto Criado',
            descricao: 'Desc',
          )).thenAnswer((_) async => novoProjeto);

      final resultado = await projetoService.criarProjeto(
        nome: 'Projeto Criado',
        descricao: 'Desc',
      );

      expect(resultado, equals(novoProjeto));
      verify(() => mockProjetoRepo.criarProjeto(
            token: 'token_sessao_123',
            nome: 'Projeto Criado',
            descricao: 'Desc',
          )).called(1);
    });

    test('criarProjeto valida que nome não pode ser vazio', () async {
      expect(
        () => projetoService.criarProjeto(nome: '   '),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('obrigatório'))),
      );
    });

    test('atualizarProjeto delega para repositório com ID, nome e token', () async {
      when(() => mockSessaoService.token).thenReturn('token_sessao_123');

      final projetoAtualizado = Projeto(
        id: 50,
        nome: 'Projeto Atualizado',
        descricao: 'Desc Nova',
        usuarioId: 1,
        createdAt: DateTime(2026, 11, 16),
      );

      when(() => mockProjetoRepo.atualizarProjeto(
            token: 'token_sessao_123',
            projetoId: 50,
            nome: 'Projeto Atualizado',
            descricao: 'Desc Nova',
          )).thenAnswer((_) async => projetoAtualizado);

      final resultado = await projetoService.atualizarProjeto(
        projetoId: 50,
        nome: 'Projeto Atualizado',
        descricao: 'Desc Nova',
      );

      expect(resultado, equals(projetoAtualizado));
      verify(() => mockProjetoRepo.atualizarProjeto(
            token: 'token_sessao_123',
            projetoId: 50,
            nome: 'Projeto Atualizado',
            descricao: 'Desc Nova',
          )).called(1);
    });

    test('deletarProjeto delega exclusão para repositório com token', () async {
      when(() => mockSessaoService.token).thenReturn('token_sessao_123');

      when(() => mockProjetoRepo.deletarProjeto(
            token: 'token_sessao_123',
            projetoId: 50,
          )).thenAnswer((_) async {});

      await projetoService.deletarProjeto(50);

      verify(() => mockProjetoRepo.deletarProjeto(
            token: 'token_sessao_123',
            projetoId: 50,
          )).called(1);
    });
  });
}
