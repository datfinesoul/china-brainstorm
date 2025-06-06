# WordPress China Deployment - Variables
# AWS China (cn-north-1) - Configuration Variables

variable "aws_region" {
  description = "AWS China Region"
  type        = string
  default     = "cn-north-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "wordpress-china"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment (production, staging, etc.)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["cn-north-1a", "cn-north-1b"]
}

variable "domain_name" {
  description = "Domain name for WordPress site (e.g., example.com)"
  type        = string
  default     = ""
}
