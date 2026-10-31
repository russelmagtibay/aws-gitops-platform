from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_homepage_serves_html():
    """Tests that root / returns 200 OK and contains Ebook HTML."""
    response = client.get("/")
    assert response.status_code == 200
    assert "Ebook" in response.text or "<!doctype html>" in response.text.lower()


def test_health_endpoint():
    """Tests that AWS ALB health check responds 200 healthy."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_api_info_endpoint():
    """Tests that API info returns JSON with container hostname."""
    response = client.get("/api/info")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "aws-gitops-platform-ebook"
    assert "container_hostname" in data
