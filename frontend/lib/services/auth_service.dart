import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../models/auth_token.dart';
import '../models/login_request.dart';
import '../models/cadastro_request.dart';
import '../repositories/auth_repository.dart';

/// Camada de regra de negócio e orquestração.
/// REGRA ARQUITETURAL: Chama o repositório, gerencia e armazena o token JWT localmente,
/// valida regras de negócio e expõe dados prontos para a tela.
class AuthService {
  final IAuthRepository repository;
  final SharedPreferences? prefs;

  static const String _storageTokenKey = 'reqflow_auth_jwt_token';

  String? _jwtToken;
  Usuario? _currentUser;

  AuthService({
    required this.repository,
    this.prefs,
  }) {
    // Carrega o token previamente salvo se SharedPreferences estiver disponível
    _jwtToken = prefs?.getString(_storageTokenKey);
  }

  /// Retorna o token JWT atual em memória
  String? get token => _jwtToken;

  /// Retorna o usuário logado em cache
  Usuario? get currentUser => _currentUser;

  /// Indica se há uma sessão autenticada com token presente
  bool get isAuthenticated => _jwtToken != null && _jwtToken!.trim().isNotEmpty;

  /// Define o token manualmente (útil para testes ou injeção)
  void setToken(String? token) {
    _jwtToken = token;
  }

  /// Regra de Negócio: Fluxo de Login com persistência de token JWT.
  /// Valida as credenciais na camada de serviço, despacha para o repositório e salva o token.
  Future<AuthToken> login(String email, String senha) async {
    final cleanEmail = email.trim();
    final cleanSenha = senha.trim();

    if (cleanEmail.isEmpty) {
      throw const ApiException('O e-mail é obrigatório para realizar o login.');
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      throw const ApiException('Informe um e-mail em formato válido.');
    }
    if (cleanSenha.isEmpty) {
      throw const ApiException('A senha é obrigatória.');
    }

    final request = LoginRequest(email: cleanEmail, senha: cleanSenha);
    final authToken = await repository.login(request);

    // Salva o token JWT localmente
    _jwtToken = authToken.accessToken;
    if (prefs != null) {
      await prefs!.setString(_storageTokenKey, authToken.accessToken);
    }

    return authToken;
  }

  /// Regra de Negócio: Fluxo de Cadastro de novos usuários.
  Future<Usuario> cadastrar(String nome, String email, String senha) async {
    final cleanNome = nome.trim();
    final cleanEmail = email.trim();
    final cleanSenha = senha.trim();

    if (cleanNome.length < 2) {
      throw const ApiException('O nome completo deve conter ao menos 2 caracteres.');
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw const ApiException('Informe um e-mail válido para o cadastro.');
    }
    if (cleanSenha.length < 6) {
      throw const ApiException('A senha deve possuir pelo menos 6 caracteres.');
    }

    final request = CadastroRequest(
      nome: cleanNome,
      email: cleanEmail,
      senha: cleanSenha,
    );

    return await repository.cadastrar(request);
  }

  /// Regra de Negócio: Consulta obrigatória de `GET /usuarios/eu` enviando o token JWT.
  /// Chamado na inicialização da Tela Inicial para carregar os dados reais do usuário autenticado.
  Future<Usuario> obterUsuarioAtual() async {
    final activeToken = _jwtToken;
    if (activeToken == null || activeToken.isEmpty) {
      throw const ApiException('Sessão expirada ou não autenticada. Faça login novamente.', 401);
    }

    final usuario = await repository.obterUsuarioLogado(activeToken);
    _currentUser = usuario;
    return usuario;
  }

  /// Encerra a sessão atual e remove o token do armazenamento
  Future<void> logout() async {
    _jwtToken = null;
    _currentUser = null;
    if (prefs != null) {
      await prefs!.remove(_storageTokenKey);
    }
  }
}
