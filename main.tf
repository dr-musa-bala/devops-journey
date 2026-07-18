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
# 2. Output the bucket creation confirmation
output "bucket_name" {
  value       = aws_s3_bucket.local_bucket.id
  description = "The name of your newly emulated local S3 bucket"
}