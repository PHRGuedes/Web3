from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session

from database import get_db
from security import get_current_user
from usuarios._model import Usuario
from projetos._model import ProjetoCreate, ProjetoUpdate, ProjetoPublic
from projetos._repository import ProjetoRepository
from projetos._service import ProjetoService

router = APIRouter(prefix="/projetos", tags=["Projetos"])


def get_projeto_service(db: Session = Depends(get_db)) -> ProjetoService:
    repo = ProjetoRepository(db)
    return ProjetoService(repo)


@router.post("/", response_model=ProjetoPublic, status_code=status.HTTP_201_CREATED)
def criar_projeto(
    dados: ProjetoCreate,
    current_user: Usuario = Depends(get_current_user),
    service: ProjetoService = Depends(get_projeto_service)
):
    """Cria um novo projeto vinculado automaticamente ao usuário logado (RN01)."""
    return service.criar_projeto(dados, usuario_id=current_user.id)


@router.get("/", response_model=list[ProjetoPublic])
def listar_projetos(
    nome: str | None = Query(None, description="Filtro para busca por nome do projeto"),
    current_user: Usuario = Depends(get_current_user),
    service: ProjetoService = Depends(get_projeto_service)
):
    """Lista apenas os projetos do usuário logado (Multi-tenant)."""
    return service.listar_projetos(usuario_id=current_user.id, search_nome=nome)


@router.get("/{projeto_id}", response_model=ProjetoPublic)
def obter_projeto(
    projeto_id: int,
    current_user: Usuario = Depends(get_current_user),
    service: ProjetoService = Depends(get_projeto_service)
):
    """Obtém detalhes de um projeto específico pertencente ao usuário logado."""
    return service.obter_projeto(projeto_id=projeto_id, usuario_id=current_user.id)


@router.put("/{projeto_id}", response_model=ProjetoPublic)
def atualizar_projeto(
    projeto_id: int,
    dados: ProjetoUpdate,
    current_user: Usuario = Depends(get_current_user),
    service: ProjetoService = Depends(get_projeto_service)
):
    """Atualiza dados de um projeto existente."""
    return service.atualizar_projeto(projeto_id=projeto_id, dados=dados, usuario_id=current_user.id)


@router.delete("/{projeto_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_projeto(
    projeto_id: int,
    current_user: Usuario = Depends(get_current_user),
    service: ProjetoService = Depends(get_projeto_service)
):
    """Deleta um projeto existente."""
    service.deletar_projeto(projeto_id=projeto_id, usuario_id=current_user.id)
    return None
