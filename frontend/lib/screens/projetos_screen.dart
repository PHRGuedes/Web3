import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../repositories/auth_repository.dart';
import '../routes.dart';
import '../services/projeto_service.dart';
import '../widgets/app_drawer.dart';

/// Tela de Listagem de Projetos de Requisitos do sistema ReqFlow.
/// RESTRIÇÃO ARQUITETURAL:
/// 1. A tela NUNCA faz chamadas HTTP e NUNCA manipula JSON ou Status Codes (200, 400, 404).
/// 2. Consome exclusivamente o `ProjetoService`.
/// 3. OBRIGATÓRIO: Uso de `FutureBuilder` e `ListView.builder`.
/// 4. Tratamento explícito de 4 Estados:
///    a) Carregando (CircularProgressIndicator).
///    b) Erro (mensagem amigável da ApiException + botão "Tentar de novo").
///    c) Lista Vazia (mensagem clara de ausência de registros).
///    d) Lista Preenchida (ListView.builder desenhando os cards reais).
/// 5. Ao tocar no card, navega para AppRoutes.projetoDetalhes passando `projeto.id` como argumento.
class ProjetosScreen extends StatefulWidget {
  const ProjetosScreen({super.key});

  @override
  State<ProjetosScreen> createState() => _ProjetosScreenState();
}

class _ProjetosScreenState extends State<ProjetosScreen> {
  Future<List<Projeto>>? _futureProjetos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureProjetos == null) {
      _carregarProjetos();
    }
  }

  void _carregarProjetos() {
    setState(() {
      _futureProjetos = context.read<ProjetoService>().listarProjetos();
    });
  }

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
        actions: [
          IconButton(
            tooltip: 'Atualizar lista',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E60ED)),
            onPressed: _carregarProjetos,
          ),
        ],
      ),
      drawer: const AppDrawer(rotaAtual: AppRoutes.projetos),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: FutureBuilder<List<Projeto>>(
              future: _futureProjetos,
              builder: (context, snapshot) {
                // ESTADO 1: Carregando
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
                          'Carregando projetos de requisitos...',
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

                // ESTADO 2: Erro com opção de Tentar Novamente
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final mensagemErro = error is ApiException
                      ? error.message
                      : 'Ocorreu um erro ao buscar os projetos.';

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
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
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Não foi possível carregar os projetos',
                              textAlign: TextAlign.center,
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
                              onPressed: _carregarProjetos,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Tentar de novo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E60ED),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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

                final projetos = snapshot.data ?? [];

                // ESTADO 3: Lista Vazia
                if (projetos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.folder_off_rounded,
                                color: Color(0xFF94A3B8),
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Nenhum projeto encontrado',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Você ainda não possui projetos cadastrados em sua conta.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: _carregarProjetos,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Recarregar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E60ED),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // ESTADO 4: Lista Preenchida (ListView.builder com cards reais)
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  itemCount: projetos.length + 1, // +1 para o cabeçalho explicativo
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _buildBannerInformativo(total: projetos.length),
                      );
                    }

                    final projeto = projetos[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: _buildProjetoCard(projeto),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerInformativo({required int total}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meus Projetos de Requisitos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total projeto(s) vinculado(s) à sua conta',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjetoCard(Projeto projeto) {
    final dataFormatada =
        '${projeto.createdAt.day.toString().padLeft(2, '0')}/${projeto.createdAt.month.toString().padLeft(2, '0')}/${projeto.createdAt.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // REGRA DE NAVEGAÇÃO: Rota nomeada passando projeto.id como argumento
          Navigator.of(context).pushNamed(
            AppRoutes.projetoDetalhes,
            arguments: projeto.id,
          );
        },
        child: Container(
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
                      projeto.nome,
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${projeto.id}',
                      style: const TextStyle(
                        color: Color(0xFF1E60ED),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                projeto.descricao != null && projeto.descricao!.trim().isNotEmpty
                    ? projeto.descricao!
                    : 'Sem descrição cadastrada.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Rodapé do Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        'Criado em $dataFormatada',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'Ver detalhes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E60ED),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF1E60ED)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
