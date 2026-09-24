from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from database import Base


# ==========================================
# Modelo SQLAlchemy (Banco de Dados)
# ==========================================
class Requisito(Base):
    __tablename__ = "requisitos"

    id = Column(Integer, primary_key=True, index=True)
    titulo = Column(String(150), nullable=False)
    descricao = Column(Text, nullable=True)
    tipo = Column(String(50), nullable=True)  # ex: "Funcional", "Não-Funcional"
    prioridade = Column(String(50), nullable=True)  # ex: "Alta", "Média", "Baixa"
    status = Column(String(50), default="Rascunho", nullable=False)  # ex: "Rascunho", "Aprovado", "Rejeitado"
    criterio_aceitacao = Column(Text, nullable=True)
    
    projeto_id = Column(Integer, ForeignKey("projetos.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relacionamento N para 1 com Projeto
    projeto = relationship("Projeto", back_populates="requisitos")


# ==========================================
# Schemas Pydantic (Validação e DTOs)
# ==========================================
class RequisitoCreate(BaseModel):
    titulo: str = Field(..., min_length=2, max_length=150, description="Título claro do requisito (mínimo 2 caracteres)")
    descricao: str | None = Field(None, max_length=2000, description="Descrição detalhada do requisito")
    tipo: str | None = Field(None, description="Tipo do requisito (ex: Funcional, Não-Funcional)")
    prioridade: str | None = Field(None, description="Prioridade (ex: Alta, Média, Baixa)")
    status: str = Field(default="Rascunho", description="Status do requisito: Rascunho, Aprovado ou Rejeitado")
    criterio_aceitacao: str | None = Field(None, max_length=2000, description="Critérios de aceitação para aprovação")


class RequisitoUpdate(BaseModel):
    titulo: str | None = Field(None, min_length=2, max_length=150, description="Novo título do requisito")
    descricao: str | None = Field(None, max_length=2000, description="Nova descrição")
    tipo: str | None = Field(None, description="Novo tipo do requisito")
    prioridade: str | None = Field(None, description="Nova prioridade")
    status: str | None = Field(None, description="Novo status")
    criterio_aceitacao: str | None = Field(None, max_length=2000, description="Novos critérios de aceitação")


class RequisitoPublic(BaseModel):
    id: int
    titulo: str
    descricao: str | None = None
    tipo: str | None = None
    prioridade: str | None = None
    status: str
    criterio_aceitacao: str | None = None
    projeto_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
