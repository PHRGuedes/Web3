import 'package:flutter/foundation.dart';
import '../models/auth_token.dart';
import '../models/cadastro_request.dart';
import '../models/login_request.dart';
import '../models/usuario.dart';
import '../repositories/auth_repository.dart';

/// Serviço responsável pelo gerenciamento de sessão e estado de autenticação.
/// REGRA DE NEGÓCIO: Herda de ChangeNotifier e utiliza notifyListeners()
/// para avisar a interface sobre mudanças de estado (login/logout).
/// REGRA DE SEGURANÇA / VOLATILIDADE: O token JWT e os dados do usuário são mantidos
/// APENAS na memória (sem SharedPreferences ou SecureStorage nesta etapa).
class SessaoService extends ChangeNotifier {
  final IAuthRepository authRepository;

  String? _token;
  Usuario? _usuario;

  SessaoService({
    required this.authRepository,
  });

  /// Token JWT armazenado exclusivamente na memória
  String? get token => _token;

  /// Usuário atualmente autenticado em memória
  Usuario? get usuario => _usuario;

  /// Alias de conveniência para o usuário autenticado
  Usuario? get currentUser => _usuario;

  /// Retorna true se houver um token válido em memória
  bool get isAuthenticated => _token != null && _token!.trim().isNotEmpty;

  /// Permite definir o token manualmente (útil para testes ou transições controladas)
  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }

  /// Permite definir o usuário manualmente (útil para testes ou mocks)
  void setUsuario(Usuario? usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  /// Executa o login via repositório HTTP, armazena o token na memória
  /// e carrega os dados do usuário atual, notificando os ouvintes.
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
    final authToken = await authRepository.login(request);

    // Salva token estritamente na memória
    _token = authToken.accessToken;

    try {
      _usuario = await authRepository.obterUsuarioLogado(authToken.accessToken);
    } catch (_) {
      // Se falhar a busca do usuário complementar, o token ainda permanece ativo
    }

    notifyListeners();
    return authToken;
  }

  /// Regra de Negócio: Fluxo de Cadastro de novos usuários delegando ao repositório.
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

    return await authRepository.cadastrar(request);
  }

  /// Faz a requisição GET /usuarios/eu utilizando o token em memória
  Future<Usuario> carregarUsuarioAtual() async {
    final activeToken = _token;
    if (activeToken == null || activeToken.isEmpty) {
      throw const ApiException('Sessão expirada ou não autenticada. Faça login novamente.', 401);
    }

    final usuarioCarregado = await authRepository.obterUsuarioLogado(activeToken);
    _usuario = usuarioCarregado;
    notifyListeners();
    return usuarioCarregado;
  }

  /// Encerra a sessão, limpando o token e dados do usuário da memória e notificando a UI.
  void logout() {
    _token = null;
    _usuario = null;
    notifyListeners();
  }
}
