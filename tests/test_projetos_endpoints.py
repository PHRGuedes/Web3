import pytest
from fastapi.testclient import TestClient


def obter_token_autenticado(client: TestClient, email: str = "usuario@teste.com", senha: str = "senha123") -> str:
    """Helper para cadastrar um usuário e retornar seu token JWT de acesso."""
    cadastro_resp = client.post(
        "/usuarios/cadastro",
        json={"nome": "Usuário Teste", "email": email, "senha": senha},
    )
    assert cadastro_resp.status_code == 201, cadastro_resp.text

    login_resp = client.post(
        "/usuarios/login",
        json={"email": email, "senha": senha},
    )
    assert login_resp.status_code == 200, login_resp.text
    return login_resp.json()["access_token"]


def test_caminho_critico_crud_projetos_com_autenticacao(client: TestClient):
    """
    Teste de endpoint cobrindo o caminho crítico completo:
    1. Autenticação e geração de token JWT
    2. Criação de Projeto (POST) com 201 Created
    3. Bloqueio de duplicidade RN01 com 409 Conflict (frase da API)
    4. Validação de payload inválido com 422 Unprocessable Entity
    5. Busca com parâmetro de consulta (?nome=)
    6. Atualização parcial do projeto (PATCH)
    7. Exclusão do projeto (DELETE) com 204 No Content
    """
    token = obter_token_autenticado(client)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Criação do projeto (POST) - Sucesso 201
    payload_criacao = {
        "nome": "ReqFlow Sistema de Requisitos",
        "descricao": "Gestão ágil de histórias e critérios de aceitação",
    }
    resp_post = client.post("/projetos/", json=payload_criacao, headers=headers)
    assert resp_post.status_code == 201
    projeto_criado = resp_post.json()
    assert projeto_criado["id"] > 0
    assert projeto_criado["nome"] == payload_criacao["nome"]
    assert projeto_criado["descricao"] == payload_criacao["descricao"]
    projeto_id = projeto_criado["id"]

    # 2. Recusa por duplicidade de nome no mesmo usuário (RN01) - 409 Conflito
    resp_duplicado = client.post("/projetos/", json=payload_criacao, headers=headers)
    assert resp_duplicado.status_code == 409
    erro_duplicado = resp_duplicado.json()
    assert erro_duplicado["erro"] == "RN01_NOME_DUPLICADO"
    assert "Você já possui um projeto cadastrado com o nome" in erro_duplicado["mensagem"]

    # 3. Recusa por validação de campos (Pydantic) - 422 Unprocessable Entity
    resp_invalido = client.post("/projetos/", json={"nome": "A"}, headers=headers)
    assert resp_invalido.status_code == 422
    erro_invalido = resp_invalido.json()
    assert erro_invalido["erro"] == "VALIDACAO_FALHOU"

    # 4. Listagem e busca com filtro por parâmetro (?nome=)
    resp_busca_match = client.get("/projetos/?nome=ReqFlow", headers=headers)
    assert resp_busca_match.status_code == 200
    lista_match = resp_busca_match.json()
    assert len(lista_match) == 1
    assert lista_match[0]["id"] == projeto_id

    resp_busca_empty = client.get("/projetos/?nome=InexistenteXYZ", headers=headers)
    assert resp_busca_empty.status_code == 200
    assert len(resp_busca_empty.json()) == 0

    # 5. Edição do projeto (PATCH)
    payload_edicao = {
        "nome": "ReqFlow 2.0 Enterprise",
        "descricao": "Versão corporativa atualizada",
    }
    resp_patch = client.patch(f"/projetos/{projeto_id}", json=payload_edicao, headers=headers)
    assert resp_patch.status_code == 200
    projeto_atualizado = resp_patch.json()
    assert projeto_atualizado["id"] == projeto_id
    assert projeto_atualizado["nome"] == "ReqFlow 2.0 Enterprise"
    assert projeto_atualizado["descricao"] == "Versão corporativa atualizada"

    # 6. Exclusão do projeto (DELETE) - Sucesso 204
    resp_delete = client.delete(f"/projetos/{projeto_id}", headers=headers)
    assert resp_delete.status_code == 204

    # 7. Verificação de que o projeto não existe mais (404)
    resp_get_deletado = client.get(f"/projetos/{projeto_id}", headers=headers)
    assert resp_get_deletado.status_code == 404
