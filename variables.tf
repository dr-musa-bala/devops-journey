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