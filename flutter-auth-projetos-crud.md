# Plano de Evolução: Persistência, Auto-Login e Leitura de Projetos no Flutter

## Objetivo
Evoluir o frontend Flutter ([frontend/lib](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib)) com persistência de token JWT via `shared_preferences`, inicialização silenciosa, cadastro com auto-login, tratamento de expiração 401 e CRUD de leitura da entidade `Projeto` (listagem com 4 estados em `FutureBuilder` e tela de detalhes via rota nomeada com `projetoId` por argumento).

---

## Arquitetura e Decisões Técnicas (Opção C)
1. **`models/`**:
   - `Projeto` ([frontend/lib/models/projeto.dart](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib/models/projeto.dart)) com serialização JSON e mapeamento de campos (`id`, `nome`, `descricao`, `usuario_id`, `created_at`).
2. **`repositories/`**:
   - `LocalStorageRepository` ([frontend/lib/repositories/local_storage_repository.dart](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib/repositories/local_storage_repository.dart)) abstraindo `shared_preferences` com interface `ILocalStorageRepository`.
   - `ProjetoRepository` ([frontend/lib/repositories/projeto_repository.dart](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib/repositories/projeto_repository.dart)) implementando `GET /projetos` e `GET /projetos/{id}` com `Authorization: Bearer <token>`, lançando `ApiException`.
3. **`services/`**:
   - `SessaoService` ([frontend/lib/services/sessao_service.dart](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib/services/sessao_service.dart)): orquestra token na memória e no storage, cadastro com auto-login e logout unificado com notificação de ouvintes.
   - `ProjetoService` ([frontend/lib/services/projeto_service.dart](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib/services/projeto_service.dart)): consome `IProjetoRepository` usando o token da sessão; captura 401 e aciona logout na sessão.
4. **`screens/` & `routes/`**:
   - [main.dart](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib/main.dart): inicialização assíncrona do storage, `MultiProvider` e rota inicial dinâmica (`/home` se houver token, `/login` se vazio).
   - [routes.dart](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib/routes.dart): adiciona rota protegida `/projetos/detalhes`.
   - [cadastro_screen.dart](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib/screens/cadastro_screen.dart): cadastro com auto-login e fallback para login se a rede falhar após criar a conta.
   - [projetos_screen.dart](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib/screens/projetos_screen.dart): `FutureBuilder` com 4 estados (Loading, Erro com retry, Vazio, Preenchido com `ListView.builder`) e clique navegando para detalhes com `projetoId`.
   - `projeto_detalhes_screen.dart` ([frontend/lib/screens/projeto_detalhes_screen.dart](file:///c:/Users/ypedr/OneDrive/Desktop/Web3/frontend/lib/screens/projeto_detalhes_screen.dart)): recebe `projetoId` por argumento, consome `GET /projetos/{id}` via `FutureBuilder` com retry e layout rico.

---

## Tarefas de Implementação

- [x] Tarefa 1: Criar modelo `Projeto` em `frontend/lib/models/projeto.dart` → Concluído: campos tipados e `fromJson`/`toJson`
- [x] Tarefa 2: Criar repositório `LocalStorageRepository` em `frontend/lib/repositories/local_storage_repository.dart` → Concluído: persistência via `shared_preferences`
- [x] Tarefa 3: Criar repositório `ProjetoRepository` em `frontend/lib/repositories/projeto_repository.dart` → Concluído: chamadas autenticadas a `GET /projetos` e `GET /projetos/{id}`
- [x] Tarefa 4: Atualizar `SessaoService` em `frontend/lib/services/sessao_service.dart` para persistência, auto-login no cadastro e tratamento de 401 → Concluído: persistência no storage e deslogue reativo
- [x] Tarefa 5: Criar serviço `ProjetoService` em `frontend/lib/services/projeto_service.dart` → Concluído: integração com repositório e repasse seguro de exceções
- [x] Tarefa 6: Configurar injeção no `main.dart` e registrar rotas em `routes.dart` → Concluído: `initialRoute` condicional e `MultiProvider`
- [x] Tarefa 7: Atualizar `cadastro_screen.dart` para fluxo de auto-login e redirecionamento para Home → Concluído: formulário cadastra, loga e transiciona
- [x] Tarefa 8: Atualizar `projetos_screen.dart` com `FutureBuilder`, `ListView.builder` e os 4 estados visuais → Concluído: Loading, Erro c/ Retry, Vazio e Cards reais
- [x] Tarefa 9: Criar tela `projeto_detalhes_screen.dart` consumindo `projetoId` via argumentos da rota → Concluído: navegação via rota nomeada com `projetoId`
- [x] Tarefa 10: Criar e atualizar testes automatizados para todos os componentes criados e alterados → Concluído: testes de unit/widget em models, repositories, services, screens e rotas

---

## Critérios de Sucesso
- [x] Separação estrita em `models/`, `repositories/`, `services/`, `screens/` respeitada (telas sem HTTP, JSON ou status codes).
- [x] Token JWT salvo no `SharedPreferences` e restaurado no boot do app (inicialização silenciosa).
- [x] Auto-login executado no cadastro com redirecionamento para Home.
- [x] Rota protegida atuando em caso de 401 redirecionando para a tela de login.
- [x] Interface híbrida de projetos utilizando `FutureBuilder` e `ListView.builder` tratando os 4 estados.
- [x] Rota nomeada `/projetos/detalhes` recebendo `projetoId` via argumentos.
