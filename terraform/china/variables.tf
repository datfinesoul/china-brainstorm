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
