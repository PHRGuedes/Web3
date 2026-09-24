from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from database import get_db
from security import get_current_user
from usuarios._model import UsuarioCreate, UsuarioLogin, UsuarioPublic, Token, Usuario
from usuarios._repository import UsuarioRepository
from usuarios._service import UsuarioService

router = APIRouter(prefix="/usuarios", tags=["Usuários"])


def get_usuario_service(db: Session = Depends(get_db)) -> UsuarioService:
    repo = UsuarioRepository(db)
    return UsuarioService(repo)


@router.post("/cadastro", response_model=UsuarioPublic, status_code=status.HTTP_201_CREATED)
def cadastrar_usuario(
    dados: UsuarioCreate,
    service: UsuarioService = Depends(get_usuario_service)
):
    """Rota pública para cadastro de novos usuários."""
    return service.cadastrar_usuario(dados)


@router.post("/login", response_model=Token)
def login(
    dados: UsuarioLogin,
    service: UsuarioService = Depends(get_usuario_service)
):
    """Rota pública para autenticação e obtenção do token JWT."""
    return service.autenticar_usuario(dados)


@router.get("/me", response_model=UsuarioPublic)
def obter_usuario_logado(current_user: Usuario = Depends(get_current_user)):
    """Rota protegida para consultar o perfil do usuário logado."""
    return current_user
