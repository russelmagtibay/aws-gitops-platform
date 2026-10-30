from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "aws-gitops-platform-api"
    assert data["status"] == "online"
    assert "container_hostname" in data


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_dashboard_endpoint():
    response = client.get("/dashboard")
    assert response.status_code == 200
    assert "Russel Magtibay" in response.text