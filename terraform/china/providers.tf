# WordPress China Deployment - Provider Configuration
# AWS China (cn-north-1) - Provider Setup

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider for China partition
provider "aws" {
  region = var.aws_region
  
  # China partition specific configuration
  endpoints {
    # Use China-specific endpoints if needed
  }
  
  # Default tags applied to all resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}
