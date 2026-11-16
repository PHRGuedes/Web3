import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/projeto.dart';
import 'auth_repository.dart'; // Reutiliza ApiException

/// Interface abstrata do repositório de projetos para permitir testes unitários mockados.
abstract class IProjetoRepository {
  Future<List<Projeto>> listarProjetos({required String token, String? searchNome});
  Future<Projeto> obterProjeto({required String token, required int projetoId});
  Future<Projeto> criarProjeto({
    required String token,
    required String nome,
    String? descricao,
  });
  Future<Projeto> atualizarProjeto({
    required String token,
    required int projetoId,
    required String nome,
    String? descricao,
  });
  Future<void> deletarProjeto({
    required String token,
    required int projetoId,
  });
}

/// Implementação concreta do Repositório de Projetos.
/// REGRA ARQUITETURAL: Esta é a ÚNICA camada autorizada a fazer chamadas HTTP para o recurso `/projetos`.
class ProjetoRepository implements IProjetoRepository {
  final String baseUrl;
  final http.Client client;

  ProjetoRepository({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  Map<String, String> _buildHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  @override
  Future<List<Projeto>> listarProjetos({required String token, String? searchNome}) async {
    final queryParams = <String, String>{};
    if (searchNome != null && searchNome.trim().isNotEmpty) {
      queryParams['nome'] = searchNome.trim();
    }

    final baseUri = Uri.parse('$baseUrl/projetos/');
    final uri = queryParams.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParams);

    try {
      final response = await client.get(
        uri,
        headers: _buildHeaders(token),
      );

      final data = _processResponse(response);
      if (data is List) {
        return data
            .map((item) => Projeto.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => Projeto.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Falha ao conectar com o serviço de projetos: ${e.toString()}');
    }
  }

  @override
  Future<Projeto> obterProjeto({required String token, required int projetoId}) async {
    final uri = Uri.parse('$baseUrl/projetos/$projetoId');
    try {
      final response = await client.get(
        uri,
        headers: _buildHeaders(token),
      );

      final data = _processResponse(response);
      if (data is Map<String, dynamic>) {
        return Projeto.fromJson(data);
      }
      throw const ApiException('Formato de resposta inválido ao obter projeto.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Falha ao obter detalhes do projeto: ${e.toString()}');
    }
  }

  @override
  Future<Projeto> criarProjeto({
    required String token,
    required String nome,
    String? descricao,
  }) async {
    final uri = Uri.parse('$baseUrl/projetos/');
    try {
      final response = await client.post(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode({
          'nome': nome,
          'descricao': descricao,
        }),
      );

      final data = _processResponse(response);
      if (data is Map<String, dynamic>) {
        return Projeto.fromJson(data);
      }
      throw const ApiException('Formato de resposta inválido ao criar projeto.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Falha ao criar projeto: ${e.toString()}');
    }
  }

  @override
  Future<Projeto> atualizarProjeto({
    required String token,
    required int projetoId,
    required String nome,
    String? descricao,
  }) async {
    final uri = Uri.parse('$baseUrl/projetos/$projetoId');
    try {
      final response = await client.patch(
        uri,
        headers: _buildHeaders(token),
        body: jsonEncode({
          'nome': nome,
          'descricao': descricao,
        }),
      );

      final data = _processResponse(response);
      if (data is Map<String, dynamic>) {
        return Projeto.fromJson(data);
      }
      throw const ApiException('Formato de resposta inválido ao atualizar projeto.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Falha ao atualizar projeto: ${e.toString()}');
    }
  }

  @override
  Future<void> deletarProjeto({
    required String token,
    required int projetoId,
  }) async {
    final uri = Uri.parse('$baseUrl/projetos/$projetoId');
    try {
      final response = await client.delete(
        uri,
        headers: _buildHeaders(token),
      );

      _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Falha ao excluir projeto: ${e.toString()}');
    }
  }

  /// Trata a resposta HTTP da API FastAPI
  dynamic _processResponse(http.Response response) {
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        body = {'mensagem': response.body};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorMessage = 'Erro ao processar requisição (${response.statusCode})';

    if (body is Map<String, dynamic>) {
      if (body.containsKey('detalhes') &&
          body['detalhes'] is List &&
          (body['detalhes'] as List).isNotEmpty) {
        final firstDet = (body['detalhes'] as List).first;
        if (firstDet is Map && firstDet.containsKey('mensagem')) {
          errorMessage = firstDet['mensagem'].toString();
        } else if (body.containsKey('mensagem')) {
          errorMessage = body['mensagem'].toString();
        }
      } else if (body.containsKey('mensagem')) {
        errorMessage = body['mensagem'].toString();
      } else if (body.containsKey('detail')) {
        final detail = body['detail'];
        if (detail is String) {
          errorMessage = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first.containsKey('msg')) {
            errorMessage = first['msg'].toString();
          } else {
            errorMessage = detail.toString();
          }
        }
      } else if (body.containsKey('erro')) {
        errorMessage = body['erro'].toString();
      }
    }

    throw ApiException(errorMessage, response.statusCode);
  }
}
