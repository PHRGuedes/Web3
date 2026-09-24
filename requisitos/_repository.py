from sqlalchemy.orm import Session
from requisitos._model import Requisito


class RequisitoRepository:
    """ÚNICA camada que executa queries no banco de dados para a entidade Requisito."""

    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, requisito_id: int) -> Requisito | None:
        return self.db.query(Requisito).filter(Requisito.id == requisito_id).first()

    def get_all_by_projeto(self, projeto_id: int, status_filter: str | None = None) -> list[Requisito]:
        query = self.db.query(Requisito).filter(Requisito.projeto_id == projeto_id)
        if status_filter:
            query = query.filter(Requisito.status.ilike(status_filter))
        return query.order_by(Requisito.created_at.desc()).all()

    def create(self, requisito: Requisito) -> Requisito:
        self.db.add(requisito)
        self.db.commit()
        self.db.refresh(requisito)
        return requisito

    def update(self, requisito: Requisito, dados: dict) -> Requisito:
        for campo, valor in dados.items():
            if valor is not None:
                setattr(requisito, campo, valor)
        self.db.commit()
        self.db.refresh(requisito)
        return requisito

    def delete(self, requisito: Requisito) -> None:
        self.db.delete(requisito)
        self.db.commit()
