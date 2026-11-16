# ReqFlow - Frontend Flutter (Web & Emulador)

Frontend moderno desenvolvido em **Flutter** para o Sistema de Engenharia de Requisitos (**ReqFlow**), integrado à API FastAPI com autenticação JWT e isolamento em camadas.

---

## 🏛️ Arquitetura e Separação de Camadas (lib/)

O projeto segue rigorosamente o padrão de separação de responsabilidades em camadas desacopladas:

```
frontend/
├── lib/
│   ├── constants/
│   │   └── api_constants.dart     # Resolução dinâmica de host (Web vs Emulador)
│   ├── models/                    # Camada 1: Dados puros (sem lógica de negócio)
│   │   ├── usuario.dart           # Model de usuário (fromJson / toJson)
│   │   ├── auth_token.dart        # Model de token JWT (fromJson / toJson)
│   │   ├── login_request.dart     # DTO de login
│   │   └── cadastro_request.dart  # DTO de cadastro
│   ├── repositories/              # Camada 2: ÚNICA autorizada a realizar chamadas HTTP
│   │   └── auth_repository.dart   # Implementa IAuthRepository com client http
│   ├── services/                  # Camada 3: Regra de negócio e orquestração de tokens
│   │   └── auth_service.dart      # Gerencia sessão, valida dados e persiste token JWT
│   ├── screens/                   # Camada 4: UI (Widgets fundamentais: Scaffold, Column, Row, Container)
│   │   ├── login_screen.dart      # Tela de login fiel ao protótipo
│   │   ├── cadastro_screen.dart   # Tela de cadastro de novos usuários
│   │   └── home_screen.dart       # Dashboard com chamada GET /usuarios/eu
│   └── main.dart                  # Ponto de entrada e Injeção de Dependências
├── test/                          # Testes unitários com Mocks (Mocktail)
│   ├── models/
│   │   └── models_test.dart       # Testes de serialização dos models
│   ├── services/
│   │   └── auth_service_test.dart # Testes de unidade do AuthService com MockAuthRepository
│   └── screens/
│       └── login_screen_test.dart # Testes de widgets (Scaffold, Column, Row, Container e erros)
└── pubspec.yaml                   # Dependências do Flutter
```

### Regras Arquiteturais Estritas
1. **`models/`**: Classes de dados puros com métodos `fromJson` e `toJson`. Não contém lógica de rede nem estado.
2. **`repositories/`**: A **única** camada autorizada a fazer chamadas HTTP (usando o pacote `http`). Trata códigos de status e exceptions de rede.
3. **`services/`**: Camada de negócio. Valida entradas, chama o repositório, armazena e recupera o token JWT localmente e fornece dados prontos para a tela.
4. **`screens/`**: A camada de UI. Desenha a interface, captura eventos e chama o `AuthService`. **A tela NUNCA faz HTTP diretamente**. Utiliza explicitamente os widgets estruturais `Scaffold`, `Column`, `Row` e `Container`.
5. **`main.dart`**: Monta o grafo de injeção de dependências (`AuthRepository` -> `AuthService` -> `ReqFlowApp`).

---

## 🌐 Configuração de Rede (Web vs Emulador)

O arquivo [api_constants.dart](lib/constants/api_constants.dart) detecta automaticamente a plataforma de execução:
- **Navegador Web / Desktop:** Comunica-se com `http://localhost:8000`.
- **Emulador Android:** Comunica-se com `http://10.0.2.2:8000` (endereço de loopback especial do emulador que acessa o `localhost` do seu computador).

Para apontar para uma URL customizada em tempo de execução ou compilar para produção (Vercel / Netlify / Firebase):
```bash
# Execução no navegador apontando para a API no ar
flutter run -d chrome --dart-define=API_URL=https://reqflow-api.onrender.com

# Build estático de produção para deploy em nuvem (Vercel/Netlify)
flutter build web --dart-define=API_URL=https://reqflow-api.onrender.com
```

---

## 🚀 Como Executar o Aplicativo

### 1. Pré-requisitos
- Flutter SDK instalado (versão `>=3.0.0`).
- Google Chrome (para Web) ou Android Studio / Emulador configurado (para Mobile).
- API Backend (FastAPI) em execução na porta 8000 (ver raiz do projeto).

### 2. Instalar Dependências
Navegue até a pasta `frontend` e execute:
```bash
cd frontend
flutter pub get
```

---

### 3. Executar no Navegador Web (Chrome)
Para rodar no Chrome com suporte a CORS:
```bash
flutter run -d chrome
```
Ou com porta fixa (ex: 3000):
```bash
flutter run -d chrome --web-port=3000
```

---

### 4. Executar no Emulador Android
1. Inicie seu emulador Android (via Android Studio ou comando `emulator -avd <nome>`).
2. Liste os dispositivos disponíveis:
   ```bash
   flutter devices
   ```
3. Execute o aplicativo apontando para o emulador:
   ```bash
   flutter run -d android
   ```
*(O aplicativo conectará automaticamente no host via `http://10.0.2.2:8000`)*.

---

## 🧪 Como Executar os Testes Unitários e de Widgets

Os testes foram construídos utilizando o pacote **`mocktail`**, permitindo simular respostas de sucesso e erro do repositório HTTP sem precisar que a API backend esteja ligada:

### Executar toda a suíte de testes:
```bash
flutter test
```

### Executar arquivo de teste específico:
```bash
# Testes dos Models (fromJson e toJson)
flutter test test/models/models_test.dart
flutter test test/models/projeto_test.dart

# Testes de unidade dos Services (Mocks dos Repositories)
flutter test test/services/auth_service_test.dart
flutter test test/services/projeto_service_test.dart

# Testes de unidade dos Repositories (Mocks http.Client)
flutter test test/repositories/local_storage_repository_test.dart
flutter test test/repositories/projeto_repository_test.dart

# Testes de telas e widgets (Formulário, Diálogos, 4 Estados e Rotas)
flutter test test/screens/login_screen_test.dart
flutter test test/screens/projetos_screen_test.dart
flutter test test/screens/projeto_detalhes_screen_test.dart
flutter test test/screens/projeto_form_screen_test.dart
flutter test test/routes/rota_protegida_test.dart
```

### Testes de Backend (FastAPI / Pytest com TestClient):
Para executar os testes automatizados da API backend (a partir da raiz do projeto):
```bash
poetry run pytest -v
```

---

## 📋 Checklist das Seis Funcionalidades Mínimas

| # | Funcionalidade Mínima | Onde Está no Código | Como Provar (Manual e Automatizado) |
|---|-----------------------|---------------------|--------------------------------------|
| **1** | **Autenticação JWT, Persistência e Rotas Protegidas** | • [sessao_service.dart](lib/services/sessao_service.dart)<br>• [local_storage_repository.dart](lib/repositories/local_storage_repository.dart)<br>• [routes.dart](lib/routes.dart) (`RotaProtegida`)<br>• [main.dart](lib/main.dart) | **Manual:** Fazer login ou cadastro (com auto-login) e dar F5 no navegador: a sessão permanece ativa via `SharedPreferences`. Acessar rotas internas sem token redireciona para `/login`.<br>**Automatizado:** `flutter test test/routes/rota_protegida_test.dart` e `flutter test test/services/sessao_service_test.dart`. |
| **2** | **Listagem com 4 Estados (FutureBuilder e ListView.builder)** | • [projetos_screen.dart](lib/screens/projetos_screen.dart)<br>• [projeto_service.dart](lib/services/projeto_service.dart)<br>• [projeto_repository.dart](lib/repositories/projeto_repository.dart) | **Manual:** Abre a listagem exibindo loading (`CircularProgressIndicator`), cards reais em `ListView.builder`, erro com botão "Tentar de novo" se a API estiver fora, ou tela de lista vazia.<br>**Automatizado:** `flutter test test/screens/projetos_screen_test.dart`. |
| **3** | **Busca/Filtro via API (`?nome=`) com Feedback na Lista Vazia** | • [projetos_screen.dart](lib/screens/projetos_screen.dart)<br>• [projeto_service.dart](lib/services/projeto_service.dart)<br>• [projeto_repository.dart](lib/repositories/projeto_repository.dart) | **Manual:** Digitar no campo de busca: requisição vai para `GET /projetos/?nome=termo`. Se não houver itens, a tela vazia exibe: *"Nenhum resultado corresponde à busca por '[termo]'."* com botão "Limpar busca".<br>**Automatizado:** `flutter test test/screens/projetos_screen_test.dart` e `flutter test test/repositories/projeto_repository_test.dart`. |
| **4** | **Formulário Unificado com `Form`, `TextFormField` e Validação (`validator`)** | • [projeto_form_screen.dart](lib/screens/projeto_form_screen.dart)<br>• [routes.dart](lib/routes.dart) (`/projetos/form`) | **Manual:** Botão "+" abre tela limpa como "Novo Projeto". Salvar vazio dispara `validator` impedindo envio. Clicar em "Editar" no card abre a mesma tela como "Editar Projeto" com dados pré-carregados.<br>**Automatizado:** `flutter test test/screens/projeto_form_screen_test.dart`. |
| **5** | **Recusa da API (422, 409) com Frase na Tela, Formulário Aberto e Feedbacks** | • [projeto_form_screen.dart](lib/screens/projeto_form_screen.dart)<br>• [projeto_repository.dart](lib/repositories/projeto_repository.dart) (`_processResponse`) | **Manual:** Salvar com nome duplicado: API retorna 409 Conflito. O formulário **continua aberto**, exibe banner com a frase da API e dispara SnackBar de erro. Erro 422 de validação também exibe a frase da API.<br>**Automatizado:** `flutter test test/screens/projeto_form_screen_test.dart` e `flutter test test/repositories/projeto_repository_test.dart`. |
| **6** | **Exclusão (DELETE) com Confirmação (`showDialog`) e Atualização Reativa da Lista** | • [projetos_screen.dart](lib/screens/projetos_screen.dart)<br>• [projeto_detalhes_screen.dart](lib/screens/projeto_detalhes_screen.dart)<br>• [projeto_service.dart](lib/services/projeto_service.dart)<br>• [projeto_repository.dart](lib/repositories/projeto_repository.dart) | **Manual:** Clicar na lixeira abre `AlertDialog` via `showDialog`. "Cancelar" aborta; "Excluir" chama `DELETE`, exibe SnackBar de sucesso e a lista recarrega. Salvar no formulário fecha com `pop(context, true)` e a lista também recarrega.<br>**Automatizado:** `flutter test test/screens/projetos_screen_test.dart` e `flutter test test/screens/projeto_detalhes_screen_test.dart`. |

---

## 🔒 Fluxo de Autenticação e Erros

1. **Login:** A tela de login captura e-mail e senha e envia para `authService.login(email, senha)`.
2. **Tratamento de Credenciais Inválidas:** Caso a API retorne erro (401, 404, 422), o aplicativo **permanece na tela de login**, exibe um banner com mensagem de erro clara em vermelho e um `SnackBar` informativo.
3. **Navegação com Sucesso:** O token JWT retornado é persistido no `AuthService` e o app navega para a `HomeScreen`.
4. **Carga Obrigatória `GET /usuarios/eu`:** Na inicialização da `HomeScreen`, o app dispara `authService.obterUsuarioAtual()`, enviando o cabeçalho `Authorization: Bearer <token>` para obter os dados do usuário conectado.
