from sqlalchemy.orm import Session
from projetos._model import Projeto


class ProjetoRepository:
    """ÚNICA camada que executa queries no banco de dados para a entidade Projeto."""

    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, projeto_id: int) -> Projeto | None:
        return self.db.query(Projeto).filter(Projeto.id == projeto_id).first()

    def get_by_nome_and_user(self, nome: str, usuario_id: int) -> Projeto | None:
        return self.db.query(Projeto).filter(
            Projeto.nome == nome,
            Projeto.usuario_id == usuario_id
        ).first()

    def get_all_by_user(self, usuario_id: int, search_nome: str | None = None) -> list[Projeto]:
        query = self.db.query(Projeto).filter(Projeto.usuario_id == usuario_id)
        if search_nome:
            query = query.filter(Projeto.nome.ilike(f"%{search_nome}%"))
        return query.order_by(Projeto.created_at.desc()).all()

    def create(self, projeto: Projeto) -> Projeto:
        self.db.add(projeto)
        self.db.commit()
        self.db.refresh(projeto)
        return projeto

    def update(self, projeto: Projeto, dados: dict) -> Projeto:
        for campo, valor in dados.items():
            if valor is not None:
                setattr(projeto, campo, valor)
        self.db.commit()
        self.db.refresh(projeto)
        return projeto

    def delete(self, projeto: Projeto) -> None:
        self.db.delete(projeto)
        self.db.commit()
