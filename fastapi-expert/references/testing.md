# Testing en FastAPI

## Setup base con pytest

```python
# tests/conftest.py
import pytest
from fastapi.testclient import TestClient
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.db import get_supabase
from unittest.mock import MagicMock, patch

# Cliente síncrono (para tests simples)
@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c

# Cliente async (para tests de endpoints async)
@pytest.fixture
async def async_client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c

# Mock de Supabase
@pytest.fixture
def mock_supabase():
    with patch("app.db.get_supabase") as mock:
        supabase = MagicMock()
        mock.return_value = supabase
        yield supabase

# Usuario autenticado para tests
@pytest.fixture
def auth_headers():
    return {"Authorization": "Bearer test-token-valid"}

@pytest.fixture
def mock_auth():
    with patch("app.dependencies.get_current_user") as mock:
        mock.return_value = {"id": "user-123", "email": "test@test.com"}
        yield mock
```

## Tests de endpoints

```python
# tests/test_products.py
import pytest

def test_list_products_success(client, mock_supabase):
    # Arrange
    mock_supabase.table.return_value.select.return_value \
        .eq.return_value.execute.return_value.data = [
            {"id": "1", "name": "Nike Air", "price": 150000}
        ]

    # Act
    response = client.get("/api/products/?catalog_id=cat-1")

    # Assert
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["name"] == "Nike Air"

def test_create_product_unauthorized(client):
    response = client.post("/api/products/", json={"name": "Test"})
    assert response.status_code == 401

def test_create_product_success(client, mock_supabase, mock_auth):
    mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [
        {"id": "new-id", "name": "Adidas", "price": 120000}
    ]

    response = client.post(
        "/api/products/",
        json={"name": "Adidas", "price": 120000},
        headers={"Authorization": "Bearer token"},
    )

    assert response.status_code == 201
    assert response.json()["id"] == "new-id"

def test_get_product_not_found(client, mock_supabase):
    mock_supabase.table.return_value.select.return_value \
        .eq.return_value.single.return_value.execute.return_value.data = None

    response = client.get("/api/products/nonexistent")
    assert response.status_code == 404
```

## Tests de validación Pydantic

```python
def test_invalid_price(client, mock_auth):
    response = client.post(
        "/api/products/",
        json={"name": "Test", "price": -100},  # precio negativo
        headers={"Authorization": "Bearer token"},
    )
    assert response.status_code == 422
    errors = response.json()["detail"]
    assert any("price" in str(e) for e in errors)
```

## Tests de servicios (sin HTTP)

```python
# tests/test_text_parser.py
import pytest
from app.services.text_parser import TextParser

@pytest.mark.parametrize("text,expected", [
    ("Nike Air Force 👩 $150.000", {"brand": "Nike", "gender": "DAMA", "price": 150000}),
    ("Adidas Superstar 👨 $120000", {"brand": "Adidas", "gender": "HOMBRE", "price": 120000}),
    ("ref 1234 precio 80", {"brand": "Genérica", "price": 80}),
])
def test_parse_whatsapp_text(text, expected):
    result = TextParser.parse(text)
    for key, value in expected.items():
        assert result[key] == value
```

## Correr tests

```bash
# Todos los tests
pytest tests/ -v

# Un archivo específico
pytest tests/test_products.py -v

# Un test específico
pytest tests/test_products.py::test_create_product_success -v

# Con cobertura
pytest tests/ --cov=app --cov-report=html
open htmlcov/index.html  # ver reporte

# Solo tests marcados
pytest tests/ -m "not slow"
```
