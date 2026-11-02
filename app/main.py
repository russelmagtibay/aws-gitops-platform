import os
import socket
from datetime import datetime, timezone
import boto3
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

app = FastAPI(
    title="AWS GitOps Platform API & Ebook Portal",
    description="Containerized Ebook Portal with DynamoDB & SNS Lead Capture on ECS Fargate",
    version="1.3.0",
)

# Mount static asset directories so browser can load CSS, JS, fonts, and images
app.mount("/css", StaticFiles(directory="static/css"), name="css")
app.mount("/js", StaticFiles(directory="static/js"), name="js")
app.mount("/images", StaticFiles(directory="static/images"), name="images")
app.mount("/fonts", StaticFiles(directory="static/fonts"), name="fonts")


class LeadRequest(BaseModel):
    name: str
    email: str
    message: str = "Requested ebook download"


@app.get("/")
def serve_homepage():
    """Serves your Ebook landing page as the homepage."""
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
        "version": "1.3.0",
        "environment": os.getenv("ENVIRONMENT", "dev"),
        "container_hostname": socket.gethostname(),
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
    }


@app.post("/leads")
def capture_lead(lead: LeadRequest):
    """Saves client lead to Amazon DynamoDB and sends an instant Amazon SNS email notification."""
    name = lead.name.strip()
    email = lead.email.strip()

    if not name or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid name and email are required.")

    timestamp = datetime.now(timezone.utc).isoformat()
    region = os.getenv("AWS_REGION", "ap-southeast-1")
    table_name = os.getenv("DYNAMODB_TABLE_NAME")
    sns_topic_arn = os.getenv("SNS_TOPIC_ARN")

    # 1. Save client lead into Amazon DynamoDB
    if table_name:
        dynamodb = boto3.resource("dynamodb", region_name=region)
        table = dynamodb.Table(table_name)
        table.put_item(
            Item={
                "email": email,
                "timestamp": timestamp,
                "name": name,
                "message": lead.message,
                "container_hostname": socket.gethostname(),
            }
        )

    # 2. Send instant email notification via Amazon SNS
    if sns_topic_arn:
        sns = boto3.client("sns", region_name=region)
        sns.publish(
            TopicArn=sns_topic_arn,
            Subject=f"New Ebook Client Request: {name}",
            Message=(
                f"Hello Russel,\n\n"
                f"A new client just requested to download your Ebook!\n\n"
                f"• Client Name:  {name}\n"
                f"• Client Email: {email}\n"
                f"• Message:      {lead.message}\n"
                f"• Timestamp:    {timestamp}\n"
                f"• ECS Server:   {socket.gethostname()}\n"
            ),
        )

    return {
        "status": "success",
        "message": f"Thank you, {name}! Your ebook request has been recorded.",
    }