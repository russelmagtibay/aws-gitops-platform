import os
import socket
from datetime import datetime, timezone
from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI(
    title="AWS GitOps Platform API",
    description="Highly Available Containerized API deployed via GitHub Actions OIDC, Terraform, ECR, and ECS Fargate",
    version="1.1.0",
)


@app.get("/")
def root():
    """Main JSON endpoint showing which ECS container answered the request."""
    return {
        "service": "aws-gitops-platform-api",
        "status": "online",
        "version": "1.1.0",
        "environment": os.getenv("ENVIRONMENT", "dev"),
        "container_hostname": socket.gethostname(),
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/health")
def health_check():
    """Health check endpoint polled by the AWS Application Load Balancer."""
    return {"status": "healthy"}


@app.get("/dashboard", response_class=HTMLResponse)
def dashboard():
    """Visual portfolio dashboard showing live Multi-AZ ECS Fargate load balancing."""
    hostname = socket.gethostname()
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    az = "ap-southeast-1a (10.0.11.0/24)" if "10-0-11" in hostname else "ap-southeast-1b (10.0.12.0/24)"
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Russel Magtibay | AWS GitOps Platform</title>
        <style>
            body {{ font-family: system-ui, sans-serif; background: #0f172a; color: #f8fafc; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }}
            .card {{ background: #1e293b; border: 1px solid #334155; border-radius: 16px; padding: 32px; max-width: 560px; width: 90%; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.5); }}
            .badge {{ display: inline-block; background: #065f46; color: #34d399; padding: 4px 12px; border-radius: 999px; font-size: 13px; font-weight: 600; margin-bottom: 12px; }}
            h1 {{ margin: 0 0 8px 0; font-size: 24px; }}
            p {{ color: #94a3b8; margin: 0 0 24px 0; font-size: 14px; }}
            .stat {{ background: #0f172a; border: 1px solid #334155; border-radius: 10px; padding: 14px 16px; margin-bottom: 12px; display: flex; justify-content: space-between; }}
            .label {{ color: #94a3b8; font-size: 13px; }}
            .value {{ color: #38bdf8; font-family: monospace; font-weight: 600; font-size: 14px; }}
            button {{ width: 100%; background: #2563eb; color: white; border: none; padding: 12px; border-radius: 8px; font-size: 15px; font-weight: 600; cursor: pointer; margin-top: 8px; }}
            button:hover {{ background: #1d4ed8; }}
        </style>
    </head>
    <body>
        <div class="card">
            <span class="badge">● LIVE ON AWS ECS FARGATE</span>
            <h1>AWS GitOps Platform (v1.1.0)</h1>
            <p>Engineered by <strong>Russel Magtibay</strong> • Terraform • GitHub Actions OIDC • Multi-AZ ALB & ECS</p>
            <div class="stat"><span class="label">Container Hostname</span><span class="value">{hostname}</span></div>
            <div class="stat"><span class="label">Private Subnet / AZ</span><span class="value">{az}</span></div>
            <div class="stat"><span class="label">Response Time (UTC)</span><span class="value">{now}</span></div>
            <button onclick="window.location.reload()">🔄 Refresh to Test Multi-AZ Load Balancer</button>
        </div>
    </body>
    </html>
    """