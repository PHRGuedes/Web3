import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../routes.dart';
import '../services/sessao_service.dart';

/// Menu Lateral (Drawer) compartilhado entre todas as telas protegidas do ReqFlow.
/// REQUISITO OBRIGATÓRIO:
/// 1. Exibe o nome do usuário logado reativamente consumido do Provider (SessaoService).
/// 2. Contém botão 'Sair' (Logout) que limpa os dados da sessão e reseta
///    a pilha de navegação para a tela de Login via pushNamedAndRemoveUntil.
class AppDrawer extends StatelessWidget {
  final String? rotaAtual;

  const AppDrawer({
    super.key,
    this.rotaAtual,
  });

  String _obterIniciais(String nome) {
    if (nome.trim().isEmpty) return 'U';
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.length == 1) {
      return partes.first.substring(0, partes.first.length > 2 ? 2 : partes.first.length).toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Consome os dados da sessão reativamente via Provider
    final sessao = context.watch<SessaoService>();
    final nomeUsuario = sessao.usuario?.nome ?? 'Usuário Conectado';
    final emailUsuario = sessao.usuario?.email ?? 'usuario@reqflow.com';
    final iniciais = _obterIniciais(nomeUsuario);

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho do Drawer com dados do Usuário
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 24, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF15294E), Color(0xFF1E60ED)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        iniciais,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomeUsuario,
                            key: const Key('drawerUserName'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            emailUsuario,
                            key: const Key('drawerUserEmail'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Sessão Ativa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Itens de Navegação
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  title: 'Início',
                  route: AppRoutes.home,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.folder_open_outlined,
                  selectedIcon: Icons.folder_rounded,
                  title: 'Projetos',
                  route: AppRoutes.projetos,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  title: 'Meu Perfil',
                  route: AppRoutes.perfil,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Botão Sair (Logout)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              key: const Key('drawerLogoutButton'),
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                // 1. Limpa os dados de sessão no Provider
                context.read<SessaoService>().logout();

                // 2. Reseta a pilha de navegação e envia para o Login via pushNamedAndRemoveUntil
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Sair da Conta',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required String route,
  }) {
    final bool isSelected = rotaAtual == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: const Color(0xFFEFF6FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? const Color(0xFF1E60ED) : const Color(0xFF64748B),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF1E60ED) : const Color(0xFF334155),
          ),
        ),
        onTap: () {
          // Fecha o drawer
          Navigator.of(context).pop();

          if (!isSelected) {
            // Navega para a rota desejada via pushReplacementNamed
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
      ),
    );
  }
}
