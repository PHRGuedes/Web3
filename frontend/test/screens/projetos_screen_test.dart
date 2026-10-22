import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../lib/models/projeto.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/routes.dart';
import '../../lib/screens/projetos_screen.dart';
import '../../lib/services/projeto_service.dart';
import '../../lib/services/sessao_service.dart';

class MockProjetoService extends Mock implements ProjetoService {}
class MockSessaoService extends Mock implements SessaoService {}

void main() {
  late MockProjetoService mockProjetoService;
  late MockSessaoService mockSessaoService;

  setUp(() {
    mockProjetoService = MockProjetoService();
    mockSessaoService = MockSessaoService();
    when(() => mockSessaoService.isAuthenticated).thenReturn(true);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessaoService>.value(value: mockSessaoService),
        Provider<ProjetoService>.value(value: mockProjetoService),
      ],
      child: MaterialApp(
        routes: {
          AppRoutes.projetoDetalhes: (context) => const Scaffold(body: Text('Tela Detalhes Mock')),
        },
        home: const ProjetosScreen(),
      ),
    );
  }

  group('ProjetosScreen 4 Estados & FutureBuilder Tests', () {
    testWidgets('Estado 1: Exibe indicador de carregando enquanto aguarda resposta', (WidgetTester tester) async {
      when(() => mockProjetoService.listarProjetos())
          .thenAnswer((_) => Future.delayed(const Duration(seconds: 2), () => []));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando projetos de requisitos...'), findsOneWidget);
    });

    testWidgets('Estado 2: Exibe tela de erro e botão Tentar de novo', (WidgetTester tester) async {
      when(() => mockProjetoService.listarProjetos())
          .thenThrow(const ApiException('Serviço temporariamente indisponível.', 503));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar os projetos'), findsOneWidget);
      expect(find.text('Serviço temporariamente indisponível.'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
    });

    testWidgets('Estado 3: Exibe mensagem de lista vazia quando não há projetos cadastrados', (WidgetTester tester) async {
      when(() => mockProjetoService.listarProjetos()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Nenhum projeto encontrado'), findsOneWidget);
      expect(find.text('Você ainda não possui projetos cadastrados em sua conta.'), findsOneWidget);
    });

    testWidgets('Estado 4: Exibe ListView.builder com cards de projetos reais', (WidgetTester tester) async {
      final projetos = [
        Projeto(
          id: 101,
          nome: 'ReqFlow Web & Mobile',
          descricao: 'Módulo de requisitos ágeis e rastreabilidade.',
          usuarioId: 1,
          createdAt: DateTime(2026, 10, 22),
        ),
        Projeto(
          id: 102,
          nome: 'Portal Corporativo',
          descricao: 'Gestão de histórias de usuário.',
          usuarioId: 1,
          createdAt: DateTime(2026, 10, 22),
        ),
      ];

      when(() => mockProjetoService.listarProjetos()).thenAnswer((_) async => projetos);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('ReqFlow Web & Mobile'), findsOneWidget);
      expect(find.text('#101'), findsOneWidget);
      expect(find.text('Portal Corporativo'), findsOneWidget);
      expect(find.text('#102'), findsOneWidget);
    });

    testWidgets('Toque no card navega para rota de detalhes passando o ID', (WidgetTester tester) async {
      final projetos = [
        Projeto(
          id: 77,
          nome: 'Projeto Selecionado',
          descricao: 'Desc',
          usuarioId: 1,
          createdAt: DateTime(2026, 10, 22),
        ),
      ];

      when(() => mockProjetoService.listarProjetos()).thenAnswer((_) async => projetos);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Projeto Selecionado'));
      await tester.pumpAndSettle();

      expect(find.text('Tela Detalhes Mock'), findsOneWidget);
    });
  });
}
