import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/models/usuario.dart';
import '../../lib/models/auth_token.dart';
import '../../lib/models/login_request.dart';
import '../../lib/models/cadastro_request.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/services/auth_service.dart';

// Mocks e Fakes com Mocktail
class MockAuthRepository extends Mock implements IAuthRepository {}
class FakeLoginRequest extends Fake implements LoginRequest {}
class FakeCadastroRequest extends Fake implements CadastroRequest {}

void main() {
  late MockAuthRepository mockRepository;
  late AuthService authService;

  setUpAll(() {
    registerFallbackValue(FakeLoginRequest());
    registerFallbackValue(FakeCadastroRequest());
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    // Instancia o serviço com o repositório mockado
    authService = AuthService(repository: mockRepository);
  });

  group('AuthService Unit Tests (Mocked Repository)', () {
    test('Login com sucesso deve salvar o token JWT em memória e retornar AuthToken', () async {
      const email = 'ana.ribeiro@reqflow.com';
      const senha = 'senhaValida123';
      const tokenEsperado = AuthToken(accessToken: 'mock_jwt_token_999');

      when(() => mockRepository.login(any())).thenAnswer((_) async => tokenEsperado);

      final resultado = await authService.login(email, senha);

      expect(resultado.accessToken, 'mock_jwt_token_999');
      expect(authService.token, 'mock_jwt_token_999');
      expect(authService.isAuthenticated, isTrue);

      verify(() => mockRepository.login(any(that: isA<LoginRequest>()))).called(1);
    });

    test('Login com e-mail inválido deve falhar na validação do Service sem chamar o Repositório', () async {
      expect(
        () => authService.login('emailinvalido', '123456'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('formato válido'),
        )),
      );

      verifyNever(() => mockRepository.login(any()));
    });

    test('Login com senha incorreta deve propagar ApiException 401 do Repositório', () async {
      when(() => mockRepository.login(any())).thenThrow(
        const ApiException('E-mail ou senha incorretos.', 401),
      );

      expect(
        () => authService.login('ana.ribeiro@reqflow.com', 'senhaErrada'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'E-mail ou senha incorretos.',
        )),
      );

      expect(authService.token, isNull);
      expect(authService.isAuthenticated, isFalse);
    });

    test('Cadastrar usuário com sucesso deve chamar o repositório e retornar o Usuario criado', () async {
      const usuarioCriado = Usuario(
        id: 2,
        nome: 'Carlos Mendes',
        email: 'carlos@reqflow.com',
      );

      when(() => mockRepository.cadastrar(any())).thenAnswer((_) async => usuarioCriado);

      final resultado = await authService.cadastrar('Carlos Mendes', 'carlos@reqflow.com', 'senha12345');

      expect(resultado.id, 2);
      expect(resultado.nome, 'Carlos Mendes');
      verify(() => mockRepository.cadastrar(any(that: isA<CadastroRequest>()))).called(1);
    });

    test('Cadastrar com senha menor que 6 caracteres deve lançar exceção do Service', () async {
      expect(
        () => authService.cadastrar('Carlos Mendes', 'carlos@reqflow.com', '123'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('6 caracteres'),
        )),
      );

      verifyNever(() => mockRepository.cadastrar(any()));
    });

    test('obterUsuarioAtual deve fazer requisição GET enviando o token JWT e salvar em cache', () async {
      authService.setToken('jwt_token_valido');

      const usuarioEsperado = Usuario(
        id: 1,
        nome: 'Ana Ribeiro',
        email: 'ana.ribeiro@reqflow.com',
      );

      when(() => mockRepository.obterUsuarioLogado('jwt_token_valido'))
          .thenAnswer((_) async => usuarioEsperado);

      final usuario = await authService.obterUsuarioAtual();

      expect(usuario.id, 1);
      expect(usuario.nome, 'Ana Ribeiro');
      expect(authService.currentUser, equals(usuarioEsperado));

      verify(() => mockRepository.obterUsuarioLogado('jwt_token_valido')).called(1);
    });

    test('obterUsuarioAtual sem token deve falhar com erro 401 sem chamar o repositório', () async {
      expect(
        () => authService.obterUsuarioAtual(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      verifyNever(() => mockRepository.obterUsuarioLogado(any()));
    });

    test('logout deve limpar o token e os dados do usuário', () async {
      authService.setToken('jwt_token_teste');

      await authService.logout();

      expect(authService.token, isNull);
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);
    });
  });
}
