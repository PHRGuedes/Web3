import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuario.dart';
import '../models/auth_token.dart';
import '../models/login_request.dart';
import '../models/cadastro_request.dart';

/// Exceção de comunicação e regras da API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Interface abstrata do repositório para permitir testes unitários mockados.
abstract class IAuthRepository {
  Future<AuthToken> login(LoginRequest request);
  Future<Usuario> cadastrar(CadastroRequest request);
  Future<Usuario> obterUsuarioLogado(String token);
}

/// Implementação concreta do Repositório de Autenticação.
/// REGRA ARQUITETURAL: Esta é a ÚNICA camada autorizada a fazer chamadas HTTP.
class AuthRepository implements IAuthRepository {
  final String baseUrl;
  final http.Client client;

  AuthRepository({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  @override
  Future<AuthToken> login(LoginRequest request) async {
    final uri = Uri.parse('$baseUrl/usuarios/login');
    try {
      final response = await client.post(
        uri,
        headers: _baseHeaders,
        body: jsonEncode(request.toJson()),
      );

      final data = _processResponse(response);
      return AuthToken.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Falha de conexão com a API: ${e.toString()}');
    }
  }

  @override
  Future<Usuario> cadastrar(CadastroRequest request) async {
    final uri = Uri.parse('$baseUrl/usuarios/cadastro');
    try {
      final response = await client.post(
        uri,
        headers: _baseHeaders,
        body: jsonEncode(request.toJson()),
      );

      final data = _processResponse(response);
      return Usuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Falha de conexão com a API: ${e.toString()}');
    }
  }

  /// Requisição obrigatória para carregar perfil do usuário logado.
  /// Envia token JWT no cabeçalho `Authorization: Bearer <token>` para `GET /usuarios/eu`.
  @override
  Future<Usuario> obterUsuarioLogado(String token) async {
    final uri = Uri.parse('$baseUrl/usuarios/eu');
    try {
      final response = await client.get(
        uri,
        headers: {
          ..._baseHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      final data = _processResponse(response);
      return Usuario.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Falha ao consultar usuário autenticado: ${e.toString()}');
    }
  }

  /// Trata a resposta HTTP da API FastAPI
  Map<String, dynamic> _processResponse(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        } else {
          body = {'data': decoded};
        }
      } catch (_) {
        body = {'mensagem': response.body};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Tratamento de mensagens de erro formatadas no backend (FastAPI handlers e Pydantic)
    String errorMessage = 'Erro ao processar requisição (${response.statusCode})';

    if (body.containsKey('mensagem')) {
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

    throw ApiException(errorMessage, response.statusCode);
  }
}
