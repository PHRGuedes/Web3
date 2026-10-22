import 'package:shared_preferences/shared_preferences.dart';

/// Interface abstrata do repositório de persistência local.
/// Facilita injeção e testes mockados.
abstract class ILocalStorageRepository {
  Future<void> salvarToken(String token);
  Future<String?> obterToken();
  Future<void> removerToken();
  Future<bool> possuiToken();
}

/// Implementação concreta do armazenamento local utilizando SharedPreferences.
/// REGRA ARQUITETURAL: Pertence à camada `repositories/` como fonte de dados de I/O em disco.
class LocalStorageRepository implements ILocalStorageRepository {
  static const String keyToken = 'reqflow_auth_jwt_token';
  final SharedPreferences? _prefs;

  LocalStorageRepository({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<void> salvarToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(keyToken, token);
  }

  @override
  Future<String?> obterToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(keyToken);
  }

  @override
  Future<void> removerToken() async {
    final prefs = await _getPrefs();
    await prefs.remove(keyToken);
  }

  @override
  Future<bool> possuiToken() async {
    final token = await obterToken();
    return token != null && token.trim().isNotEmpty;
  }
}
