import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../routes.dart';
import '../services/sessao_service.dart';
import '../widgets/app_drawer.dart';

/// Tela de Perfil do usuário logado no ReqFlow.
/// REQUISITO OBRIGATÓRIO:
/// 1. Exibe o nome e o e-mail do usuário consumindo essas informações reativamente da sessão.
/// 2. Proibição de injeção por construtor: Não recebe SessaoService por parâmetro.
/// 3. Utiliza explicitamente Scaffold, Column, Row e Container.
/// 4. Possui o Menu Lateral (Drawer) compartilhado.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

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
    // Consome reativamente os dados da sessão via Provider
    final sessao = context.watch<SessaoService>();
    final usuario = sessao.usuario;
    final nome = usuario?.nome ?? 'Usuário';
    final email = usuario?.email ?? 'usuario@reqflow.com';
    final idUsuario = usuario?.id != null ? '#${usuario!.id}' : 'N/A';
    final iniciais = _obterIniciais(nome);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        title: const Text(
          'Meu Perfil',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            onPressed: () {
              context.read<SessaoService>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(rotaAtual: AppRoutes.perfil),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              // Uso explícito de Column
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cartão Principal de Perfil
                  // Uso explícito de Container
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar com iniciais
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: const Color(0xFF15294E),
                          child: Text(
                            iniciais,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nome reativo do usuário
                        Text(
                          nome,
                          key: const Key('perfilNomeText'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // E-mail reativo do usuário
                        Text(
                          email,
                          key: const Key('perfilEmailText'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Badges de status
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Identificador: $idUsuario',
                                style: const TextStyle(
                                  color: Color(0xFF1E60ED),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Sessão Ativa (JWT em Memória)',
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cartão com Informações da Conta
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalhes da Conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Nome Completo',
                          value: nome,
                        ),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.alternate_email_rounded,
                          label: 'E-mail Cadastrado',
                          value: email,
                        ),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.security_rounded,
                          label: 'Status de Autenticação',
                          value: sessao.isAuthenticated ? 'Autenticado' : 'Não autenticado',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botão de Logout secundário
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: OutlinedButton.icon(
                      key: const Key('perfilLogoutButton'),
                      onPressed: () {
                        context.read<SessaoService>().logout();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                      label: const Text(
                        'Encerrar Sessão',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    // Uso explícito de Row
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
