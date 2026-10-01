import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// Tela Inicial (Dashboard) do ReqFlow.
/// REQUISITO OBRIGATÓRIO: Ao ser carregada, deve obrigatoriamente fazer uma requisição
/// GET /usuarios/eu enviando o token JWT no cabeçalho de autorização (via AuthService).
/// REQUISITO OBRIGATÓRIO: Utiliza explicitamente Scaffold, Column, Row e Container.
class HomeScreen extends StatefulWidget {
  final AuthService authService;

  const HomeScreen({
    super.key,
    required this.authService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Usuario? _usuario;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarUsuarioLogado();
  }

  /// REQUISITO DO SISTEMA:
  /// Faz a requisição obrigatória GET /usuarios/eu através da camada de serviço.
  Future<void> _carregarUsuarioLogado() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Chama o AuthService, que internamente aciona o AuthRepository com o token JWT
      final user = await widget.authService.obterUsuarioAtual();
      if (!mounted) return;
      setState(() {
        _usuario = user;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
      // Se não autorizado (401), desloga e redireciona
      if (e.statusCode == 401) {
        _handleLogout();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Falha ao obter perfil do usuário: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await widget.authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
    );
  }

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
    // Uso explícito de Scaffold
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        titleSpacing: 20,
        title: Row(
          children: [
            // Uso explícito de Container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E60ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.view_in_ar_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            // Uso explícito de Column
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ReqFlow',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Requisitos & Projetos',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_usuario != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              // Uso explícito de Row
              child: Row(
                children: [
                  // Avatar circular de iniciais
                  // Uso explícito de Container
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF15294E),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _obterIniciais(_usuario!.nome),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nome do usuário logado
                  // Uso explícito de Column
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _usuario!.nome,
                        key: const Key('usuarioNomeHeader'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Analista de Requisitos',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          IconButton(
            key: const Key('logoutButton'),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: 'Sair da conta',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E60ED)),
            ),
            SizedBox(height: 16),
            Text(
              'Carregando perfil via GET /usuarios/eu...',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        // Uso explícito de Container
        child: Container(
          margin: const EdgeInsets.all(24.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          // Uso explícito de Column
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Falha na Comunicação',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _carregarUsuarioLogado,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E60ED),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = _usuario!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      // Uso explícito de Column
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de Boas-vindas
          // Uso explícito de Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E60ED), Color(0xFF1742A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E60ED).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            // Uso explícito de Row
            child: Row(
              children: [
                Expanded(
                  // Uso explícito de Column
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${user.nome}!',
                        key: const Key('usuarioNomeBoasVindas'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sessão autenticada via JWT. Bem-vindo à plataforma de Engenharia de Requisitos.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Uso explícito de Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Título de Métricas
          const Text(
            'Visão Geral do Sistema',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Cards de Métricas em Row / Wrap
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricCard(
                titulo: 'Total de Requisitos',
                valor: '44',
                icone: Icons.description_outlined,
                corIcone: const Color(0xFF1E60ED),
                fundoIcone: const Color(0xFFEFF6FF),
              ),
              _buildMetricCard(
                titulo: 'Pendentes',
                valor: '8',
                icone: Icons.schedule_rounded,
                corIcone: const Color(0xFFF59E0B),
                fundoIcone: const Color(0xFFFEF3C7),
              ),
              _buildMetricCard(
                titulo: 'Aprovados',
                valor: '21',
                icone: Icons.check_circle_outline_rounded,
                corIcone: const Color(0xFF10B981),
                fundoIcone: const Color(0xFFD1FAE5),
              ),
              _buildMetricCard(
                titulo: 'Em Desenvolvimento',
                valor: '10',
                icone: Icons.code_rounded,
                corIcone: const Color(0xFF6366F1),
                fundoIcone: const Color(0xFFEEF2FF),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Cartão de Dados do Usuário Autenticado (GET /usuarios/eu)
          // Uso explícito de Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // Uso explícito de Column
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Uso explícito de Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dados do Usuário Autenticado (GET /usuarios/eu)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    // Uso explícito de Container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'JWT Ativo',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 16),

                _buildInfoRow(
                  label: 'ID do Usuário',
                  valor: '#${user.id}',
                  icone: Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  label: 'Nome Completo',
                  valor: user.nome,
                  icone: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  label: 'E-mail Cadastrado',
                  valor: user.email,
                  icone: Icons.mail_outline_rounded,
                ),
                if (user.createdAt != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    label: 'Data de Cadastro',
                    valor: user.createdAt!.toLocal().toString().split('.').first,
                    icone: Icons.calendar_today_outlined,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color corIcone,
    required Color fundoIcone,
  }) {
    // Uso explícito de Container
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Uso explícito de Column
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Uso explícito de Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: fundoIcone,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: corIcone, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String valor,
    required IconData icone,
  }) {
    // Uso explícito de Row
    return Row(
      children: [
        Icon(icone, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
