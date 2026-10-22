import '../models/projeto.dart';
import '../repositories/auth_repository.dart'; // ApiException
import '../repositories/projeto_repository.dart';
import 'sessao_service.dart';

/// Serviço responsável pelas regras de negócio e orquestração de Projetos.
/// REGRA ARQUITETURAL:
/// 1. Não faz chamadas HTTP diretas (delega para IProjetoRepository).
/// 2. Valida a existência do Token ativo da sessão.
/// 3. Em caso de erro 401 (Unauthorized), aciona a limpeza da sessão no SessaoService.
class ProjetoService {
  final IProjetoRepository projetoRepository;
  final SessaoService sessaoService;

  ProjetoService({
    required this.projetoRepository,
    required this.sessaoService,
  });

  /// Busca a lista de projetos do usuário logado.
  Future<List<Projeto>> listarProjetos({String? searchNome}) async {
    final token = sessaoService.token;
    if (token == null || token.isEmpty) {
      await sessaoService.tratarFugaSessao401();
      throw const ApiException('Sessão expirada. Faça login novamente.', 401);
    }

    try {
      return await projetoRepository.listarProjetos(
        token: token,
        searchNome: searchNome,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await sessaoService.tratarFugaSessao401();
      }
      rethrow;
    }
  }

  /// Busca os detalhes de um projeto específico através do seu ID.
  Future<Projeto> obterProjeto(int projetoId) async {
    if (projetoId <= 0) {
      throw const ApiException('Identificador de projeto inválido.');
    }

    final token = sessaoService.token;
    if (token == null || token.isEmpty) {
      await sessaoService.tratarFugaSessao401();
      throw const ApiException('Sessão expirada. Faça login novamente.', 401);
    }

    try {
      return await projetoRepository.obterProjeto(
        token: token,
        projetoId: projetoId,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await sessaoService.tratarFugaSessao401();
      }
      rethrow;
    }
  }
}
