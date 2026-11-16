# Sistema de Engenharia de Requisitos

Sistema completo para Engenharia de Requisitos desenvolvido com **FastAPI**, **SQLAlchemy**, **Alembic**, **PostgreSQL** e **Poetry**.

---

## 🛠️ Tech Stack & Arquitetura

- **Gerenciador de Pacotes:** Poetry
- **Framework Web:** FastAPI
- **Banco de Dados:** PostgreSQL (Docker Compose fornecido)
- **ORM & Migrations:** SQLAlchemy 2.0 & Alembic
- **Validação:** Pydantic v2
- **Autenticação:** JWT (JSON Web Tokens) e Passlib/Bcrypt

---

## 🌐 Endereços do Sistema no Ar (Produção & Local)

| Componente | Ambiente de Nuvem (No Ar) | Ambiente Local | Descrição |
| :--- | :--- | :--- | :--- |
| **Frontend (ReqFlow Web)** | `https://reqflow-web.vercel.app` | `http://localhost:3000` | Interface em Flutter Web com persistência de sessão e rotas protegidas |
| **API Backend (FastAPI)** | `https://reqflow-api.onrender.com` | `http://localhost:8000` | API RESTful rodando em contêiner Docker a partir do `Dockerfile` |
| **Swagger UI (Docs)** | `https://reqflow-api.onrender.com/docs` | `http://localhost:8000/docs` | Documentação interativa OpenAPI dos endpoints |
| **Banco de Dados (PostgreSQL)** | `postgresql://...@ep-reqflow.neon.tech/requisitos_db` | `localhost:5433/requisitos_db` | Banco relacional PostgreSQL com migrações Alembic |

---

## 🐳 Dockerfile e Deploy em Nuvem (CI/CD Automático)

A API possui um [Dockerfile](Dockerfile) de produção otimizado com base `python:3.11-slim`, executado por usuário não-root (`appuser`), com as seguintes garantias:

1. **Construção Automática pelo Serviço de Nuvem:**
   - Provedores como **Render**, **Railway**, **Fly.io** ou **Google Cloud Run** constroem a imagem automaticamente a partir do [Dockerfile](Dockerfile) a cada commit na branch `main`.
   - O contêiner executa automaticamente as migrações do banco (`alembic upgrade head`) e sobe o servidor `uvicorn` escutando na porta dinâmica `${PORT:-8000}`.

2. **Configuração Exclusiva por Variáveis de Ambiente (Zero Segredos no Git e na Imagem):**
   - O arquivo [.dockerignore](.dockerignore) bloqueia estritamente `.env`, `.git`, caches e arquivos confidenciais.
   - O arquivo [.gitignore](.gitignore) impede o envio de `.env` para o repositório.
   - O modelo de variáveis exigidas está documentado em [.env.example](.env.example).

### Variáveis de Ambiente para Configurar no Painel da Nuvem:

| Variável | Exemplo de Valor em Nuvem | Finalidade |
| :--- | :--- | :--- |
| `DATABASE_URL` | `postgresql://user:pass@ep-reqflow.neon.tech/requisitos_db` | Conexão com o banco PostgreSQL gerenciado |
| `SECRET_KEY` | `9b8c7d6e5f4a3b2c1d0e...` (64+ caracteres aleatórios) | Chave de assinatura criptográfica dos tokens JWT |
| `ALGORITHM` | `HS256` | Algoritmo de hash para os tokens JWT |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `60` | Tempo de validade do token de autenticação |
| `PORT` | `8000` *(definido automaticamente pelo provedor de nuvem)* | Porta interna exposta pelo contêiner |

### Executar a API e o Banco Localmente via Docker Compose:
```bash
docker compose up -d --build
```
Isso inicializará tanto o banco PostgreSQL quanto o contêiner da API construído a partir do `Dockerfile`, aplicando as migrações automaticamente.

---

## 📂 Arquitetura por Entidades (Corte Rigoroso)

Cada entidade está isolada em sua própria pasta e separada em exatamente 4 arquivos:

```
├── usuarios/
│   ├── _model.py        # SQLAlchemy Model & Pydantic Schemas (Senha omitida no Public)
│   ├── _repository.py   # ÚNICA camada com db.query
│   ├── _service.py      # Lógica de Negócio (exceções customizadas, sem db.query)
│   └── _controller.py   # APIRouter & Injeção de Dependências
├── projetos/
│   ├── _model.py        # Relacionamento 1:N com Usuario e Requisitos
│   ├── _repository.py   # Operações de BD & Filtro por nome
│   ├── _service.py      # Lógica (RN01 - Nome Único por Usuário)
│   └── _controller.py   # Endpoints Protegidos por JWT
└── requisitos/
    ├── _model.py        # Requisito (Status, Prioridade, Tipo, Critérios)
    ├── _repository.py   # Operações de BD de Requisitos
    ├── _service.py      # Lógica (RN02 - Imutabilidade & RN03 - Aprovação Completa)
    └── _controller.py   # Endpoints de CRUD de Requisitos
```

### Arquivos Globais
- `database.py`: Conexão SQLAlchemy, SessionLocal e dependência `get_db`.
- `erros.py`: Classes de exceção customizadas de negócio.
- `security.py`: Hashing de senha (bcrypt), geração/validação JWT e dependência `get_current_user`.
- `main.py`: Instância do FastAPI, montagem da pasta de arquivos estáticos `imagens`, inclusão dos roteadores e Exception Handlers globais.

---

## 📜 Regras de Negócio Implementadas

1. **RN01 - Nome de Projeto Único por Usuário (`ProjetoService`):**
   - Um usuário não pode criar dois projetos com o mesmo nome.

2. **RN02 - Imutabilidade de Requisitos Aprovados (`RequisitoService`):**
   - É vedada qualquer alteração ou exclusão de um requisito com status `"Aprovado"`. Dispara `RequisitoAprovadoNaoPodeSerAlteradoError` (HTTP 400).

3. **RN03 - Bloqueio de Aprovação por Incompletude (`RequisitoService`):**
   - Um requisito não pode ser transicionado para `"Aprovado"` se campos obrigatórios (`descricao`, `prioridade`, `tipo`, `criterio_aceitacao`) estiverem nulos ou em branco. Dispara `RequisitoIncompletoError` (HTTP 422).

---

## 🚀 Como Executar o Projeto

### 1. Iniciar o Banco de Dados (PostgreSQL via Docker)
```bash
docker compose up -d
```

### 2. Instalar Dependências (Poetry)
```bash
poetry install
```

### 3. Rodar as Migrações do Banco (Alembic)
```bash
poetry run alembic upgrade head
```
> **Histórico de Migrações:**
> - `001_initial_schema`: Criação das tabelas base.
> - `002_add_relacionamento`: Adição da coluna `usuario_id` e chave estrangeira (`1:N` entre Usuario e Projeto), comprovando a evolução por migração sem `create_all`.

### 4. Iniciar o Servidor de Desenvolvimento
```bash
poetry run uvicorn main:app --reload
```

---

## 🧪 Como Executar os Testes Automatizados

### 1. Testes de Backend (FastAPI / Pytest com TestClient)
O projeto conta com suíte de testes de endpoints utilizando `pytest` e `TestClient`, cobrindo o caminho crítico com banco SQLite isolado em memória:
```bash
poetry run pytest -v
```
> **Caminho Crítico Testado (`tests/test_projetos_endpoints.py`):**
> - Autenticação e geração de token JWT
> - Criação de Projeto (`POST /projetos/`) com status 201 Created
> - Bloqueio de duplicidade de nome por usuário (RN01) com status 409 Conflict
> - Validação de schema com status 422 Unprocessable Entity
> - Busca por parâmetro de consulta (`GET /projetos/?nome=...`)
> - Atualização parcial (`PATCH /projetos/{id}`)
> - Exclusão (`DELETE /projetos/{id}`) com status 204 No Content e verificação 404

### 2. Testes de Frontend (Flutter / Widget Tests e Unit Tests com Mocks)
No diretório `frontend/`:
```bash
cd frontend
flutter test
```

Para rodar arquivos de teste de widget ou unidade específicos:
```bash
# Teste de widget do Formulário Único (Form, TextFormField, validator, 409/422 mantendo formulário aberto)
flutter test test/screens/projeto_form_screen_test.dart

# Teste de widget da Listagem (4 estados, busca/filtro via API e diálogo showDialog)
flutter test test/screens/projetos_screen_test.dart

# Teste de widget dos Detalhes (layout rico, botões de ação e diálogo de exclusão)
flutter test test/screens/projeto_detalhes_screen_test.dart

# Testes de repositório e serviços mockados
flutter test test/repositories/projeto_repository_test.dart
flutter test test/services/projeto_service_test.dart
```

---

## 🔗 Documentação Interativa (Swagger)

Acesse no navegador:
- **Swagger UI:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **Redoc:** [http://localhost:8000/redoc](http://localhost:8000/redoc)
- **Imagens Estáticas:** [http://localhost:8000/imagens/dashboard.jpg](http://localhost:8000/imagens/dashboard.jpg)

---

## 📱 Frontend Flutter (ReqFlow)

O frontend cliente do sistema está localizado na pasta `frontend/`, desenvolvido em **Flutter** para Web e Emulador/Dispositivo móvel com arquitetura em camadas (`models`, `repositories`, `services`, `screens`).

Para executar o frontend e rodar os testes unitários mockados, consulte as instruções em:
👉 [frontend/README.md](frontend/README.md)

---

## 📋 Checklist das Seis Funcionalidades Mínimas

| # | Funcionalidade Mínima | Onde Está no Código | Como Provar (Manual e Automatizado) |
|---|-----------------------|---------------------|--------------------------------------|
| **1** | **Autenticação JWT, Persistência e Rotas Protegidas** | • Backend: `security.py`, `usuarios/`<br>• Frontend: [sessao_service.dart](frontend/lib/services/sessao_service.dart), [local_storage_repository.dart](frontend/lib/repositories/local_storage_repository.dart), [routes.dart](frontend/lib/routes.dart) (`RotaProtegida`), [main.dart](frontend/lib/main.dart) | **Manual:** Fazer login ou cadastro (com auto-login) e atualizar a página (F5): a sessão permanece salva via `SharedPreferences`. Tentar acessar rotas internas (`/home`, `/projetos`, `/projetos/form`) sem token redireciona imediatamente para `/login`.<br>**Automatizado:** `flutter test test/routes/rota_protegida_test.dart` e `flutter test test/services/sessao_service_test.dart`. |
| **2** | **Listagem de Projetos com 4 Estados (FutureBuilder e ListView.builder)** | • Backend: `projetos/_controller.py` (`GET /projetos/`)<br>• Frontend: [projetos_screen.dart](frontend/lib/screens/projetos_screen.dart), [projeto_service.dart](frontend/lib/services/projeto_service.dart), [projeto_repository.dart](frontend/lib/repositories/projeto_repository.dart) | **Manual:** Ao abrir a tela de projetos com a API conectada, exibe o loading (`CircularProgressIndicator`), seguido pelos cards reais em `ListView.builder`. Se desligar o backend, exibe estado de erro amigável com botão "Tentar de novo". Se não houver projetos, exibe tela de lista vazia.<br>**Automatizado:** `flutter test test/screens/projetos_screen_test.dart`. |
| **3** | **Busca/Filtro via API (`?nome=`) com Feedback na Lista Vazia** | • Backend: `projetos/_repository.py` (filtro `ilike`), `projetos/_controller.py` (`Query ?nome=`)<br>• Frontend: [projetos_screen.dart](frontend/lib/screens/projetos_screen.dart), [projeto_service.dart](frontend/lib/services/projeto_service.dart), [projeto_repository.dart](frontend/lib/repositories/projeto_repository.dart) | **Manual:** Digitar um nome no campo de busca no topo da lista: a requisição HTTP dispara para `GET /projetos/?nome=termo` (quem filtra é a API). Ao buscar um termo inexistente, a lista vazia informa exatamente o que foi procurado: *"Nenhum resultado corresponde à busca por '[termo]'."* e oferece o botão "Limpar busca".<br>**Automatizado:** `flutter test test/screens/projetos_screen_test.dart` (cenário de filtro e lista vazia com termo) e `flutter test test/repositories/projeto_repository_test.dart`. |
| **4** | **Formulário Unificado com `Form`, `TextFormField` e Validação (`validator`)** | • Frontend: [projeto_form_screen.dart](frontend/lib/screens/projeto_form_screen.dart), [routes.dart](frontend/lib/routes.dart) (`/projetos/form`), [main.dart](frontend/lib/main.dart) | **Manual:** Clicar no botão "+" ("Novo Projeto"): tela abre limpa com título "Novo Projeto". Clicar em salvar com campos em branco ou nome com 1 caractere: o `validator` bloqueia a submissão e exibe o alerta em vermelho sob o campo. Clicar no ícone de lápis em um card: a mesma tela abre com título "Editar Projeto" e campos pré-preenchidos.<br>**Automatizado:** `flutter test test/screens/projeto_form_screen_test.dart`. |
| **5** | **Recusa da API (422, 409) Mostrada na Tela com Formulário Aberto e Feedbacks Visuais** | • Backend: `main.py` (handlers de 409 e 422), `projetos/_service.py` (`RN01`)<br>• Frontend: [projeto_form_screen.dart](frontend/lib/screens/projeto_form_screen.dart), [projeto_repository.dart](frontend/lib/repositories/projeto_repository.dart) (`_processResponse`) | **Manual:** Tentar salvar um projeto com nome já existente na conta do usuário: a API recusa com HTTP 409 Conflito. O formulário **permanece aberto**, os campos não são apagados, um banner vermelho exibe a frase da API (*"Já existe um projeto cadastrado com o nome..."*) e um SnackBar vermelho de erro é disparado. No caso de validação falha no servidor (422), a mensagem de validação é exibida na tela da mesma forma.<br>**Automatizado:** `flutter test test/screens/projeto_form_screen_test.dart` e `flutter test test/repositories/projeto_repository_test.dart`. |
| **6** | **Exclusão (DELETE) com Confirmação (`showDialog`) e Atualização Reativa da Lista** | • Backend: `projetos/_controller.py` (`DELETE /projetos/{id}`)<br>• Frontend: [projetos_screen.dart](frontend/lib/screens/projetos_screen.dart), [projeto_detalhes_screen.dart](frontend/lib/screens/projeto_detalhes_screen.dart), [projeto_service.dart](frontend/lib/services/projeto_service.dart), [projeto_repository.dart](frontend/lib/repositories/projeto_repository.dart) (`DELETE /projetos/{id}`) | **Manual:** Clicar na lixeira de um card: abre o diálogo modal `AlertDialog` via `showDialog`. Clicar em "Cancelar": o diálogo fecha e o item permanece. Clicar em "Excluir": executa `DELETE` na API, exibe SnackBar verde de sucesso e a lista recarrega imediatamente. Ao criar ou editar no formulário, a tela fecha com `Navigator.pop(context, true)` e a lista também recarrega automaticamente.<br>**Automatizado:** `flutter test test/screens/projetos_screen_test.dart` e `flutter test test/screens/projeto_detalhes_screen_test.dart`. |
