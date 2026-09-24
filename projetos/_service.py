from projetos._model import Projeto, ProjetoCreate, ProjetoUpdate
from projetos._repository import ProjetoRepository
from erros import ProjetoNomeDuplicadoError, ProjetoNaoEncontradoError, AcessoNegadoError


class ProjetoService:
    """Camada de negócio para Projetos. NÃO levanta HTTPException e NÃO faz queries diretas no BD."""

    def __init__(self, repository: ProjetoRepository):
        self.repository = repository

    def criar_projeto(self, dados: ProjetoCreate, usuario_id: int) -> Projeto:
        # RN01: Um usuário não pode criar dois projetos com o mesmo nome
        projeto_existente = self.repository.get_by_nome_and_user(dados.nome, usuario_id)
        if projeto_existente:
            raise ProjetoNomeDuplicadoError(dados.nome)

        # Associação automática ao usuário logado
        novo_projeto = Projeto(
            nome=dados.nome,
            descricao=dados.descricao,
            usuario_id=usuario_id
        )

        return self.repository.create(novo_projeto)

    def listar_projetos(self, usuario_id: int, search_nome: str | None = None) -> list[Projeto]:
        # Filtro multi-tenant: retorna apenas os projetos do usuário logado
        return self.repository.get_all_by_user(usuario_id=usuario_id, search_nome=search_nome)

    def obter_projeto(self, projeto_id: int, usuario_id: int) -> Projeto:
        projeto = self.repository.get_by_id(projeto_id)
        if not projeto:
            raise ProjetoNaoEncontradoError(projeto_id)

        # Verificação de multi-tenant
        if projeto.usuario_id != usuario_id:
            raise AcessoNegadoError("projeto")

        return projeto

    def atualizar_projeto(self, projeto_id: int, dados: ProjetoUpdate, usuario_id: int) -> Projeto:
        projeto = self.obter_projeto(projeto_id, usuario_id)

        # Se for atualizar o nome, valida a RN01 para evitar duplicidade
        if dados.nome and dados.nome != projeto.nome:
            existente = self.repository.get_by_nome_and_user(dados.nome, usuario_id)
            if existente:
                raise ProjetoNomeDuplicadoError(dados.nome)

        dados_dict = dados.model_dump(exclude_unset=True)
        return self.repository.update(projeto, dados_dict)

    def deletar_projeto(self, projeto_id: int, usuario_id: int) -> None:
        projeto = self.obter_projeto(projeto_id, usuario_id)
        self.repository.delete(projeto)
