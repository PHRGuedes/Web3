class RegraDeNegocioError(Exception):
    """Exceção base para todas as violações de regras de negócio do sistema."""
    def __init__(self, mensagem: str):
        self.mensagem = mensagem
        super().__init__(self.mensagem)


# Exceções de Usuários / Autenticação
class UsuarioJaExisteError(RegraDeNegocioError):
    def __init__(self, email: str):
        super().__init__(f"Já existe um usuário cadastrado com o e-mail '{email}'.")


class CredenciaisInvalidasError(RegraDeNegocioError):
    def __init__(self):
        super().__init__("E-mail ou senha incorretos.")


class UsuarioNaoEncontradoError(RegraDeNegocioError):
    def __init__(self, identifier: str = ""):
        msg = f"Usuário '{identifier}' não foi encontrado." if identifier else "Usuário não encontrado."
        super().__init__(msg)


# Exceções de Permissão
class AcessoNegadoError(RegraDeNegocioError):
    def __init__(self, recurso: str = "recurso"):
        super().__init__(f"Você não tem permissão para acessar ou modificar este {recurso}.")


# Exceções de Projetos (RN01)
class ProjetoNomeDuplicadoError(RegraDeNegocioError):
    """RN01: Um usuário não pode criar dois projetos com o mesmo nome."""
    def __init__(self, nome: str):
        super().__init__(f"RN01: Você já possui um projeto cadastrado com o nome '{nome}'.")


class ProjetoNaoEncontradoError(RegraDeNegocioError):
    def __init__(self, projeto_id: int):
        super().__init__(f"Projeto com ID {projeto_id} não foi encontrado.")


# Exceções de Requisitos (RN02 e RN03)
class RequisitoNaoEncontradoError(RegraDeNegocioError):
    def __init__(self, requisito_id: int):
        super().__init__(f"Requisito com ID {requisito_id} não foi encontrado.")


class RequisitoAprovadoNaoPodeSerAlteradoError(RegraDeNegocioError):
    """RN02: É vedada a alteração ou exclusão de um requisito com status 'Aprovado'."""
    def __init__(self, requisito_id: int, acao: str = "alterar"):
        super().__init__(
            f"RN02: Imutabilidade de Requisitos Aprovados - Não é possível {acao} o requisito {requisito_id} "
            f"pois ele já está com o status 'Aprovado'."
        )


class RequisitoIncompletoError(RegraDeNegocioError):
    """RN03: Um requisito não pode ter seu status alterado para 'Aprovado' se campos obrigatórios estiverem vazios."""
    def __init__(self, campos_faltantes: list[str]):
        campos_str = ", ".join(campos_faltantes)
        super().__init__(
            f"RN03: Bloqueio de Aprovação por Incompletude - O requisito não pode ser Aprovado pois "
            f"os seguintes campos obrigatórios estão vazios/nulos: {campos_str}."
        )
