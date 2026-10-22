import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/api_constants.dart';
import 'repositories/auth_repository.dart';
import 'repositories/local_storage_repository.dart';
import 'repositories/projeto_repository.dart';
import 'routes.dart';
import 'screens/cadastro_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/projetos_screen.dart';
import 'screens/projeto_detalhes_screen.dart';
import 'services/projeto_service.dart';
import 'services/sessao_service.dart';

/// Ponto de entrada da aplicação Flutter (ReqFlow).
/// GERÊNCIA DE ESTADO (PROVIDER):
/// - Injetado no topo absoluto do app (envolvendo o MaterialApp via MultiProvider).
/// - Nenhuma tela recebe serviços por construtor.
/// - Persistência: O token JWT é persistido via LocalStorageRepository (SharedPreferences).
/// - Inicialização Silenciosa: Recupera o token antes de inicializar o app e ajusta initialRoute.
/// NAVEGAÇÃO E ROTAS:
/// - Mapeamento estrito em `routes:`.
/// - Telas sensíveis encapsuladas pelo guarda `RotaProtegida`.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Instancia os repositórios (únicos que realizam I/O e HTTP)
  final storageRepository = LocalStorageRepository();
  final authRepository = AuthRepository(
    baseUrl: ApiConstants.baseUrl,
  );
  final projetoRepository = ProjetoRepository(
    baseUrl: ApiConstants.baseUrl,
  );

  // 2. Instancia o SessaoService e inicializa sessão silenciosa
  final sessaoService = SessaoService(
    authRepository: authRepository,
    storageRepository: storageRepository,
  );
  await sessaoService.inicializarSessaoSilenciosa();

  // 3. Instancia o ProjetoService vinculado ao SessaoService
  final projetoService = ProjetoService(
    projetoRepository: projetoRepository,
    sessaoService: sessaoService,
  );

  // 4. Define rota inicial: se houver token no storage vai para Home, senão Login
  final initialRoute = sessaoService.isAuthenticated ? AppRoutes.home : AppRoutes.login;

  // 5. Inicia a aplicação com MultiProvider no topo absoluto
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessaoService>.value(value: sessaoService),
        Provider<ProjetoService>.value(value: projetoService),
      ],
      child: ReqFlowApp(initialRoute: initialRoute),
    ),
  );
}

class ReqFlowApp extends StatelessWidget {
  final String initialRoute;

  const ReqFlowApp({
    super.key,
    this.initialRoute = AppRoutes.login,
  });

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
      initialRoute: initialRoute,
      // REGRA OBRIGATÓRIA: Mapeamento de todas as telas na propriedade routes:
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.cadastro: (context) => const CadastroScreen(),
        AppRoutes.home: (context) => const RotaProtegida(child: HomeScreen()),
        AppRoutes.perfil: (context) => const RotaProtegida(child: PerfilScreen()),
        AppRoutes.projetos: (context) => const RotaProtegida(child: ProjetosScreen()),
        AppRoutes.projetoDetalhes: (context) => const RotaProtegida(child: ProjetoDetalhesScreen()),
      },
    );
  }
}
