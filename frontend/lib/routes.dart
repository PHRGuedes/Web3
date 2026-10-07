import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/sessao_service.dart';

/// Constantes com os nomes das rotas do sistema ReqFlow.
/// RESTRIÇÃO SEVERA: A navegação no app deve ser feita exclusivamente
/// utilizando Navigator.pushNamed, pushReplacementNamed e pushNamedAndRemoveUntil.
class AppRoutes {
  static const String login = '/login';
  static const String cadastro = '/cadastro';
  static const String home = '/home';
  static const String perfil = '/perfil';
  static const String projetos = '/projetos';

  /// Lista de rotas restritas que exigem sessão ativa
  static const List<String> rotasProtegidas = [
    home,
    perfil,
    projetos,
  ];

  /// Helper para encapsular telas que exigem autenticação
  static Widget proteger(Widget tela) {
    return RotaProtegida(child: tela);
  }
}

/// Guarda de rotas (Route Guard) para telas protegidas.
/// REGRA DE SEGURANÇA: Se o usuário tentar acessar uma tela protegida
/// (ex: dar F5 no navegador ou navegar diretamente) sem estar logado,
/// ele é imediatamente redirecionado para a tela de Login via pushNamedAndRemoveUntil.
class RotaProtegida extends StatelessWidget {
  final Widget child;

  const RotaProtegida({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<SessaoService>();

    if (!sessao.isAuthenticated) {
      // Redireciona imediatamente para o login ao detectar ausência de token
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
      });

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return child;
  }
}
