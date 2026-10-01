import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/models/auth_token.dart';
import '../../lib/models/login_request.dart';
import '../../lib/models/usuario.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/screens/login_screen.dart';
import '../../lib/screens/home_screen.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}
class FakeLoginRequest extends Fake implements LoginRequest {}

void main() {
  late MockAuthRepository mockRepository;
  late AuthService authService;

  setUpAll(() {
    registerFallbackValue(FakeLoginRequest());
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    authService = AuthService(repository: mockRepository);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: LoginScreen(authService: authService),
    );
  }

  group('LoginScreen Widget & UI Tests', () {
    testWidgets('Deve conter explicitamente os widgets fundamentais: Scaffold, Column, Row e Container', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Validação explícita dos 4 widgets exigidos
      expect(find.byType(Scaffold), findsWidgets, reason: 'Scaffold deve estar presente na tela');
      expect(find.byType(Column), findsWidgets, reason: 'Column deve estar presente na tela');
      expect(find.byType(Row), findsWidgets, reason: 'Row deve estar presente na tela');
      expect(find.byType(Container), findsWidgets, reason: 'Container deve estar presente na tela');

      // Validação dos elementos do protótipo ReqFlow
      expect(find.text('ReqFlow'), findsOneWidget);
      expect(find.text('Entrar na sua conta'), findsOneWidget);
      expect(find.byKey(const Key('emailField')), findsOneWidget);
      expect(find.byKey(const Key('senhaField')), findsOneWidget);
      expect(find.byKey(const Key('entrarButton')), findsOneWidget);
      expect(find.byKey(const Key('criarContaLink')), findsOneWidget);
    });

    testWidgets('Tratamento de Erros: Credenciais inválidas exibem mensagem de erro e NÃO navegam', (WidgetTester tester) async {
      when(() => mockRepository.login(any())).thenThrow(
        const ApiException('E-mail ou senha inválidos.', 401),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Preenche os campos
      await tester.enterText(find.byKey(const Key('emailField')), 'usuario@errado.com');
      await tester.enterText(find.byKey(const Key('senhaField')), 'senhaIncorreta');

      // Clica em Entrar
      await tester.tap(find.byKey(const Key('entrarButton')));
      await tester.pumpAndSettle();

      // Verifica que a mensagem clara de erro é exibida
      expect(find.text('E-mail ou senha inválidos.'), findsWidgets);

      // Garante que o app permaneceu na tela de Login e não navegou para a HomeScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Fluxo de Sucesso: Credenciais válidas salvam JWT e navegam para HomeScreen', (WidgetTester tester) async {
      const token = AuthToken(accessToken: 'jwt_mock_token_123');
      const usuarioLogado = Usuario(
        id: 1,
        nome: 'Ana Ribeiro',
        email: 'ana.ribeiro@reqflow.com',
      );

      when(() => mockRepository.login(any())).thenAnswer((_) async => token);
      when(() => mockRepository.obterUsuarioLogado('jwt_mock_token_123'))
          .thenAnswer((_) async => usuarioLogado);

      await tester.pumpWidget(createWidgetUnderTest());

      // Preenche com credenciais válidas
      await tester.enterText(find.byKey(const Key('emailField')), 'ana.ribeiro@reqflow.com');
      await tester.enterText(find.byKey(const Key('senhaField')), 'senhaCorreta123');

      // Dispara o login
      await tester.tap(find.byKey(const Key('entrarButton')));
      await tester.pumpAndSettle();

      // Verifica que navegou para HomeScreen e executou GET /usuarios/eu exibindo dados do usuário
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Olá, Ana Ribeiro!'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
    });
  });
}
