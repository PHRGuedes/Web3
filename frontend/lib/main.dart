import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/api_constants.dart';
import 'repositories/auth_repository.dart';
import 'routes.dart';
import 'screens/cadastro_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/projetos_screen.dart';
import 'services/sessao_service.dart';

/// Ponto de entrada da aplicação Flutter (ReqFlow).
/// GERÊNCIA DE ESTADO (PROVIDER):
/// - Injetado no topo absoluto do app (envolvendo o MaterialApp).
/// - Nenhuma tela recebe o SessaoService por construtor.
/// - Volatilidade: O token JWT permanece exclusivamente em memória.
/// NAVEGAÇÃO E ROTAS:
/// - Utiliza a propriedade `routes:` para registrar todas as telas.
/// - Telas sensíveis encapsuladas pelo guarda `RotaProtegida`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Instancia o repositório HTTP (único que faz chamadas à API)
  final authRepository = AuthRepository(
    baseUrl: ApiConstants.baseUrl,
  );

  // 2. Instancia o SessaoService (mantendo JWT volátil apenas em memória)
  final sessaoService = SessaoService(
    authRepository: authRepository,
  );

  // 3. Inicia a aplicação com ChangeNotifierProvider no topo absoluto
  runApp(
    ChangeNotifierProvider<SessaoService>(
      create: (_) => sessaoService,
      child: const ReqFlowApp(),
    ),
  );
}

class ReqFlowApp extends StatelessWidget {
  const ReqFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReqFlow - Engenharia de Requisitos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E60ED),
          primary: const Color(0xFF1E60ED),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E60ED), width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      initialRoute: AppRoutes.login,
      // REGRA OBRIGATÓRIA: Mapeamento de todas as telas na propriedade routes:
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.cadastro: (context) => const CadastroScreen(),
        AppRoutes.home: (context) => const RotaProtegida(child: HomeScreen()),
        AppRoutes.perfil: (context) => const RotaProtegida(child: PerfilScreen()),
        AppRoutes.projetos: (context) => const RotaProtegida(child: ProjetosScreen()),
      },
    );
  }
}
