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
          AppRoutes.projetoForm: (context) => const Scaffold(body: Text('Tela Form Mock')),
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

    testWidgets('Botão de Novo Projeto navega para formulário', (WidgetTester tester) async {
      when(() => mockProjetoService.listarProjetos()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_novo_projeto')));
      await tester.pumpAndSettle();

      expect(find.text('Tela Form Mock'), findsOneWidget);
    });

    testWidgets('Clique em excluir abre diálogo de confirmação com showDialog', (WidgetTester tester) async {
      final projetos = [
        Projeto(
          id: 88,
          nome: 'Projeto para Deletar',
          descricao: 'Desc',
          usuarioId: 1,
          createdAt: DateTime(2026, 10, 22),
        ),
      ];

      when(() => mockProjetoService.listarProjetos()).thenAnswer((_) async => projetos);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Clica no botão de excluir do card
      await tester.tap(find.byKey(const Key('btn_excluir_projeto_88')));
      await tester.pumpAndSettle();

      // Verifica que o diálogo com showDialog apareceu
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Confirmar Exclusão'), findsOneWidget);
      expect(find.text('Tem certeza que deseja excluir o projeto "Projeto para Deletar"? Esta ação não pode ser desfeita.'), findsOneWidget);
      expect(find.byKey(const Key('btn_cancelar_exclusao')), findsOneWidget);
      expect(find.byKey(const Key('btn_confirmar_exclusao')), findsOneWidget);

      // Clica em Cancelar
      await tester.tap(find.byKey(const Key('btn_cancelar_exclusao')));
      await tester.pumpAndSettle();

      // Diálogo fechou e deletarProjeto NÃO foi chamado
      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => mockProjetoService.deletarProjeto(any()));
    });

    testWidgets('Confirmar exclusão no diálogo deleta o projeto e atualiza a lista', (WidgetTester tester) async {
      final projetos = [
        Projeto(
          id: 88,
          nome: 'Projeto a ser Excluído',
          descricao: 'Desc',
          usuarioId: 1,
          createdAt: DateTime(2026, 10, 22),
        ),
      ];

      when(() => mockProjetoService.listarProjetos()).thenAnswer((_) async => projetos);
      when(() => mockProjetoService.deletarProjeto(88)).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Clica para excluir
      await tester.tap(find.byKey(const Key('btn_excluir_projeto_88')));
      await tester.pumpAndSettle();

      // Clica em Excluir no diálogo
      await tester.tap(find.byKey(const Key('btn_confirmar_exclusao')));
      await tester.pumpAndSettle();

      // Verifica que deletou e chamou listarProjetos novamente
      verify(() => mockProjetoService.deletarProjeto(88)).called(1);
      verify(() => mockProjetoService.listarProjetos()).called(2);
      expect(find.text('Projeto excluído com sucesso!'), findsOneWidget);
    });

    testWidgets('Erro ao excluir projeto exibe SnackBar com a mensagem da API', (WidgetTester tester) async {
      final projetos = [
        Projeto(
          id: 88,
          nome: 'Projeto Bloqueado',
          descricao: 'Desc',
          usuarioId: 1,
          createdAt: DateTime(2026, 10, 22),
        ),
      ];

      when(() => mockProjetoService.listarProjetos()).thenAnswer((_) async => projetos);
      when(() => mockProjetoService.deletarProjeto(88)).thenThrow(
        const ApiException('Não é permitido excluir projeto com requisitos aprovados.', 400),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_excluir_projeto_88')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirmar_exclusao')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Não é permitido excluir projeto com requisitos aprovados.'), findsOneWidget);
    });

    testWidgets('Botão de editar no card navega para formulário', (WidgetTester tester) async {
      final projetos = [
        Projeto(
          id: 99,
          nome: 'Projeto para Editar',
          descricao: 'Desc',
          usuarioId: 1,
          createdAt: DateTime(2026, 10, 22),
        ),
      ];

      when(() => mockProjetoService.listarProjetos()).thenAnswer((_) async => projetos);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_editar_projeto_99')));
      await tester.pumpAndSettle();

      expect(find.text('Tela Form Mock'), findsOneWidget);
    });

    testWidgets('Busca/Filtro por nome envia parâmetro para API e lista vazia diz o que foi procurado', (WidgetTester tester) async {
      when(() => mockProjetoService.listarProjetos(searchNome: null)).thenAnswer((_) async => [
            Projeto(
              id: 1,
              nome: 'Sistema Alpha',
              descricao: 'Alpha',
              usuarioId: 1,
              createdAt: DateTime(2026, 11, 16),
            ),
          ]);
      when(() => mockProjetoService.listarProjetos(searchNome: 'Beta')).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Sistema Alpha'), findsOneWidget);
      expect(find.byKey(const Key('campo_busca_projetos')), findsOneWidget);

      // Digita no campo de busca
      await tester.enterText(find.byKey(const Key('campo_busca_projetos')), 'Beta');
      await tester.pumpAndSettle();

      // Verifica que chamou listarProjetos com searchNome: 'Beta' (quem filtra é a API)
      verify(() => mockProjetoService.listarProjetos(searchNome: 'Beta')).called(1);

      // Lista vazia diz explicitamente o que foi procurado
      expect(find.text('Nenhum resultado corresponde à busca por "Beta".'), findsOneWidget);
      expect(find.byKey(const Key('btn_limpar_filtro')), findsOneWidget);

      // Clica em Limpar busca
      when(() => mockProjetoService.listarProjetos(searchNome: null)).thenAnswer((_) async => []);
      await tester.tap(find.byKey(const Key('btn_limpar_filtro')));
      await tester.pumpAndSettle();

      // Campo de busca limpo e lista recarregada sem filtro
      final searchField = tester.widget<TextField>(find.byKey(const Key('campo_busca_projetos')));
      expect(searchField.controller?.text, isEmpty);
    });
  });
}
