from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from database import Base


# ==========================================
# Modelo SQLAlchemy (Banco de Dados)
# ==========================================
class Projeto(Base):
    __tablename__ = "projetos"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(150), nullable=False, index=True)
    descricao = Column(Text, nullable=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relacionamento N para 1 com Usuario
    usuario = relationship("Usuario", back_populates="projetos")
    
    # Relacionamento 1 para N com Requisitos
    requisitos = relationship("Requisito", back_populates="projeto", cascade="all, delete-orphan")


# ==========================================
# Schemas Pydantic (Validação e DTOs)
# ==========================================
class ProjetoCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=150, description="Nome identificador do projeto (mínimo 2 caracteres)")
    descricao: str | None = Field(None, max_length=1000, description="Descrição detalhada do projeto")


class ProjetoUpdate(BaseModel):
    nome: str | None = Field(None, min_length=2, max_length=150, description="Novo nome do projeto (mínimo 2 caracteres)")
    descricao: str | None = Field(None, max_length=1000, description="Nova descrição detalhada do projeto")


class ProjetoPublic(BaseModel):
    id: int
    nome: str
    descricao: str | None = None
    usuario_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
