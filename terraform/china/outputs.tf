# WordPress China Deployment - Outputs
# AWS China (cn-north-1) - Resource Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = aws_db_subnet_group.main.name
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = aws_security_group.vpc_endpoints.id
}

# Database outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.wordpress.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.wordpress.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.wordpress.db_name
}

output "rds_username" {
  description = "RDS database username"
  value       = aws_db_instance.wordpress.username
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "db_password_secret_arn" {
  description = "ARN of the database password secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_password_secret_name" {
  description = "Name of the database password secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_password.name
}

# ALB and WordPress Security Group outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "wordpress_security_group_id" {
  description = "ID of the WordPress security group"
  value       = aws_security_group.wordpress.id
}

# Application Load Balancer outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.wordpress.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = aws_lb.wordpress.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.wordpress.arn
}

# CloudFront outputs (conditional)
output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = var.domain_name != "" ? aws_cloudfront_distribution.wordpress[0].domain_name : null
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = var.domain_name != "" ? aws_cloudfront_distribution.wordpress[0].id : null
}

# Launch Template outputs
# Launch Template outputs
output "launch_template_id" {
  description = "ID of the WordPress launch template"
  value       = aws_launch_template.wordpress.id
}

output "launch_template_latest_version" {
  description = "Latest version of the WordPress launch template"
  value       = aws_launch_template.wordpress.latest_version
}

# Auto Scaling Group outputs
output "autoscaling_group_name" {
  description = "Name of the WordPress Auto Scaling Group"
  value       = aws_autoscaling_group.wordpress.name
}

output "autoscaling_group_arn" {
  description = "ARN of the WordPress Auto Scaling Group"
  value       = aws_autoscaling_group.wordpress.arn
}

# WordPress access information
output "wordpress_url" {
  description = "WordPress site URL via CloudFront or ALB"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_lb.wordpress.dns_name}"
}

output "wordpress_admin_url" {
  description = "WordPress admin URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}/wp-admin" : "http://${aws_lb.wordpress.dns_name}/wp-admin"
}
