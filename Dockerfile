# ==============================================================================
# Dockerfile de Produção para API FastAPI (ReqFlow)
# ==============================================================================
# SEGURANÇA E BOAS PRÁTICAS:
# 1. Base slim oficial com Python 3.11.
# 2. Nenhum segredo ou credencial fixada no Dockerfile (configuração 100% via env vars).
# 3. .dockerignore impede a inclusão de .env, chaves e artefatos locais.
# 4. Execução como usuário não-root (appuser).
# 5. Compatível com provedores de nuvem (Render, Railway, Fly.io, Cloud Run, AWS).
# ==============================================================================

FROM python:3.11-slim as base

# Variáveis de ambiente para comportamento padrão do Python e Poetry
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    POETRY_VERSION=1.8.3 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_NO_INTERACTION=1

# Instala dependências do sistema necessárias para compilação e PostgreSQL
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Instala o gerenciador Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="$POETRY_HOME/bin:$PATH"

# Define diretório de trabalho
WORKDIR /app

# Copia os arquivos de manifesto de dependências primeiro (otimização de cache do Docker)
COPY pyproject.toml poetry.lock* ./

# Instala somente as dependências de produção (exclui o grupo de dev)
RUN poetry install --without dev --no-root

# Copia o código da aplicação e arquivos de migração do banco
COPY alembic.ini ./
COPY alembic ./alembic
COPY database.py erros.py security.py main.py ./
COPY usuarios ./usuarios
COPY projetos ./projetos
COPY requisitos ./requisitos
COPY imagens ./imagens

# Cria usuário sem privilégios de root para segurança
RUN adduser --disabled-password --gecos "" appuser && \
    chown -R appuser:appuser /app

USER appuser

# Porta exposta (padrão 8000, adaptável dinamicamente em nuvem via $PORT)
EXPOSE 8000

# Executa migrações pendentes no banco e inicia o servidor FastAPI
# A variável ${PORT:-8000} permite compatibilidade automática com Render/Railway/Fly.io
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
