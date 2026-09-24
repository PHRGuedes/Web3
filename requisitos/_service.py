from requisitos._model import Requisito, RequisitoCreate, RequisitoUpdate
from requisitos._repository import RequisitoRepository
from projetos._repository import ProjetoRepository
from erros import (
    RequisitoNaoEncontradoError,
    ProjetoNaoEncontradoError,
    AcessoNegadoError,
    RequisitoAprovadoNaoPodeSerAlteradoError,
    RequisitoIncompletoError
)


class RequisitoService:
    """Camada de negócio para Requisitos. Implementa RN02 e RN03. NÃO levanta HTTPException e NÃO consulta DB diretamente."""

    def __init__(self, repository: RequisitoRepository, projeto_repository: ProjetoRepository):
        self.repository = repository
        self.projeto_repository = projeto_repository

    def _validar_propriedade_projeto(self, projeto_id: int, usuario_id: int):
        projeto = self.projeto_repository.get_by_id(projeto_id)
        if not projeto:
            raise ProjetoNaoEncontradoError(projeto_id)
        if projeto.usuario_id != usuario_id:
            raise AcessoNegadoError("projeto")
        return projeto

    def _validar_incompletude_para_aprovacao(self, descricao: str | None, prioridade: str | None, tipo: str | None, criterio_aceitacao: str | None):
        """RN03: Bloqueio de Aprovação por Incompletude."""
        campos_faltantes = []
        if not descricao or not descricao.strip():
            campos_faltantes.append("descricao")
        if not prioridade or not prioridade.strip():
            campos_faltantes.append("prioridade")
        if not tipo or not tipo.strip():
            campos_faltantes.append("tipo")
        if not criterio_aceitacao or not criterio_aceitacao.strip():
            campos_faltantes.append("criterio_aceitacao")

        if campos_faltantes:
            raise RequisitoIncompletoError(campos_faltantes)

    def criar_requisito(self, projeto_id: int, dados: RequisitoCreate, usuario_id: int) -> Requisito:
        self._validar_propriedade_projeto(projeto_id, usuario_id)

        # RN03: Se for criado direto como 'Aprovado', valida incompletude
        if dados.status and dados.status.strip().lower() == "aprovado":
            self._validar_incompletude_para_aprovacao(
                dados.descricao, dados.prioridade, dados.tipo, dados.criterio_aceitacao
            )

        novo_requisito = Requisito(
            titulo=dados.titulo,
            descricao=dados.descricao,
            tipo=dados.tipo,
            prioridade=dados.prioridade,
            status=dados.status,
            criterio_aceitacao=dados.criterio_aceitacao,
            projeto_id=projeto_id
        )

        return self.repository.create(novo_requisito)

    def listar_requisitos_do_projeto(self, projeto_id: int, usuario_id: int, status_filter: str | None = None) -> list[Requisito]:
        self._validar_propriedade_projeto(projeto_id, usuario_id)
        return self.repository.get_all_by_projeto(projeto_id=projeto_id, status_filter=status_filter)

    def obter_requisito(self, requisito_id: int, usuario_id: int) -> Requisito:
        requisito = self.repository.get_by_id(requisito_id)
        if not requisito:
            raise RequisitoNaoEncontradoError(requisito_id)

        self._validar_propriedade_projeto(requisito.projeto_id, usuario_id)
        return requisito

    def atualizar_requisito(self, requisito_id: int, dados: RequisitoUpdate, usuario_id: int) -> Requisito:
        requisito = self.obter_requisito(requisito_id, usuario_id)

        # RN02: Imutabilidade de Requisitos Aprovados
        if requisito.status and requisito.status.strip().lower() == "aprovado":
            raise RequisitoAprovadoNaoPodeSerAlteradoError(requisito_id=requisito_id, acao="alterar")

        # Projeção dos novos valores
        novo_status = dados.status if dados.status is not None else requisito.status
        nova_descricao = dados.descricao if dados.descricao is not None else requisito.descricao
        nova_prioridade = dados.prioridade if dados.prioridade is not None else requisito.prioridade
        novo_tipo = dados.tipo if dados.tipo is not None else requisito.tipo
        novo_criterio = dados.criterio_aceitacao if dados.criterio_aceitacao is not None else requisito.criterio_aceitacao

        # RN03: Bloqueio de Aprovação por Incompletude
        if novo_status and novo_status.strip().lower() == "aprovado":
            self._validar_incompletude_para_aprovacao(
                descricao=nova_descricao,
                prioridade=nova_prioridade,
                tipo=novo_tipo,
                criterio_aceitacao=novo_criterio
            )

        dados_dict = dados.model_dump(exclude_unset=True)
        return self.repository.update(requisito, dados_dict)

    def deletar_requisito(self, requisito_id: int, usuario_id: int) -> None:
        requisito = self.obter_requisito(requisito_id, usuario_id)

        # RN02: Imutabilidade de Requisitos Aprovados
        if requisito.status and requisito.status.strip().lower() == "aprovado":
            raise RequisitoAprovadoNaoPodeSerAlteradoError(requisito_id=requisito_id, acao="deletar")

        self.repository.delete(requisito)
