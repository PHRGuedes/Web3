"""initial_schema

Revision ID: 001_initial_schema
Revises: 
Create Date: 2026-09-24 14:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Tabela Usuarios
    op.create_table(
        'usuarios',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('nome', sa.String(length=150), nullable=False),
        sa.Column('email', sa.String(length=150), nullable=False),
        sa.Column('senha_hash', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_usuarios_email'), 'usuarios', ['email'], unique=True)
    op.create_index(op.f('ix_usuarios_id'), 'usuarios', ['id'], unique=False)

    # 2. Tabela Projetos (Criada inicialmente sem a ForeignKey de usuario)
    op.create_table(
        'projetos',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('nome', sa.String(length=150), nullable=False),
        sa.Column('descricao', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_projetos_id'), 'projetos', ['id'], unique=False)
    op.create_index(op.f('ix_projetos_nome'), 'projetos', ['nome'], unique=False)

    # 3. Tabela Requisitos
    op.create_table(
        'requisitos',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('titulo', sa.String(length=150), nullable=False),
        sa.Column('descricao', sa.Text(), nullable=True),
        sa.Column('tipo', sa.String(length=50), nullable=True),
        sa.Column('prioridade', sa.String(length=50), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='Rascunho'),
        sa.Column('criterio_aceitacao', sa.Text(), nullable=True),
        sa.Column('projeto_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['projeto_id'], ['projetos.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_requisitos_id'), 'requisitos', ['id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_requisitos_id'), table_name='requisitos')
    op.drop_table('requisitos')
    op.drop_index(op.f('ix_projetos_nome'), table_name='projetos')
    op.drop_index(op.f('ix_projetos_id'), table_name='projetos')
    op.drop_table('projetos')
    op.drop_index(op.f('ix_usuarios_id'), table_name='usuarios')
    op.drop_index(op.f('ix_usuarios_email'), table_name='usuarios')
    op.drop_table('usuarios')
