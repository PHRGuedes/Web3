# Gerência de Estado com Provider

## 1. Visão Geral

O gerenciamento de estado da sessão do usuário utiliza o pacote `provider` (versão 6.1.x) com um serviço centralizado (`SessaoService`) que herda de `ChangeNotifier`.

---

## 2. Estrutura do `SessaoService` (`lib/services/sessao_service.dart`)

O `SessaoService` é a única fonte da verdade sobre o estado de autenticação e os dados do usuário conectado.

### Principais Propriedades:
- `String? get token`: Retorna o token JWT mantido exclusivamente em memória RAM.
- `Usuario? get usuario`: Retorna o modelo do usuário autenticado.
- `bool get isAuthenticated`: Avalia se há um token JWT válido ativo (`_token != null && _token!.trim().isNotEmpty`).

### Principais Métodos:
- `Future<AuthToken> login(String email, String senha)`: Valida os dados, faz a autenticação via repositório HTTP, guarda o token e dados do usuário na memória e invoca `notifyListeners()`.
- `Future<Usuario> cadastrar(String nome, String email, String senha)`: Encaminha a criação de conta para a camada de persistência.
- `Future<Usuario> carregarUsuarioAtual()`: Executa `GET /usuarios/eu` enviando o token em memória e notifica os ouvintes.
- `void logout()`: Limpa os campos `_token` e `_usuario` e invoca `notifyListeners()`.
- `void setToken(String?)` e `void setUsuario(Usuario?)`: Métodos auxiliares para injeção controlada de estado e cenários de testes unitários.

---

## 3. Injeção no Topo Absoluto (`lib/main.dart`)

O Provider é injetado no ponto mais alto da árvore de widgets, envolvendo o próprio `MaterialApp`:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final authRepository = AuthRepository(
    baseUrl: ApiConstants.baseUrl,
  );

  final sessaoService = SessaoService(
    authRepository: authRepository,
  );

  runApp(
    ChangeNotifierProvider<SessaoService>(
      create: (_) => sessaoService,
      child: const ReqFlowApp(),
    ),
  );
}
```

---

## 4. Regra de Proibição de Injeção por Construtor

**Regra Estrita**: Nenhuma tela (`Screen`) ou componente pode receber instâncias de `SessaoService` ou `AuthService` por meio de parâmetros de construtor.

### Para Disparar Ações:
Utilize sempre `context.read<SessaoService>()`. Não causa rebuild desnecessário do widget quando o estado é alterado.
```dart
// Exemplo no Login:
await context.read<SessaoService>().login(email, senha);

// Exemplo no Logout:
context.read<SessaoService>().logout();
```

### Para Reagir a Mudanças de Estado:
Utilize `context.watch<SessaoService>()` ou o widget `Consumer<SessaoService>`. Notifica o widget para reconstrução imediata ao invocar `notifyListeners()`.
```dart
// Exemplo no Drawer ou na Tela de Perfil:
final sessao = context.watch<SessaoService>();
final nome = sessao.usuario?.nome ?? 'Usuário';
```

---

## 5. Garantia de Volatilidade do Token JWT

Nesta etapa do projeto, o token JWT **NÃO** é persistido em `SharedPreferences` ou `FlutterSecureStorage`.
- O token é armazenado unicamente na variável privada `String? _token` da instância de `SessaoService`.
- Ao reiniciar a aplicação ou recarregar a página web (F5), a memória é reiniciada com `_token = null`.
- O `isAuthenticated` retorna `false` e a `RotaProtegida` redireciona imediatamente para a tela de Login.
