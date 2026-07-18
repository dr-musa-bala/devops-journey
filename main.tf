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

# 3. Provision a Virtual Compute Server (EC2) inside our Subnet
resource "aws_instance" "web_server" {
  ami           = "ami-12345678" # A mock AMI ID for our local emulator
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id # Drops the server directly into our new network room

  tags = {
    Name = "${var.project_name}-${var.environment}-web-server"
  }
}
# 2. Output the bucket creation confirmation
output "bucket_name" {
  value       = aws_s3_bucket.local_bucket.id
  description = "The name of your newly emulated local S3 bucket"
}