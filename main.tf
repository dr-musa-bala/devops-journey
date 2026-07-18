terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Override default AWS settings to target Floci's local endpoints
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

 s3_use_path_style             = true
  # Redirect all cloud resource requests to localhost
  endpoints {
    s3  = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
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
  vpc_id                  = aws_vpc.main_vpc.id # Links this subnet directly to our VPC above
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

  # Open HTTP Port 80 to the public world
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow the server to download packages out to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Upgraded Virtual Server with Automated Docker Bootstrapping
resource "aws_instance" "web_server" {
  ami                    = "ami-12345678" # Mock AMI schema for local runtime
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_firewall.id] # Attaches the firewall profile

  # The Automated Bootstrap Script Execution Layer
  user_data = <<-EOF
              #!/bin/bash
              # Update package manager mirrors
              apt-get update -y
              
              # Install the core Docker runtime daemon
              apt-get install docker.io -y
              
              # Boot up the docker service engine
              systemctl start docker
              systemctl enable docker
              
              # Reach out to Docker Hub, pull the app, and map port 80
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