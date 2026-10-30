# 1. Virtual Private Cloud
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }

  lifecycle {
    # Guardrail: Prevent accidental replacement or invalid network config
    precondition {
      condition     = can(cidrnetmask(var.vpc_cidr))
      error_message = "VPC CIDR mask is invalid."
    }
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id


  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 3. Public Subnets (Mapped per AZ with for_each)
resource "aws_subnet" "public" {

  for_each = var.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${each.key}"
    Tier = "Public"
  }

  lifecycle {
    # Ensure subnet CIDR fits cleanly inside the VPC CIDR
    precondition {
      condition     = can(cidrsubnet(var.vpc_cidr, 8, 0))
      error_message = "Subnet calculation error: verify your VPC and subnet CIDR prefixes."
    }
  }
}

# 4. Private Subnets (Mapped per AZ with for_each)
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-${each.key}"
    Tier = "Private"
  }
}

# 5. Elastic IP + NAT Gateway (Attached to the first public subnet)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  # Uses the first public subnet key deterministically
  subnet_id = aws_subnet.public[keys(var.public_subnets)[0]].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

# 6. Public Route Table & Associations
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# 7. Private Route Table & Associations
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}