import os
import socket
from datetime import datetime, timezone
from fastapi import FastAPI

app = FastAPI(
    title="AWS GitOps Platform API",
    description="Highly Available Containerized API deployed via GitHub Actions OIDC, Terraform, ECR, and ECS Fargate",
    version="1.0.0",
)


@app.get("/")
def root():
    """Main endpoint showing which ECS container answered the request."""
    return {
        "service": "aws-gitops-platform-api",
        "status": "online",
        "environment": os.getenv("ENVIRONMENT", "dev"),
        "container_hostname": socket.gethostname(),
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/health")
def health_check():
    """Health check endpoint polled by the AWS Application Load Balancer."""
    return {"status": "healthy"}