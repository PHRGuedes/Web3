import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/models/auth_token.dart';
import '../../lib/models/cadastro_request.dart';
import '../../lib/models/login_request.dart';
import '../../lib/models/usuario.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/repositories/local_storage_repository.dart';
import '../../lib/services/sessao_service.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}
class MockLocalStorageRepository extends Mock implements ILocalStorageRepository {}
class FakeLoginRequest extends Fake implements LoginRequest {}
class FakeCadastroRequest extends Fake implements CadastroRequest {}

void main() {
  late MockAuthRepository mockRepository;
  late MockLocalStorageRepository mockStorage;
  late SessaoService sessaoService;

  setUpAll(() {
    registerFallbackValue(FakeLoginRequest());
    registerFallbackValue(FakeCadastroRequest());
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockLocalStorageRepository();
    sessaoService = SessaoService(
      authRepository: mockRepository,
      storageRepository: mockStorage,
    );
  });

  group('SessaoService Unit Tests (Persistência, ChangeNotifier e Sessão)', () {
    test('Estado inicial: deslogado com token e usuário nulos', () {
      expect(sessaoService.isAuthenticated, isFalse);
      expect(sessaoService.token, isNull);
      expect(sessaoService.usuario, isNull);
      expect(sessaoService.currentUser, isNull);
    });

    test('Volatilidade: cada nova instância inicia com memória limpa sem persistência automática', () {
      sessaoService.setToken('token_temporario');
      expect(sessaoService.isAuthenticated, isTrue);

      final novaInstancia = SessaoService(authRepository: mockRepository);
      expect(novaInstancia.isAuthenticated, isFalse);
      expect(novaInstancia.token, isNull);
      expect(novaInstancia.usuario, isNull);
    });

    test('inicializarSessaoSilenciosa() restaura token do LocalStorageRepository', () async {
      when(() => mockStorage.obterToken()).thenAnswer((_) async => 'jwt_salvo_123');

      await sessaoService.inicializarSessaoSilenciosa();

      expect(sessaoService.token, 'jwt_salvo_123');
      expect(sessaoService.isAuthenticated, isTrue);
      verify(() => mockStorage.obterToken()).called(1);
    });

    test('Login com sucesso salva no storage, memória e emite notifyListeners()', () async {
      const email = 'ana.ribeiro@reqflow.com';
      const senha = 'senhaCorreta123';
      const tokenEsperado = AuthToken(accessToken: 'jwt_memory_token_777');
      const usuarioLogado = Usuario(
        id: 1,
        nome: 'Ana Ribeiro',
        email: email,
      );

      when(() => mockRepository.login(any())).thenAnswer((_) async => tokenEsperado);
      when(() => mockRepository.obterUsuarioLogado('jwt_memory_token_777'))
          .thenAnswer((_) async => usuarioLogado);
      when(() => mockStorage.salvarToken('jwt_memory_token_777')).thenAnswer((_) async {});

      int listenerNotifications = 0;
      sessaoService.addListener(() {
        listenerNotifications++;
      });

      final resultado = await sessaoService.login(email, senha);

      expect(resultado.accessToken, 'jwt_memory_token_777');
      expect(sessaoService.token, 'jwt_memory_token_777');
      expect(sessaoService.usuario, equals(usuarioLogado));
      expect(sessaoService.isAuthenticated, isTrue);
      expect(listenerNotifications, greaterThanOrEqualTo(1));

      verify(() => mockRepository.login(any(that: isA<LoginRequest>()))).called(1);
      verify(() => mockRepository.obterUsuarioLogado('jwt_memory_token_777')).called(1);
      verify(() => mockStorage.salvarToken('jwt_memory_token_777')).called(1);
    });

    test('cadastrar() executa auto-login salvando token e retornando usuário', () async {
      const usuarioNovo = Usuario(id: 2, nome: 'Beatriz', email: 'beatriz@reqflow.com');
      const tokenEsperado = AuthToken(accessToken: 'jwt_auto_login');

      when(() => mockRepository.cadastrar(any())).thenAnswer((_) async => usuarioNovo);
      when(() => mockRepository.login(any())).thenAnswer((_) async => tokenEsperado);
      when(() => mockRepository.obterUsuarioLogado('jwt_auto_login'))
          .thenAnswer((_) async => usuarioNovo);
      when(() => mockStorage.salvarToken('jwt_auto_login')).thenAnswer((_) async {});

      final resultado = await sessaoService.cadastrar('Beatriz', 'beatriz@reqflow.com', '123456');

      expect(resultado.nome, 'Beatriz');
      expect(sessaoService.token, 'jwt_auto_login');
      expect(sessaoService.isAuthenticated, isTrue);

      verify(() => mockRepository.cadastrar(any(that: isA<CadastroRequest>()))).called(1);
      verify(() => mockRepository.login(any(that: isA<LoginRequest>()))).called(1);
      verify(() => mockStorage.salvarToken('jwt_auto_login')).called(1);
    });

    test('cadastrar() com falha de rede no auto-login lança ApiException com statusCode 201', () async {
      const usuarioNovo = Usuario(id: 2, nome: 'Beatriz', email: 'beatriz@reqflow.com');

      when(() => mockRepository.cadastrar(any())).thenAnswer((_) async => usuarioNovo);
      when(() => mockRepository.login(any())).thenThrow(const ApiException('Erro de conexão no login'));

      expect(
        () => sessaoService.cadastrar('Beatriz', 'beatriz@reqflow.com', '123456'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 201)
            .having((e) => e.message, 'message', contains('Conta criada com sucesso'))),
      );
    });

    test('logout() limpa token físico no storage, memória e emite notifyListeners()', () async {
      sessaoService.setToken('token_ativo');
      sessaoService.setUsuario(const Usuario(id: 1, nome: 'Ana', email: 'ana@req.com'));
      expect(sessaoService.isAuthenticated, isTrue);

      when(() => mockStorage.removerToken()).thenAnswer((_) async {});

      int notificationCount = 0;
      sessaoService.addListener(() {
        notificationCount++;
      });

      await sessaoService.logout();

      expect(sessaoService.token, isNull);
      expect(sessaoService.usuario, isNull);
      expect(sessaoService.isAuthenticated, isFalse);
      expect(notificationCount, 1);
      verify(() => mockStorage.removerToken()).called(1);
    });

    test('tratarFugaSessao401() remove token físico e dispara notifyListeners()', () async {
      sessaoService.setToken('token_expirado');
      when(() => mockStorage.removerToken()).thenAnswer((_) async {});

      await sessaoService.tratarFugaSessao401();

      expect(sessaoService.token, isNull);
      expect(sessaoService.isAuthenticated, isFalse);
      verify(() => mockStorage.removerToken()).called(1);
    });

    test('Validação de login: e-mail inválido ou senha vazia lança erro sem chamar repositório', () async {
      expect(
        () => sessaoService.login('', '123456'),
        throwsA(isA<ApiException>()),
      );
      expect(
        () => sessaoService.login('emailSemArroba', '123456'),
        throwsA(isA<ApiException>()),
      );
      expect(
        () => sessaoService.login('email@valido.com', ''),
        throwsA(isA<ApiException>()),
      );

      verifyNever(() => mockRepository.login(any()));
    });
  });
}
