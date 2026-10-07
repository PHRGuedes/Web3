import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import '../../lib/repositories/auth_repository.dart';
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

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<SessaoService>.value(
      value: sessaoService,
      child: const MaterialApp(
        home: ProjetosScreen(),
      ),
    );
  }

  group('ProjetosScreen Widget Tests', () {
    testWidgets('Renderiza área de Projetos de Requisitos e cards placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Projetos de Requisitos'), findsOneWidget);
      expect(find.text('Engenharia de Requisitos'), findsOneWidget);
      expect(find.text('ReqFlow - Sistema Web & Mobile'), findsOneWidget);
      expect(find.text('Portal Corporativo de Requisitos'), findsOneWidget);
      expect(find.text('API de Integração Contínua ReqFlow'), findsOneWidget);
    });
  });
}
