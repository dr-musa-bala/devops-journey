variable "environment" {
  type        = string
  description = "The target deployment environment (e.g., dev, staging, prod)"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "The name of the core application stack"
  default     = "sillypets"
}

variable "image_tag" {
  type        = string
  description = "The specific GitHub SHA tag of the container image to deploy"
  default     = "latest"
}