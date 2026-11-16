import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/projeto.dart';
import '../repositories/auth_repository.dart'; // ApiException
import '../services/projeto_service.dart';

/// Tela única para Criação e Edição de Projetos de Requisitos do sistema ReqFlow.
/// RESTRIÇÕES ARQUITETURAIS:
/// 1. A tela NUNCA faz chamadas HTTP diretamente nem manipula JSON ou status codes.
/// 2. Consome exclusivamente o `ProjetoService` via Provider (`context.read<ProjetoService>()`).
/// 3. Utiliza explicitamente Form e TextFormField com validações (validator).
/// 4. Trata recusa da API (422, 409, 400, etc.) exibindo a frase exata retornada pela API e MANTENDO o formulário aberto.
/// 5. Ao salvar com sucesso, fecha a tela com `Navigator.pop(context, true)` para que a listagem se atualize.
class ProjetoFormScreen extends StatefulWidget {
  final Projeto? projetoInicial;

  const ProjetoFormScreen({
    super.key,
    this.projetoInicial,
  });

  @override
  State<ProjetoFormScreen> createState() => _ProjetoFormScreenState();
}

class _ProjetoFormScreenState extends State<ProjetoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  bool _isLoading = false;
  bool _initialized = false;
  int? _projetoId;
  String? _apiErrorMessage;

  bool get _isEditing => _projetoId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;

      // Prioriza o projetoInicial passado diretamente ou busca nos argumentos da rota
      final projeto = widget.projetoInicial ??
          (ModalRoute.of(context)?.settings.arguments is Projeto
              ? ModalRoute.of(context)!.settings.arguments as Projeto
              : null);

      if (projeto != null) {
        _projetoId = projeto.id;
        _nomeController.text = projeto.nome;
        _descricaoController.text = projeto.descricao ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    // Limpa erro anterior antes de validar
    setState(() {
      _apiErrorMessage = null;
    });

    // 1. Validação local dos campos através do Form e TextFormField (validator)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();

    try {
      final projetoService = context.read<ProjetoService>();

      if (_isEditing) {
        // Fluxo de Edição ponta a ponta (PATCH)
        await projetoService.atualizarProjeto(
          projetoId: _projetoId!,
          nome: nome,
          descricao: descricao.isEmpty ? null : descricao,
        );
      } else {
        // Fluxo de Criação ponta a ponta (POST)
        await projetoService.criarProjeto(
          nome: nome,
          descricao: descricao.isEmpty ? null : descricao,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Projeto atualizado com sucesso!'
                : 'Projeto criado com sucesso!',
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Fecha a tela retornando true para indicar que a lista deve ser atualizada
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;

      // REGRA OBRIGATÓRIA: Em caso de recusa da API (422, 409, etc.),
      // exibe a frase exata da API e MANTÉM o formulário aberto para correção.
      setState(() {
        _isLoading = false;
        _apiErrorMessage = e.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _apiErrorMessage = 'Ocorreu um erro inesperado: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_apiErrorMessage!),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _isEditing ? 'Editar Projeto' : 'Novo Projeto';
    final textoBotao = _isEditing ? 'Salvar Alterações' : 'Criar Projeto';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          titulo,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cabeçalho descritivo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _isEditing
                                  ? Icons.edit_note_rounded
                                  : Icons.add_circle_outline_rounded,
                              color: const Color(0xFF1E60ED),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titulo,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isEditing
                                      ? 'Atualize as informações do projeto #$_projetoId'
                                      : 'Preencha os campos para cadastrar um novo projeto',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // BANNER DE RECUSA DA API (Mantém formulário aberto)
                      if (_apiErrorMessage != null) ...[
                        Container(
                          key: const Key('banner_erro_api'),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Atenção: A API recusou os dados',
                                      style: TextStyle(
                                        color: Color(0xFF991B1B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _apiErrorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFB91C1C),
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // CAMPO: Nome do Projeto (Obrigatório)
                      const Text(
                        'Nome do Projeto *',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('campo_nome_projeto'),
                        controller: _nomeController,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Sistema de Gestão Hospitalar',
                          prefixIcon: Icon(
                            Icons.folder_outlined,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nome do projeto.';
                          }
                          if (value.trim().length < 2) {
                            return 'O nome deve ter no mínimo 2 caracteres.';
                          }
                          if (value.trim().length > 150) {
                            return 'O nome deve ter no máximo 150 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // CAMPO: Descrição (Opcional)
                      const Text(
                        'Descrição do Projeto (opcional)',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('campo_descricao_projeto'),
                        controller: _descricaoController,
                        enabled: !_isLoading,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Descreva os objetivos e o escopo do projeto...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value != null && value.length > 1000) {
                            return 'A descrição deve ter no máximo 1000 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // BOTÃO SALVAR / CARREGANDO
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          key: const Key('btn_salvar_projeto'),
                          onPressed: _isLoading ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E60ED),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF94A3B8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isEditing
                                          ? Icons.save_rounded
                                          : Icons.add_task_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      textoBotao,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // BOTÃO CANCELAR
                      SizedBox(
                        height: 44,
                        child: TextButton(
                          key: const Key('btn_cancelar_projeto'),
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
