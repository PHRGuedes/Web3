import 'package:flutter/foundation.dart';
import '../models/auth_token.dart';
import '../models/cadastro_request.dart';
import '../models/login_request.dart';
import '../models/usuario.dart';
import '../repositories/auth_repository.dart';
import '../repositories/local_storage_repository.dart';

/// Serviço responsável pelo gerenciamento de sessão, persistência e estado de autenticação.
/// REGRA DE NEGÓCIO: Herda de ChangeNotifier e utiliza notifyListeners()
/// para avisar a interface sobre mudanças de estado (login/logout).
/// PERSISTÊNCIA: Sincroniza o token JWT na memória e no ILocalStorageRepository (SharedPreferences).
class SessaoService extends ChangeNotifier {
  final IAuthRepository authRepository;
  final ILocalStorageRepository? storageRepository;

  String? _token;
  Usuario? _usuario;

  SessaoService({
    required this.authRepository,
    this.storageRepository,
  });

  /// Token JWT armazenado na sessão
  String? get token => _token;

  /// Usuário atualmente autenticado
  Usuario? get usuario => _usuario;

  /// Alias de conveniência para o usuário autenticado
  Usuario? get currentUser => _usuario;

  /// Retorna true se houver um token válido ativo
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

  /// Inicialização Silenciosa: restaura o token persistido no disco (se houver).
  Future<void> inicializarSessaoSilenciosa() async {
    if (storageRepository == null) return;
    try {
      final tokenSalvo = await storageRepository!.obterToken();
      if (tokenSalvo != null && tokenSalvo.trim().isNotEmpty) {
        _token = tokenSalvo.trim();
        notifyListeners();
      }
    } catch (_) {
      // Ignora falhas de leitura silenciosa para não quebrar inicialização
    }
  }

  /// Executa o login via repositório HTTP, armazena o token na memória e no storage,
  /// carrega os dados do usuário atual e notifica os ouvintes.
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

    // Salva o token na memória
    _token = authToken.accessToken;

    // Persiste no armazenamento físico
    if (storageRepository != null) {
      try {
        await storageRepository!.salvarToken(authToken.accessToken);
      } catch (_) {
        // Falha no disco não impede a sessão em memória
      }
    }

    try {
      _usuario = await authRepository.obterUsuarioLogado(authToken.accessToken);
    } catch (_) {
      // Se falhar a busca do usuário complementar, o token permanece ativo
    }

    notifyListeners();
    return authToken;
  }

  /// Regra de Negócio: Fluxo de Cadastro com Auto-Login.
  /// 1. Cria a conta no backend.
  /// 2. Executa login automático com as credenciais cadastradas.
  /// 3. Se o login automático falhar por rede, lança ApiException específica para guiar ao login.
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

    // 1. Cadastra o novo usuário na API
    final novoUsuario = await authRepository.cadastrar(request);

    // 2. Realiza o login automático
    try {
      await login(cleanEmail, cleanSenha);
    } catch (_) {
      // Caso a conta tenha sido criada com sucesso mas a rede falhe no login automático
      throw const ApiException(
        'Conta criada com sucesso! Por favor, confirme suas credenciais na tela de login.',
        201,
      );
    }

    return novoUsuario;
  }

  /// Faz a requisição GET /usuarios/eu utilizando o token em memória
  Future<Usuario> carregarUsuarioAtual() async {
    final activeToken = _token;
    if (activeToken == null || activeToken.isEmpty) {
      await tratarFugaSessao401();
      throw const ApiException('Sessão expirada ou não autenticada. Faça login novamente.', 401);
    }

    try {
      final usuarioCarregado = await authRepository.obterUsuarioLogado(activeToken);
      _usuario = usuarioCarregado;
      notifyListeners();
      return usuarioCarregado;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await tratarFugaSessao401();
      }
      rethrow;
    }
  }

  /// Fuga de sessão: limpa os dados físicos e em memória e notifica os ouvintes para forçar
  /// o redirecionamento imediato para a tela de Login através da RotaProtegida.
  Future<void> tratarFugaSessao401() async {
    _token = null;
    _usuario = null;
    if (storageRepository != null) {
      try {
        await storageRepository!.removerToken();
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Encerra a sessão explicitamente (Ação de Sair).
  Future<void> logout() async {
    await tratarFugaSessao401();
  }
}
