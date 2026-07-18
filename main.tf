terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 🛑 BOOTSTRAP PHASE: Keep backend completely commented out until buckets are built
  backend "s3" {
    bucket       = "musa-devops-sillypets-state-bucket"
    key          = "global/s3/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true

    endpoints = {
      s3 = "http://localhost:4566"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

# 🌐 Local Emulator Routing Grid (Fully Active)
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3       = "http://localhost:4566"
    ec2      = "http://localhost:4566"
    iam      = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}

# Use interpolation to name your bucket dynamically based on variables
resource "aws_s3_bucket" "local_bucket" {
  bucket = "${var.project_name}-${var.environment}-storage-bucket"
}

resource "aws_s3_bucket" "profile_pictures" {
  bucket = "${var.project_name}-${var.environment}-user-profiles"
}

# 1. Create the Virtual Private Cloud (Network Border)
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# 2. Create a Public Subnet inside our VPC for the Web Server
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet"
  }
}

# 1. Firewall Rule Profile: Open Ingress for Web Gateways
resource "aws_security_group" "web_firewall" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Allow inbound HTTP web traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Upgraded Virtual Server with Automated Docker Bootstrapping
resource "aws_instance" "web_server" {
  ami                    = "ami-12345678"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_firewall.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install docker.io -y
              systemctl start docker
              systemctl enable docker
              docker run -d --name sillypets-app -p 80:80 nginx:alpine
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-web-server"
  }
}

# 2. Output the bucket creation confirmation
output "bucket_name" {
  value       = aws_s3_bucket.local_bucket.id
  description = "The name of your newly emulated local S3 bucket"
}

# 🪣 The Central S3 Storage Bucket for State Files (Fully Active!)
resource "aws_s3_bucket" "state_storage" {
  bucket        = "musa-devops-sillypets-state-bucket"
  force_destroy = true
}

# Enforce encryption on our state files for security
resource "aws_s3_bucket_server_side_encryption_configuration" "state_crypto" {
  bucket = aws_s3_bucket.state_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 2. The DynamoDB State Locking Table
resource "aws_dynamodb_table" "state_locks" {
  name         = "sillypets-infrastructure-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}