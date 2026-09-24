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

## 🔗 Documentação Interativa (Swagger)

Acesse no navegador:
- **Swagger UI:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **Redoc:** [http://localhost:8000/redoc](http://localhost:8000/redoc)
- **Imagens Estáticas:** [http://localhost:8000/imagens/dashboard.jpg](http://localhost:8000/imagens/dashboard.jpg)