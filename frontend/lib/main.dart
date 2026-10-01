import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/api_constants.dart';
import 'repositories/auth_repository.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Ponto de entrada da aplicação Flutter.
/// REGRA ARQUITETURAL: Responsável pela montagem e injeção de dependências
/// (instancia repositório, serviço e passa para as telas).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    // Permite inicialização sem erro caso SharedPreferences falhe em ambiente restrito
    prefs = null;
  }

  // 1. Instancia o repositório HTTP (único que faz chamadas à API)
  final authRepository = AuthRepository(
    baseUrl: ApiConstants.baseUrl,
  );

  // 2. Instancia o serviço de autenticação (orquestração e regras de negócio)
  final authService = AuthService(
    repository: authRepository,
    prefs: prefs,
  );

  // 3. Inicia o aplicativo passando as dependências montadas
  runApp(ReqFlowApp(authService: authService));
}

class ReqFlowApp extends StatelessWidget {
  final AuthService authService;

  const ReqFlowApp({
    super.key,
    required this.authService,
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
          background: const Color(0xFFF8FAFC),
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
      // Se houver token prévio salvo, abre direto na Home; senão abre no Login
      home: authService.isAuthenticated
          ? HomeScreen(authService: authService)
          : LoginScreen(authService: authService),
    );
  }
}
