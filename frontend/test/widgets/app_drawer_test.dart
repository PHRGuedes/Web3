import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../lib/models/usuario.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/routes.dart';
import '../../lib/screens/login_screen.dart';
import '../../lib/services/sessao_service.dart';
import '../../lib/widgets/app_drawer.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SessaoService sessaoService;

  setUp(() {
    mockRepository = MockAuthRepository();
    sessaoService = SessaoService(authRepository: mockRepository);
  });

  Widget buildDrawerApp({String initialRoute = '/test'}) {
    return ChangeNotifierProvider<SessaoService>.value(
      value: sessaoService,
      child: MaterialApp(
        initialRoute: initialRoute,
        routes: {
          '/test': (context) => const Scaffold(
                drawer: AppDrawer(),
                body: Center(child: Text('Tela Teste')),
              ),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.home: (context) => const Scaffold(body: Text('Home Page')),
          AppRoutes.projetos: (context) => const Scaffold(body: Text('Projetos Page')),
          AppRoutes.perfil: (context) => const Scaffold(body: Text('Perfil Page')),
        },
      ),
    );
  }

  group('Menu Lateral (AppDrawer) Tests', () {
    testWidgets('Renderização do Menu Lateral com dados do usuário consumidos do Provider', (WidgetTester tester) async {
      // Define usuário no Provider
      sessaoService.setToken('valid_token');
      sessaoService.setUsuario(const Usuario(
        id: 42,
        nome: 'Carlos Eduardo',
        email: 'carlos.eduardo@reqflow.com',
      ));

      await tester.pumpWidget(buildDrawerApp());

      // Abre o Drawer
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Valida que o Drawer está visível
      expect(find.byType(AppDrawer), findsOneWidget);

      // Valida que o nome e e-mail do usuário logado foram renderizados a partir do Provider
      expect(find.byKey(const Key('drawerUserName')), findsOneWidget);
      expect(find.text('Carlos Eduardo'), findsOneWidget);
      expect(find.byKey(const Key('drawerUserEmail')), findsOneWidget);
      expect(find.text('carlos.eduardo@reqflow.com'), findsOneWidget);

      // Valida presença das opções de navegação
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Projetos'), findsOneWidget);
      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.byKey(const Key('drawerLogoutButton')), findsOneWidget);
    });

    testWidgets('Ação do botão Sair (Logout): limpa dados do SessaoService e reseta navegação para /login', (WidgetTester tester) async {
      // Configura usuário autenticado
      sessaoService.setToken('token_para_deslogar');
      sessaoService.setUsuario(const Usuario(
        id: 10,
        nome: 'Juliana Costa',
        email: 'juliana@reqflow.com',
      ));
      expect(sessaoService.isAuthenticated, isTrue);

      await tester.pumpWidget(buildDrawerApp());

      // Abre o Drawer
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Clica no botão "Sair da Conta"
      final botaoSair = find.byKey(const Key('drawerLogoutButton'));
      expect(botaoSair, findsOneWidget);
      await tester.tap(botaoSair);
      await tester.pumpAndSettle();

      // 1. Verifica que os dados foram limpos do SessaoService
      expect(sessaoService.isAuthenticated, isFalse);
      expect(sessaoService.token, isNull);
      expect(sessaoService.usuario, isNull);

      // 2. Verifica que a pilha de navegação foi resetada para a tela de Login
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Entrar na sua conta'), findsOneWidget);
    });

    testWidgets('Navegação pelos itens do Drawer utiliza rotas nomeadas', (WidgetTester tester) async {
      sessaoService.setToken('token_ativo');
      sessaoService.setUsuario(const Usuario(id: 1, nome: 'Teste', email: 'teste@req.com'));

      await tester.pumpWidget(buildDrawerApp());

      // Abre o Drawer e clica em Projetos
      tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Projetos'));
      await tester.pumpAndSettle();

      expect(find.text('Projetos Page'), findsOneWidget);
    });
  });
}
