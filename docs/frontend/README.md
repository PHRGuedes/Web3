# Documentação da Arquitetura Frontend (ReqFlow)

Esta pasta contém a documentação técnica completa da evolução do frontend em Flutter do **ReqFlow** (Sistema de Engenharia de Requisitos), abordando navegação com rotas nomeadas, gerência de estado reativa com `Provider`, guarda de rotas e suíte de testes.

---

## 📑 Índice da Documentação

1. **[Rotas e Navegação Protegida](rotas_e_navegacao.md)**
   - Constantes centralizadas em `AppRoutes` (`lib/routes.dart`).
   - Mapeamento declarativo via `routes:` no `main.dart`.
   - Transições estritas com `Navigator`.
   - Mecanismo do Guarda de Rotas (`RotaProtegida`).

2. **[Gerência de Estado com Provider](gerencia_de_estado.md)**
   - Arquitetura do `SessaoService` herdando de `ChangeNotifier`.
   - Injeção global no topo absoluto (`ChangeNotifierProvider`).
   - Proibição de injeção por construtor e uso de `context.read` / `context.watch`.
   - Volatilidade estrita do token JWT em memória (sem persistência em disco).

3. **[Componentes de Interface e Telas](componentes_e_telas.md)**
   - Menu Lateral Compartilhado (`AppDrawer`) com dados do usuário e ação de Logout.
   - Tela de Perfil (`PerfilScreen`) reativa.
   - Tela de Projetos (`ProjetosScreen`) como área reservada.
   - Atualizações em `LoginScreen` e `HomeScreen`.

4. **[Guia e Relatório de Testes](guia_de_testes.md)**
   - Cobertura de testes unitários e de widget (`flutter test`).
   - Casos de teste obrigatórios (bloqueio de rotas, drawer, logout, `notifyListeners`).
   - Resultados de análise estática (`flutter analyze`) e auditoria móvel.

---

## 🚀 Resumo Rápido de Execução

### Executar a Aplicação
```bash
cd frontend
flutter run
```

### Executar a Suíte Completa de Testes
```bash
cd frontend
flutter test
```

### Análise Estática de Código
```bash
cd frontend
flutter analyze
```
