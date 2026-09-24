from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session

from database import get_db
from security import get_current_user
from usuarios._model import Usuario
from projetos._repository import ProjetoRepository
from requisitos._model import RequisitoCreate, RequisitoUpdate, RequisitoPublic
from requisitos._repository import RequisitoRepository
from requisitos._service import RequisitoService

router = APIRouter(tags=["Requisitos"])


def get_requisito_service(db: Session = Depends(get_db)) -> RequisitoService:
    repo = RequisitoRepository(db)
    projeto_repo = ProjetoRepository(db)
    return RequisitoService(repo, projeto_repo)


@router.post("/projetos/{projeto_id}/requisitos", response_model=RequisitoPublic, status_code=status.HTTP_201_CREATED)
def criar_requisito(
    projeto_id: int,
    dados: RequisitoCreate,
    current_user: Usuario = Depends(get_current_user),
    service: RequisitoService = Depends(get_requisito_service)
):
    """Cria um novo requisito associado ao projeto especificado (Aplica RN03 se status='Aprovado')."""
    return service.criar_requisito(projeto_id=projeto_id, dados=dados, usuario_id=current_user.id)


@router.get("/projetos/{projeto_id}/requisitos", response_model=list[RequisitoPublic])
def listar_requisitos_do_projeto(
    projeto_id: int,
    status_filtro: str | None = Query(None, alias="status", description="Filtro opcional por status do requisito"),
    current_user: Usuario = Depends(get_current_user),
    service: RequisitoService = Depends(get_requisito_service)
):
    """Lista todos os requisitos de um projeto pertencente ao usuário logado."""
    return service.listar_requisitos_do_projeto(
        projeto_id=projeto_id, usuario_id=current_user.id, status_filter=status_filtro
    )


@router.get("/requisitos/{requisito_id}", response_model=RequisitoPublic)
def obter_requisito(
    requisito_id: int,
    current_user: Usuario = Depends(get_current_user),
    service: RequisitoService = Depends(get_requisito_service)
):
    """Obtém detalhes de um requisito específico."""
    return service.obter_requisito(requisito_id=requisito_id, usuario_id=current_user.id)


@router.put("/requisitos/{requisito_id}", response_model=RequisitoPublic)
def atualizar_requisito(
    requisito_id: int,
    dados: RequisitoUpdate,
    current_user: Usuario = Depends(get_current_user),
    service: RequisitoService = Depends(get_requisito_service)
):
    """Atualiza dados de um requisito (Valida imutabilidade RN02 e aprovação incompleta RN03)."""
    return service.atualizar_requisito(requisito_id=requisito_id, dados=dados, usuario_id=current_user.id)


@router.delete("/requisitos/{requisito_id}", status_code=status.HTTP_204_NO_CONTENT)
def deletar_requisito(
    requisito_id: int,
    current_user: Usuario = Depends(get_current_user),
    service: RequisitoService = Depends(get_requisito_service)
):
    """Deleta um requisito (Valida imutabilidade RN02)."""
    service.deletar_requisito(requisito_id=requisito_id, usuario_id=current_user.id)
    return None
