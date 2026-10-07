import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/auth_repository.dart';
import '../routes.dart';
import '../services/sessao_service.dart';

/// Tela de Cadastro do sistema ReqFlow.
/// RESTRIÇÃO ARQUITETURAL: A tela NUNCA faz HTTP diretamente; delega exclusivamente ao SessaoService.
/// PROIBIÇÃO DE INJEÇÃO POR CONSTRUTOR: Nenhuma tela pode receber o SessaoService pelo construtor.
/// REQUISITO OBRIGATÓRIO: Utiliza explicitamente Scaffold, Column, Row e Container.
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmaSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaSenhaController.dispose();
    super.dispose();
  }

  Future<void> _handleCadastro() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_senhaController.text != _confirmaSenhaController.text) {
      setState(() {
        _errorMessage = 'As senhas informadas não coincidem.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Chama exclusivamente a camada de serviço via context.read<SessaoService>()
      await context.read<SessaoService>().cadastrar(
        _nomeController.text,
        _emailController.text,
        _senhaController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso! Faça login para continuar.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao realizar cadastro: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Uso explícito de Scaffold
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              // Uso explícito de Column
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo e Cabeçalho ReqFlow
                  Center(
                    // Uso explícito de Container
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF15294E),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Criar Conta no ReqFlow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cadastre-se para acessar a gestão de requisitos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cartão Principal de Cadastro
                  // Uso explícito de Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    // Uso explícito de Column
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner de Erro
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Campo Nome Completo
                          const Text(
                            'Nome Completo',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('nomeField'),
                            controller: _nomeController,
                            decoration: InputDecoration(
                              hintText: 'Ex: Carlos Mendes',
                              prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Informe seu nome completo';
                              if (val.trim().length < 2) return 'O nome deve ter ao menos 2 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo E-mail
                          const Text(
                            'E-mail Corporativo',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('emailCadastroField'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'carlos@empresa.com',
                              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Informe seu e-mail';
                              if (!val.contains('@')) return 'Informe um e-mail válido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo Senha
                          const Text(
                            'Senha (mínimo 6 caracteres)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('senhaCadastroField'),
                            controller: _senhaController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Informe sua senha';
                              if (val.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo Confirmar Senha
                          const Text(
                            'Confirme sua Senha',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('confirmaSenhaField'),
                            controller: _confirmaSenhaController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Confirme sua senha';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Botão Cadastrar
                          // Uso explícito de Container
                          Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                            child: ElevatedButton(
                              key: const Key('cadastrarButton'),
                              onPressed: _isLoading ? null : _handleCadastro,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E60ED),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Finalizar Cadastro',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Link para voltar ao Login
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Já tem uma conta?',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    } else {
                                      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                                    }
                                  },
                                  child: const Text(
                                    'Fazer login',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E60ED),
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

                  const SizedBox(height: 24),
                  const Text(
                    '© 2026 ReqFlow. Todos os direitos reservados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
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
}
