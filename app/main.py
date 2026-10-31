import os
import socket
from datetime import datetime, timezone
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

app = FastAPI(
    title="AWS GitOps Platform API & Ebook Portal",
    description="Containerized Ebook Portal deployed via GitHub Actions OIDC, Terraform, ECR, and ECS Fargate",
    version="1.2.0",
)

# 1. Mount static asset directories so browser can load CSS, JS, fonts, and images
app.mount("/css", StaticFiles(directory="static/css"), name="css")
app.mount("/js", StaticFiles(directory="static/js"), name="js")
app.mount("/images", StaticFiles(directory="static/images"), name="images")
app.mount("/fonts", StaticFiles(directory="static/fonts"), name="fonts")


@app.get("/")
def serve_homepage():
    """Serves your real Ebook landing page as the homepage."""
    return FileResponse("static/index.html")


@app.get("/health")
def health_check():
    """Health check endpoint polled every 30 seconds by the AWS Load Balancer."""
    return {"status": "healthy"}


@app.get("/api/info")
def platform_info():
    """JSON metadata endpoint showing which private ECS container answered."""
    return {
        "service": "aws-gitops-platform-ebook",
        "status": "online",
        "version": "1.2.0",
        "environment": os.getenv("ENVIRONMENT", "dev"),
        "container_hostname": socket.gethostname(),
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
    }
