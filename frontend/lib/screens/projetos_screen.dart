import 'package:flutter/material.dart';
import '../routes.dart';
import '../widgets/app_drawer.dart';

/// Tela de Projetos (Placeholder) do sistema de Engenharia de Requisitos (ReqFlow).
/// REQUISITO OBRIGATÓRIO:
/// 1. Atua como o lugar reservado para gestão de projetos de requisitos.
/// 2. Proibição de injeção por construtor: Não recebe SessaoService por parâmetro.
/// 3. Utiliza explicitamente Scaffold, Column, Row e Container.
/// 4. Possui o Menu Lateral (Drawer) compartilhado.
class ProjetosScreen extends StatelessWidget {
  const ProjetosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        title: const Text(
          'Projetos de Requisitos',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      drawer: const AppDrawer(rotaAtual: AppRoutes.projetos),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              // Uso explícito de Column
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho da Seção de Projetos
                  // Uso explícito de Container
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15294E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Uso explícito de Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_tree_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Engenharia de Requisitos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Gerenciamento de Épicos, Histórias de Usuário e Critérios de Aceite',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E60ED).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1E60ED).withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            'Área Reservada: O catálogo completo de requisitos e rastreabilidade estará disponível na próxima iteração.',
                            style: TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Título da Lista
                  const Text(
                    'Projetos em Andamento (Demonstração)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cards de Projetos (Placeholder)
                  _buildProjetoCard(
                    nome: 'ReqFlow - Sistema Web & Mobile',
                    descricao: 'Módulo de autenticação segura, gestão de sessões em memória e rastreabilidade de requisitos.',
                    status: 'Em Desenvolvimento',
                    requisitosCount: 18,
                    statusColor: const Color(0xFF1E60ED),
                    statusBg: const Color(0xFFEFF6FF),
                  ),
                  const SizedBox(height: 14),
                  _buildProjetoCard(
                    nome: 'Portal Corporativo de Requisitos',
                    descricao: 'Levantamento de histórias de usuário, elicitação de stakeholders e matriz de rastreabilidade.',
                    status: 'Planejamento',
                    requisitosCount: 12,
                    statusColor: const Color(0xFFD97706),
                    statusBg: const Color(0xFFFEF3C7),
                  ),
                  const SizedBox(height: 14),
                  _buildProjetoCard(
                    nome: 'API de Integração Contínua ReqFlow',
                    descricao: 'Serviços REST para versionamento de requisitos e sincronização com repositórios Git.',
                    status: 'Concluído',
                    requisitosCount: 8,
                    statusColor: const Color(0xFF059669),
                    statusBg: const Color(0xFFD1FAE5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjetoCard({
    required String nome,
    required String descricao,
    required String status,
    required int requisitosCount,
    required Color statusColor,
    required Color statusBg,
  }) {
    // Uso explícito de Container
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Uso explícito de Column
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Rodapé do Card
          Row(
            children: [
              const Icon(Icons.list_alt_rounded, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                '$requisitosCount Requisitos especificados',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
