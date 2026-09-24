from usuarios._model import Usuario, UsuarioCreate, UsuarioLogin
from usuarios._repository import UsuarioRepository
from security import hash_senha, verificar_senha, criar_token_acesso
from erros import UsuarioJaExisteError, CredenciaisInvalidasError


class UsuarioService:
    """Camada de negócio para Usuários. NÃO levanta HTTPException e NÃO faz queries diretas no BD."""

    def __init__(self, repository: UsuarioRepository):
        self.repository = repository

    def cadastrar_usuario(self, dados: UsuarioCreate) -> Usuario:
        # Regra de negócio: E-mail único
        usuario_existente = self.repository.get_by_email(dados.email)
        if usuario_existente:
            raise UsuarioJaExisteError(dados.email)

        # Hash da senha
        senha_criptografada = hash_senha(dados.senha)

        # Instanciação da entidade ORM
        novo_usuario = Usuario(
            nome=dados.nome,
            email=dados.email,
            senha_hash=senha_criptografada
        )

        return self.repository.create(novo_usuario)

    def autenticar_usuario(self, dados: UsuarioLogin) -> dict:
        usuario = self.repository.get_by_email(dados.email)
        if not usuario or not verificar_senha(dados.senha, usuario.senha_hash):
            raise CredenciaisInvalidasError()

        # Criação do Token JWT contendo o e-mail (sub) e id do usuário
        token = criar_token_acesso(data={"sub": usuario.email, "user_id": usuario.id})
        return {"access_token": token, "token_type": "bearer"}
