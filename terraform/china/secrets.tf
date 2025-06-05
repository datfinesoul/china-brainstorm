# WordPress China Deployment - Secrets Management
# AWS China (cn-north-1) - AWS Secrets Manager

# Random password for WordPress database
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# AWS Secrets Manager secret for database password
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}/database/password"
  description             = "WordPress MySQL database password"
  recovery_window_in_days = 30

  tags = {
    Name = "${var.project_name}-db-password"
  }
}

# Store the password in the secret
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "wpuser"
    password = random_password.db_password.result
  })
}
