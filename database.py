import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Carrega variáveis de ambiente do arquivo .env
load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5433/requisitos_db"
)

# Engine do SQLAlchemy
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# Fabrica de sessões do banco de dados
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base declarativa para os modelos SQLAlchemy
Base = declarative_base()


def get_db():
    """Dependência do FastAPI que fornece uma sessão do banco de dados por requisição."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
