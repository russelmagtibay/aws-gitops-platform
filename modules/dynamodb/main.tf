resource "aws_dynamodb_table" "leads" {
  name         = "${var.project_name}-leads"
  billing_mode = "PAY_PER_REQUEST" # Serverless ($0.00 when idle!)

  hash_key  = "email"
  range_key = "timestamp"

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-leads"
  }
}