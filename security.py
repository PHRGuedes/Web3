import os
from datetime import datetime, timedelta
from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from database import get_db

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY", "sua_chave_secreta_super_segura_para_jwt_dev_123456789")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

# OAuth2 Password Bearer para ler o token do cabeçalho Authorization
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/usuarios/login")

# Contexto do Passlib para Bcrypt
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_senha(senha: str) -> str:
    """Gera o hash bcrypt da senha."""
    return pwd_context.hash(senha)


def verificar_senha(senha_plana: str, senha_hash: str) -> bool:
    """Verifica se a senha plana corresponde ao hash."""
    return pwd_context.verify(senha_plana, senha_hash)


def criar_token_acesso(data: dict, expires_delta: timedelta | None = None) -> str:
    """Gera um JWT assinado com tempo de expiração."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """Dependência para autenticar requisições via JWT. Importa dinamicamente para evitar import circular."""
    from usuarios._repository import UsuarioRepository
    from erros import CredenciaisInvalidasError

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token de autenticação inválido ou expirado.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    repo = UsuarioRepository(db)
    usuario = repo.get_by_email(email)
    if usuario is None:
        raise credentials_exception
    return usuario
