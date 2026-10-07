import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/models/auth_token.dart';
import '../../lib/models/cadastro_request.dart';
import '../../lib/models/login_request.dart';
import '../../lib/models/usuario.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/services/sessao_service.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}
class FakeLoginRequest extends Fake implements LoginRequest {}
class FakeCadastroRequest extends Fake implements CadastroRequest {}

void main() {
  late MockAuthRepository mockRepository;
  late SessaoService sessaoService;

  setUpAll(() {
    registerFallbackValue(FakeLoginRequest());
    registerFallbackValue(FakeCadastroRequest());
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    sessaoService = SessaoService(authRepository: mockRepository);
  });

  group('SessaoService Unit Tests (ChangeNotifier & Memória)', () {
    test('Estado inicial: deslogado com token e usuário nulos', () {
      expect(sessaoService.isAuthenticated, isFalse);
      expect(sessaoService.token, isNull);
      expect(sessaoService.usuario, isNull);
      expect(sessaoService.currentUser, isNull);
    });

    test('Volatilidade: cada nova instância inicia com memória limpa sem persistência', () {
      sessaoService.setToken('token_temporario');
      expect(sessaoService.isAuthenticated, isTrue);

      final novaInstancia = SessaoService(authRepository: mockRepository);
      expect(novaInstancia.isAuthenticated, isFalse);
      expect(novaInstancia.token, isNull);
      expect(novaInstancia.usuario, isNull);
    });

    test('Login com sucesso define token e usuário em memória e emite notifyListeners()', () async {
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

      int listenerNotifications = 0;
      sessaoService.addListener(() {
        listenerNotifications++;
      });

      final resultado = await sessaoService.login(email, senha);

      expect(resultado.accessToken, 'jwt_memory_token_777');
      expect(sessaoService.token, 'jwt_memory_token_777');
      expect(sessaoService.usuario, equals(usuarioLogado));
      expect(sessaoService.isAuthenticated, isTrue);
      expect(listenerNotifications, greaterThanOrEqualTo(1),
          reason: 'notifyListeners() deve ser disparado após o login');

      verify(() => mockRepository.login(any(that: isA<LoginRequest>()))).called(1);
      verify(() => mockRepository.obterUsuarioLogado('jwt_memory_token_777')).called(1);
    });

    test('logout() limpa token e usuário da memória e dispara notifyListeners()', () {
      sessaoService.setToken('token_ativo');
      sessaoService.setUsuario(const Usuario(id: 1, nome: 'Ana', email: 'ana@req.com'));
      expect(sessaoService.isAuthenticated, isTrue);

      int notificationCount = 0;
      sessaoService.addListener(() {
        notificationCount++;
      });

      sessaoService.logout();

      expect(sessaoService.token, isNull);
      expect(sessaoService.usuario, isNull);
      expect(sessaoService.isAuthenticated, isFalse);
      expect(notificationCount, 1,
          reason: 'notifyListeners() deve ser disparado exatamente uma vez no logout');
    });

    test('setToken() e setUsuario() emitem avisos aos ouvintes', () {
      int count = 0;
      sessaoService.addListener(() {
        count++;
      });

      sessaoService.setToken('novo_token');
      expect(count, 1);
      expect(sessaoService.token, 'novo_token');

      sessaoService.setUsuario(const Usuario(id: 5, nome: 'Lucas', email: 'lucas@reqflow.com'));
      expect(count, 2);
      expect(sessaoService.usuario?.nome, 'Lucas');
    });

    test('carregarUsuarioAtual() com token faz requisição GET e emite notifyListeners()', () async {
      sessaoService.setToken('token_carregamento');

      const usuarioEsperado = Usuario(
        id: 99,
        nome: 'Marina Silva',
        email: 'marina@reqflow.com',
      );

      when(() => mockRepository.obterUsuarioLogado('token_carregamento'))
          .thenAnswer((_) async => usuarioEsperado);

      bool notified = false;
      sessaoService.addListener(() {
        notified = true;
      });

      final user = await sessaoService.carregarUsuarioAtual();

      expect(user.id, 99);
      expect(sessaoService.usuario, equals(usuarioEsperado));
      expect(notified, isTrue);
    });

    test('carregarUsuarioAtual() sem token lança ApiException 401', () async {
      expect(
        () => sessaoService.carregarUsuarioAtual(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('cadastrar() delega ao repositório corretamente', () async {
      const usuarioNovo = Usuario(id: 2, nome: 'Beatriz', email: 'beatriz@reqflow.com');
      when(() => mockRepository.cadastrar(any())).thenAnswer((_) async => usuarioNovo);

      final resultado = await sessaoService.cadastrar('Beatriz', 'beatriz@reqflow.com', '123456');

      expect(resultado.nome, 'Beatriz');
      verify(() => mockRepository.cadastrar(any(that: isA<CadastroRequest>()))).called(1);
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
