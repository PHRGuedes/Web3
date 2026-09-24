from datetime import datetime
from pydantic import BaseModel, EmailStr, ConfigDict, Field
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import relationship

from database import Base


# ==========================================
# Modelo SQLAlchemy (Banco de Dados)
# ==========================================
class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(150), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    senha_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relacionamento 1 para N com Projetos
    projetos = relationship("Projeto", back_populates="usuario", cascade="all, delete-orphan")


# ==========================================
# Schemas Pydantic (Validação e DTOs)
# ==========================================
class UsuarioCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=150, description="Nome completo do usuário (mínimo 2 caracteres)")
    email: EmailStr = Field(..., description="E-mail válido e exclusivo")
    senha: str = Field(..., min_length=6, max_length=100, description="Senha de acesso (mínimo 6 caracteres)")


class UsuarioLogin(BaseModel):
    email: EmailStr = Field(..., description="E-mail cadastrado")
    senha: str = Field(..., min_length=1, description="Senha de acesso")


class UsuarioPublic(BaseModel):
    """Schema público de resposta. A SENHA NUNCA DEVE CONSTAR NESTE SCHEMA."""
    id: int
    nome: str
    email: EmailStr
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
