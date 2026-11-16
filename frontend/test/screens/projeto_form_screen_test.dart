import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../lib/models/projeto.dart';
import '../../lib/repositories/auth_repository.dart'; // ApiException
import '../../lib/screens/projeto_form_screen.dart';
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

  Widget createWidgetUnderTest({Projeto? projetoInicial}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessaoService>.value(value: mockSessaoService),
        Provider<ProjetoService>.value(value: mockProjetoService),
      ],
      child: MaterialApp(
        home: ProjetoFormScreen(projetoInicial: projetoInicial),
      ),
    );
  }

  group('ProjetoFormScreen - Formulário Único de Criação e Edição Tests', () {
    testWidgets('Modo Criação: Exibe campos vazios e título Novo Projeto', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Novo Projeto'), findsWidgets);
      expect(find.byKey(const Key('campo_nome_projeto')), findsOneWidget);
      expect(find.byKey(const Key('campo_descricao_projeto')), findsOneWidget);
      expect(find.text('Criar Projeto'), findsOneWidget);

      final nomeField = tester.widget<TextFormField>(find.byKey(const Key('campo_nome_projeto')));
      expect(nomeField.controller?.text, isEmpty);
    });

    testWidgets('Modo Edição: Exibe campos pré-preenchidos e título Editar Projeto', (WidgetTester tester) async {
      final projetoExistente = Projeto(
        id: 77,
        nome: 'Projeto Legado',
        descricao: 'Descrição existente',
        usuarioId: 1,
        createdAt: DateTime(2026, 10, 22),
      );

      await tester.pumpWidget(createWidgetUnderTest(projetoInicial: projetoExistente));
      await tester.pumpAndSettle();

      expect(find.text('Editar Projeto'), findsWidgets);
      expect(find.text('Atualize as informações do projeto #77'), findsOneWidget);
      expect(find.text('Projeto Legado'), findsOneWidget);
      expect(find.text('Descrição existente'), findsOneWidget);
      expect(find.text('Salvar Alterações'), findsOneWidget);
    });

    testWidgets('Validação (validator): Impede submissão e mostra erro com campo nome em branco', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Clica em salvar sem preencher nada
      await tester.tap(find.byKey(const Key('btn_salvar_projeto')));
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome do projeto.'), findsOneWidget);
      verifyNever(() => mockProjetoService.criarProjeto(nome: any(named: 'nome')));
    });

    testWidgets('Validação (validator): Impede submissão com nome menor que 2 caracteres', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('campo_nome_projeto')), 'A');
      await tester.tap(find.byKey(const Key('btn_salvar_projeto')));
      await tester.pumpAndSettle();

      expect(find.text('O nome deve ter no mínimo 2 caracteres.'), findsOneWidget);
      verifyNever(() => mockProjetoService.criarProjeto(nome: any(named: 'nome')));
    });

    testWidgets('Criação (POST): Preenche campos válidos e salva chamando serviço', (WidgetTester tester) async {
      final projetoCriado = Projeto(
        id: 100,
        nome: 'Novo Portal de Requisitos',
        descricao: 'Gestão completa',
        usuarioId: 1,
        createdAt: DateTime(2026, 11, 16),
      );

      when(() => mockProjetoService.criarProjeto(
            nome: 'Novo Portal de Requisitos',
            descricao: 'Gestão completa',
          )).thenAnswer((_) async => projetoCriado);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('campo_nome_projeto')), 'Novo Portal de Requisitos');
      await tester.enterText(find.byKey(const Key('campo_descricao_projeto')), 'Gestão completa');

      await tester.tap(find.byKey(const Key('btn_salvar_projeto')));
      await tester.pumpAndSettle();

      verify(() => mockProjetoService.criarProjeto(
            nome: 'Novo Portal de Requisitos',
            descricao: 'Gestão completa',
          )).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Projeto criado com sucesso!'), findsOneWidget);
    });

    testWidgets('Edição (PATCH): Altera campos e salva chamando atualizarProjeto com ID', (WidgetTester tester) async {
      final projetoExistente = Projeto(
        id: 42,
        nome: 'Nome Antigo',
        descricao: 'Desc Antiga',
        usuarioId: 1,
        createdAt: DateTime(2026, 10, 22),
      );

      final projetoAtualizado = Projeto(
        id: 42,
        nome: 'Nome Atualizado',
        descricao: 'Nova Descrição',
        usuarioId: 1,
        createdAt: DateTime(2026, 10, 22),
      );

      when(() => mockProjetoService.atualizarProjeto(
            projetoId: 42,
            nome: 'Nome Atualizado',
            descricao: 'Nova Descrição',
          )).thenAnswer((_) async => projetoAtualizado);

      await tester.pumpWidget(createWidgetUnderTest(projetoInicial: projetoExistente));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('campo_nome_projeto')), 'Nome Atualizado');
      await tester.enterText(find.byKey(const Key('campo_descricao_projeto')), 'Nova Descrição');

      await tester.tap(find.byKey(const Key('btn_salvar_projeto')));
      await tester.pumpAndSettle();

      verify(() => mockProjetoService.atualizarProjeto(
            projetoId: 42,
            nome: 'Nome Atualizado',
            descricao: 'Nova Descrição',
          )).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Projeto atualizado com sucesso!'), findsOneWidget);
    });

    testWidgets('Recusa da API 409 (Conflito/Nome duplicado): Exibe frase da API na tela e MANTÉM formulário aberto', (WidgetTester tester) async {
      const mensagemErroApi = "Já existe um projeto cadastrado com o nome 'ReqFlow' para este usuário (RN01).";

      when(() => mockProjetoService.criarProjeto(
            nome: any(named: 'nome'),
            descricao: any(named: 'descricao'),
          )).thenThrow(const ApiException(mensagemErroApi, 409));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('campo_nome_projeto')), 'ReqFlow');
      await tester.tap(find.byKey(const Key('btn_salvar_projeto')));
      await tester.pumpAndSettle();

      // Prova de que a frase da API é exibida no banner
      expect(find.byKey(const Key('banner_erro_api')), findsOneWidget);
      expect(find.text(mensagemErroApi), findsWidgets);

      // Prova de que o formulário CONTINUA ABERTO e os campos permanecem editáveis
      expect(find.byKey(const Key('campo_nome_projeto')), findsOneWidget);
      expect(find.text('ReqFlow'), findsOneWidget);
      expect(find.byKey(const Key('btn_salvar_projeto')), findsOneWidget);
    });

    testWidgets('Recusa da API 422 (Validação do servidor): Exibe frase da API na tela e MANTÉM formulário aberto', (WidgetTester tester) async {
      const mensagemErro422 = 'Falha na validação dos dados de entrada.';

      when(() => mockProjetoService.criarProjeto(
            nome: any(named: 'nome'),
            descricao: any(named: 'descricao'),
          )).thenThrow(const ApiException(mensagemErro422, 422));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('campo_nome_projeto')), 'Nome Rejeitado Pela API');
      await tester.tap(find.byKey(const Key('btn_salvar_projeto')));
      await tester.pumpAndSettle();

      // Exibe a frase da API
      expect(find.byKey(const Key('banner_erro_api')), findsOneWidget);
      expect(find.text(mensagemErro422), findsWidgets);

      // O formulário continua aberto
      expect(find.byKey(const Key('campo_nome_projeto')), findsOneWidget);
      expect(find.text('Nome Rejeitado Pela API'), findsOneWidget);
    });
  });
}
