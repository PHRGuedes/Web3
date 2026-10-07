import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../lib/models/usuario.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/routes.dart';
import '../../lib/screens/login_screen.dart';
import '../../lib/screens/perfil_screen.dart';
import '../../lib/services/sessao_service.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SessaoService sessaoService;

  setUp(() {
    mockRepository = MockAuthRepository();
    sessaoService = SessaoService(authRepository: mockRepository);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SessaoService>.value(
      value: sessaoService,
      child: MaterialApp(
        initialRoute: AppRoutes.perfil,
        routes: {
          AppRoutes.perfil: (context) => const PerfilScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
        },
      ),
    );
  }

  group('PerfilScreen Widget Tests', () {
    testWidgets('Exibe dados do usuário logado consumidos reativamente da sessão', (WidgetTester tester) async {
      sessaoService.setToken('jwt_valid');
      sessaoService.setUsuario(const Usuario(
        id: 7,
        nome: 'Juliana Ferreira',
        email: 'juliana.ferreira@reqflow.com',
      ));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verifica exibição reativa
      expect(find.byKey(const Key('perfilNomeText')), findsOneWidget);
      expect(find.text('Juliana Ferreira'), findsWidgets);
      expect(find.byKey(const Key('perfilEmailText')), findsOneWidget);
      expect(find.text('juliana.ferreira@reqflow.com'), findsWidgets);
      expect(find.text('Identificador: #7'), findsOneWidget);

      // Atualiza usuário dinamicamente e valida reatividade imediata
      sessaoService.setUsuario(const Usuario(
        id: 7,
        nome: 'Juliana F. Silva',
        email: 'juliana.silva@reqflow.com',
      ));
      await tester.pump();

      expect(find.text('Juliana F. Silva'), findsWidgets);
      expect(find.text('juliana.silva@reqflow.com'), findsWidgets);
    });

    testWidgets('Botão de logout na tela de perfil limpa sessão e redireciona para login', (WidgetTester tester) async {
      sessaoService.setToken('jwt_valid');
      sessaoService.setUsuario(const Usuario(
        id: 7,
        nome: 'Juliana Ferreira',
        email: 'juliana@reqflow.com',
      ));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final logoutBtn = find.byKey(const Key('perfilLogoutButton'));
      expect(logoutBtn, findsOneWidget);

      await tester.scrollUntilVisible(logoutBtn, 200);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(sessaoService.isAuthenticated, isFalse);
      expect(find.byType(PerfilScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
