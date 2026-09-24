"""add_relacionamento_usuario_projeto

Revision ID: 002_add_relacionamento
Revises: 001_initial_schema
Create Date: 2026-09-24 15:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '002_add_relacionamento'
down_revision: Union[str, None] = '001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Adiciona a nova coluna usuario_id para o relacionamento 1:N no ORM
    op.add_column('projetos', sa.Column('usuario_id', sa.Integer(), nullable=False))
    op.create_index(op.f('ix_projetos_usuario_id'), 'projetos', ['usuario_id'], unique=False)
    
    # Cria o relacionamento de chave estrangeira com a tabela usuarios (1:N)
    op.create_foreign_key(
        'fk_projetos_usuarios',
        'projetos',
        'usuarios',
        ['usuario_id'],
        ['id'],
        ondelete='CASCADE'
    )


def downgrade() -> None:
    # Reverte a chave estrangeira e a coluna adicionada
    op.drop_constraint('fk_projetos_usuarios', 'projetos', type_='foreignkey')
    op.drop_index(op.f('ix_projetos_usuario_id'), table_name='projetos')
    op.drop_column('projetos', 'usuario_id')
