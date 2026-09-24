import os
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from erros import (
    RegraDeNegocioError,
    UsuarioJaExisteError,
    CredenciaisInvalidasError,
    UsuarioNaoEncontradoError,
    AcessoNegadoError,
    ProjetoNomeDuplicadoError,
    ProjetoNaoEncontradoError,
    RequisitoNaoEncontradoError,
    RequisitoAprovadoNaoPodeSerAlteradoError,
    RequisitoIncompletoError,
)
from usuarios._controller import router as usuarios_router
from projetos._controller import router as projetos_router
from requisitos._controller import router as requisitos_router

# Inicialização da Aplicação FastAPI
app = FastAPI(
    title="API de Engenharia de Requisitos",
    description="Sistema para gestão de requisitos com isolamento por entidade, multi-tenant e autenticação JWT.",
    version="1.0.0",
)

# Servindo arquivos estáticos da pasta 'imagens' conforme aviso do frontend
IMAGENS_DIR = os.path.join(os.path.dirname(__file__), "imagens")
if os.path.exists(IMAGENS_DIR):
    app.mount("/imagens", StaticFiles(directory=IMAGENS_DIR), name="imagens")

# Inclusão dos Roteadores das Entidades
app.include_router(usuarios_router)
app.include_router(projetos_router)
app.include_router(requisitos_router)


# ==========================================================
# Exception Handlers Globais (Traduzindo erros.py para HTTP)
# ==========================================================

@app.exception_handler(RequestValidationError)
def validacao_pydantic_handler(request: Request, exc: RequestValidationError):
    detalhes = []
    for err in exc.errors():
        campo = " -> ".join(str(loc) for loc in err.get("loc", []) if loc != "body")
        detalhes.append({
            "campo": campo or "payload",
            "mensagem": err.get("msg", "Valor inválido"),
            "tipo": err.get("type", "validacao"),
        })
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "erro": "VALIDACAO_FALHOU",
            "mensagem": "Falha na validação dos dados de entrada.",
            "detalhes": detalhes,
        },
    )


@app.exception_handler(UsuarioJaExisteError)
def usuario_ja_existe_handler(request: Request, exc: UsuarioJaExisteError):
    return JSONResponse(
        status_code=status.HTTP_409_CONFLICT,
        content={"erro": "CONFLITO", "mensagem": exc.mensagem},
    )


@app.exception_handler(CredenciaisInvalidasError)
def credenciais_invalidas_handler(request: Request, exc: CredenciaisInvalidasError):
    return JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={"erro": "NAO_AUTORIZADO", "mensagem": exc.mensagem},
    )


@app.exception_handler(UsuarioNaoEncontradoError)
def usuario_nao_encontrado_handler(request: Request, exc: UsuarioNaoEncontradoError):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"erro": "NAO_ENCONTRADO", "mensagem": exc.mensagem},
    )


@app.exception_handler(AcessoNegadoError)
def acesso_negado_handler(request: Request, exc: AcessoNegadoError):
    return JSONResponse(
        status_code=status.HTTP_403_FORBIDDEN,
        content={"erro": "ACESSO_NEGADO", "mensagem": exc.mensagem},
    )


@app.exception_handler(ProjetoNomeDuplicadoError)
def projeto_nome_duplicado_handler(request: Request, exc: ProjetoNomeDuplicadoError):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"erro": "RN01_NOME_DUPLICADO", "mensagem": exc.mensagem},
    )


@app.exception_handler(ProjetoNaoEncontradoError)
def projeto_nao_encontrado_handler(request: Request, exc: ProjetoNaoEncontradoError):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"erro": "NAO_ENCONTRADO", "mensagem": exc.mensagem},
    )


@app.exception_handler(RequisitoNaoEncontradoError)
def requisito_nao_encontrado_handler(request: Request, exc: RequisitoNaoEncontradoError):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"erro": "NAO_ENCONTRADO", "mensagem": exc.mensagem},
    )


@app.exception_handler(RequisitoAprovadoNaoPodeSerAlteradoError)
def requisito_aprovado_handler(request: Request, exc: RequisitoAprovadoNaoPodeSerAlteradoError):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"erro": "RN02_IMUTABILIDADE_REQUISITO", "mensagem": exc.mensagem},
    )


@app.exception_handler(RequisitoIncompletoError)
def requisito_incompleto_handler(request: Request, exc: RequisitoIncompletoError):
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"erro": "RN03_REQUISITO_INCOMPLETO", "mensagem": exc.mensagem},
    )


@app.exception_handler(RegraDeNegocioError)
def regra_de_negocio_handler(request: Request, exc: RegraDeNegocioError):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"erro": "REGRA_DE_NEGOCIO", "mensagem": exc.mensagem},
    )


@app.get("/", tags=["Health Check"])
def root():
    return {
        "status": "ok",
        "mensagem": "API de Engenharia de Requisitos operando normalmente.",
        "docs": "/docs",
    }
