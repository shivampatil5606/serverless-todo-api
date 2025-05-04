variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Logical env name: dev, staging, prod"
  type        = string
  default     = "dev"
}
