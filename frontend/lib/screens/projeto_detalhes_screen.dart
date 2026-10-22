import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../repositories/auth_repository.dart';
import '../services/projeto_service.dart';

/// Tela de Detalhes do Projeto.
/// RESTRIÇÃO ARQUITETURAL:
/// 1. A tela NUNCA faz chamadas HTTP e NUNCA manipula JSON ou Status Codes.
/// 2. Consome exclusivamente o `ProjetoService`.
/// 3. Recebe o `projetoId` como argumento da rota nomeada (`ModalRoute.of(context)!.settings.arguments`).
/// 4. Utiliza `FutureBuilder` com tratamento de estados (Carregando, Erro c/ Retry e Dados).
class ProjetoDetalhesScreen extends StatefulWidget {
  const ProjetoDetalhesScreen({super.key});

  @override
  State<ProjetoDetalhesScreen> createState() => _ProjetoDetalhesScreenState();
}

class _ProjetoDetalhesScreenState extends State<ProjetoDetalhesScreen> {
  Future<Projeto>? _futureProjeto;
  int? _projetoId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureProjeto == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _projetoId = args;
        _recarregar();
      }
    }
  }

  void _recarregar() {
    if (_projetoId != null) {
      setState(() {
        _futureProjeto = context.read<ProjetoService>().obterProjeto(_projetoId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Detalhes do Projeto',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _projetoId == null
            ? _buildArgumentoInvalido()
            : FutureBuilder<Projeto>(
                future: _futureProjeto,
                builder: (context, snapshot) {
                  // Estado 1: Carregando
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF1E60ED),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Carregando detalhes do projeto...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Estado 2: Erro com opção de Tentar Novamente
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    final mensagemErro = error is ApiException
                        ? error.message
                        : 'Não foi possível carregar os detalhes do projeto.';

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          padding: const EdgeInsets.all(28.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFEE2E2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Falha ao buscar projeto',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mensagemErro,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _recarregar,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Tentar de novo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E60ED),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Estado 3: Sucesso com dados preenchidos
                  final projeto = snapshot.data!;
                  return _buildConteudoProjeto(projeto);
                },
              ),
      ),
    );
  }

  Widget _buildArgumentoInvalido() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Color(0xFFD97706)),
            const SizedBox(height: 16),
            const Text(
              'Projeto não identificado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O identificador do projeto não foi fornecido na rota.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar para Projetos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoProjeto(Projeto projeto) {
    final dataFormatada =
        '${projeto.createdAt.day.toString().padLeft(2, '0')}/${projeto.createdAt.month.toString().padLeft(2, '0')}/${projeto.createdAt.year} às ${projeto.createdAt.hour.toString().padLeft(2, '0')}:${projeto.createdAt.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card do Cabeçalho Principal
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.folder_open_rounded,
                            color: Color(0xFF1E60ED),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                projeto.nome,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Identificador: #${projeto.id}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),
                    const Text(
                      'Descrição do Projeto',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      projeto.descricao != null && projeto.descricao!.trim().isNotEmpty
                          ? projeto.descricao!
                          : 'Nenhuma descrição fornecida para este projeto.',
                      style: TextStyle(
                        fontSize: 14,
                        color: projeto.descricao != null && projeto.descricao!.trim().isNotEmpty
                            ? const Color(0xFF334155)
                            : const Color(0xFF94A3B8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Metadados do Projeto
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildMetaRow(
                      icon: Icons.calendar_today_rounded,
                      titulo: 'Data de Criação',
                      valor: dataFormatada,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFF1F5F9)),
                    ),
                    _buildMetaRow(
                      icon: Icons.person_outline_rounded,
                      titulo: 'ID do Autor',
                      valor: 'Usuário #${projeto.usuarioId}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seção Informativa de Requisitos Futuros
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.checklist_rounded, color: Color(0xFF16A34A), size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'O módulo de gerenciamento de requisitos deste projeto será integrado nesta visualização.',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
