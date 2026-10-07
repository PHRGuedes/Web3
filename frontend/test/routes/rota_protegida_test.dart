import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../lib/models/usuario.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/routes.dart';
import '../../lib/screens/home_screen.dart';
import '../../lib/screens/login_screen.dart';
import '../../lib/screens/perfil_screen.dart';
import '../../lib/screens/projetos_screen.dart';
import '../../lib/services/sessao_service.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SessaoService sessaoService;

  setUp(() {
    mockRepository = MockAuthRepository();
    sessaoService = SessaoService(authRepository: mockRepository);
  });

  Widget buildAppUnderTest({required String initialRoute}) {
    return ChangeNotifierProvider<SessaoService>.value(
      value: sessaoService,
      child: MaterialApp(
        initialRoute: initialRoute,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.home: (context) => const RotaProtegida(child: HomeScreen()),
          AppRoutes.perfil: (context) => const RotaProtegida(child: PerfilScreen()),
          AppRoutes.projetos: (context) => const RotaProtegida(child: ProjetosScreen()),
        },
      ),
    );
  }

  group('Guarda de Rotas (RotaProtegida) Tests', () {
    testWidgets('Bloqueio: Tentar acessar rota protegida /home sem sessão redireciona para /login', (WidgetTester tester) async {
      // Usuário NÃO está autenticado
      expect(sessaoService.isAuthenticated, isFalse);

      await tester.pumpWidget(buildAppUnderTest(initialRoute: AppRoutes.home));
      await tester.pumpAndSettle();

      // Verifica que a tela protegida foi bloqueada e o usuário foi levado ao Login
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Entrar na sua conta'), findsOneWidget);
    });

    testWidgets('Bloqueio: Tentar acessar rota protegida /perfil sem sessão redireciona para /login', (WidgetTester tester) async {
      expect(sessaoService.isAuthenticated, isFalse);

      await tester.pumpWidget(buildAppUnderTest(initialRoute: AppRoutes.perfil));
      await tester.pumpAndSettle();

      expect(find.byType(PerfilScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Bloqueio: Tentar acessar rota protegida /projetos sem sessão redireciona para /login', (WidgetTester tester) async {
      expect(sessaoService.isAuthenticated, isFalse);

      await tester.pumpWidget(buildAppUnderTest(initialRoute: AppRoutes.projetos));
      await tester.pumpAndSettle();

      expect(find.byType(ProjetosScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Permissão: Usuário autenticado com JWT em memória acessa a rota protegida normalmente', (WidgetTester tester) async {
      // Configura sessão autenticada
      sessaoService.setToken('valid_jwt_token_123');
      sessaoService.setUsuario(const Usuario(
        id: 1,
        nome: 'Roberta Dias',
        email: 'roberta@reqflow.com',
      ));

      await tester.pumpWidget(buildAppUnderTest(initialRoute: AppRoutes.home));
      await tester.pumpAndSettle();

      // Rota protegida permitida com sucesso
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('Olá, Roberta Dias!'), findsOneWidget);
    });

    testWidgets('Volatilidade / Redirecionamento Reativo: Deslogar em tela protegida aciona a guarda e envia para login', (WidgetTester tester) async {
      // Inicia logado
      sessaoService.setToken('token_ativo');
      sessaoService.setUsuario(const Usuario(
        id: 2,
        nome: 'Felipe Ramos',
        email: 'felipe@reqflow.com',
      ));

      await tester.pumpWidget(buildAppUnderTest(initialRoute: AppRoutes.perfil));
      await tester.pumpAndSettle();

      expect(find.byType(PerfilScreen), findsOneWidget);

      // Simula perda de sessão / logout
      sessaoService.logout();
      await tester.pumpAndSettle();

      // Guarda de rotas detecta reativamente e redireciona
      expect(find.byType(PerfilScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
