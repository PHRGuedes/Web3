# Rotas, Navegação e Guarda de Rotas

## 1. Visão Geral

A arquitetura de navegação do frontend em Flutter foi projetada para garantir rotas declarativas centralizadas, transições seguras sem empilhamento indevido e proteção imediata contra acessos não autenticados (ex: reload/F5 ou navegação direta via URL).

---

## 2. Constantes de Rotas (`lib/routes.dart`)

Todas as rotas da aplicação são definidas como constantes estáticas dentro da classe `AppRoutes`:

```dart
class AppRoutes {
  static const String login = '/login';
  static const String cadastro = '/cadastro';
  static const String home = '/home';
  static const String perfil = '/perfil';
  static const String projetos = '/projetos';

  static const List<String> rotasProtegidas = [
    home,
    perfil,
    projetos,
  ];
}
```

---

## 3. Mapeamento de Rotas (`lib/main.dart`)

O registro de rotas é feito estritamente através da propriedade `routes:` do `MaterialApp`. Telas restritas são envolvidas pelo componente guarda `RotaProtegida`:

```dart
MaterialApp(
  initialRoute: AppRoutes.login,
  routes: {
    AppRoutes.login: (context) => const LoginScreen(),
    AppRoutes.cadastro: (context) => const CadastroScreen(),
    AppRoutes.home: (context) => const RotaProtegida(child: HomeScreen()),
    AppRoutes.perfil: (context) => const RotaProtegida(child: PerfilScreen()),
    AppRoutes.projetos: (context) => const RotaProtegida(child: ProjetosScreen()),
  },
);
```

---

## 4. Regras Estritas de Transição

Todas as navegações devem utilizar os métodos nomeados do `Navigator`:

1. **Avanço Normal (`pushNamed`)**: Utilizado para abrir telas sem descartar o histórico anterior (ex: Login -> Cadastro).
   ```dart
   Navigator.of(context).pushNamed(AppRoutes.cadastro);
   ```

2. **Substituição de Rota (`pushReplacementNamed`)**: Utilizado para transições de fluxo direto, como navegação entre abas pelo menu lateral ou após o login bem-sucedido.
   ```dart
   Navigator.of(context).pushReplacementNamed(AppRoutes.home);
   ```

3. **Reset Completo da Pilha (`pushNamedAndRemoveUntil`)**: Utilizado no Logout ou quando a guarda de rotas intercepta um usuário não autenticado. Garante que o botão "Voltar" não retorne para telas autenticadas.
   ```dart
   Navigator.of(context).pushNamedAndRemoveUntil(
     AppRoutes.login,
     (route) => false,
   );
   ```

---

## 5. Guarda de Rotas (`RotaProtegida`)

### Como Funciona:
1. `RotaProtegida` observa o estado de autenticação reativamente através de `context.watch<SessaoService>()`.
2. Se `sessao.isAuthenticated` for `false` (por exemplo, na inicialização ou após recarregar a página com F5), ela agenda um redirecionamento imediato pós-frame:
   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) {
     if (context.mounted) {
       Navigator.of(context).pushNamedAndRemoveUntil(
         AppRoutes.login,
         (route) => false,
       );
     }
   });
   ```
3. Enquanto o frame é processado e o redirecionamento é despachado, a guarda renderiza um placeholder com indicador de progresso, impedindo qualquer vazamento visual do conteúdo protegido.
4. Se o usuário estiver em uma tela protegida e o logout for disparado (limpando o token em memória), a guarda reage imediatamente e limpa a pilha de navegação.
