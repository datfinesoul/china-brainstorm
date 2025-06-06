# WordPress China Deployment - RDS Database
# AWS China (cn-north-1) - MySQL Database for WordPress

# RDS Parameter Group for MySQL 8.0
resource "aws_db_parameter_group" "wordpress" {
  family = "mysql8.0"
  name   = "${var.project_name}-mysql80"

  tags = {
    Name    = "${var.project_name}-mysql80"
    Purpose = "MySQL 8.0 parameter group for ${var.project_name}"
  }

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "wordpress" {
  identifier = "${var.project_name}-mysql"

  tags = {
    Name    = "${var.project_name}-mysql"
    Purpose = "MySQL database instance for ${var.project_name}"
  }

  # Engine Configuration
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.small"

  # Storage Configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database Configuration
  db_name  = "wordpress"
  username = "wpuser"
  password = random_password.db_password.result

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Parameter and Option Groups
  parameter_group_name = aws_db_parameter_group.wordpress.name

  # Backup Configuration
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Monitoring and Logging
  enabled_cloudwatch_logs_exports       = ["error", "general", "slowquery"]
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Security
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-mysql-final-snapshot"

  depends_on = [aws_cloudwatch_log_group.rds_logs]
}

# CloudWatch Log Groups for RDS
resource "aws_cloudwatch_log_group" "rds_logs" {
  for_each = toset(["error", "general", "slowquery"])

  name              = "/aws/rds/instance/${var.project_name}-mysql/${each.key}"
  retention_in_days = 7
}
