import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../lib/models/projeto.dart';
import '../../lib/repositories/auth_repository.dart';
import '../../lib/screens/projeto_detalhes_screen.dart';
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

  Widget createWidgetUnderTest({Object? arguments = 42}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessaoService>.value(value: mockSessaoService),
        Provider<ProjetoService>.value(value: mockProjetoService),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: RouteSettings(name: '/projetos/detalhes', arguments: arguments),
            builder: (_) => const ProjetoDetalhesScreen(),
          );
        },
      ),
    );
  }

  group('ProjetoDetalhesScreen Widget Tests', () {
    testWidgets('Exibe estado de carregando enquanto busca o projeto', (WidgetTester tester) async {
      when(() => mockProjetoService.obterProjeto(42))
          .thenAnswer((_) => Future.delayed(const Duration(seconds: 2), () => throw Exception()));

      await tester.pumpWidget(createWidgetUnderTest(arguments: 42));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando detalhes do projeto...'), findsOneWidget);
    });

    testWidgets('Exibe mensagem de erro e botão Tentar de novo ao falhar', (WidgetTester tester) async {
      when(() => mockProjetoService.obterProjeto(42))
          .thenThrow(const ApiException('Projeto não encontrado no sistema.', 404));

      await tester.pumpWidget(createWidgetUnderTest(arguments: 42));
      await tester.pumpAndSettle();

      expect(find.text('Falha ao buscar projeto'), findsOneWidget);
      expect(find.text('Projeto não encontrado no sistema.'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
    });

    testWidgets('Exibe dados detalhados do projeto quando obtido com sucesso', (WidgetTester tester) async {
      final projeto = Projeto(
        id: 42,
        nome: 'ReqFlow Engenharia de Requisitos',
        descricao: 'Sistema completo para gestão de requisitos e rastreabilidade ágil.',
        usuarioId: 7,
        createdAt: DateTime(2026, 10, 22, 14, 30),
      );

      when(() => mockProjetoService.obterProjeto(42)).thenAnswer((_) async => projeto);

      await tester.pumpWidget(createWidgetUnderTest(arguments: 42));
      await tester.pumpAndSettle();

      expect(find.text('ReqFlow Engenharia de Requisitos'), findsOneWidget);
      expect(find.text('Identificador: #42'), findsOneWidget);
      expect(find.text('Sistema completo para gestão de requisitos e rastreabilidade ágil.'), findsOneWidget);
      expect(find.text('Usuário #7'), findsOneWidget);
      expect(find.text('22/10/2026 às 14:30'), findsOneWidget);
    });

    testWidgets('Exibe aviso de argumento inválido se rota não receber int', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(arguments: null));
      await tester.pumpAndSettle();

      expect(find.text('Projeto não identificado'), findsOneWidget);
      expect(find.text('Voltar para Projetos'), findsOneWidget);
    });
  });
}
