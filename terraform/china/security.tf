# WordPress China Deployment - Security Groups
# AWS China (cn-north-1) - Application Security Groups

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "internet-facing-alb-"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "internet-facing-alb"
    Purpose     = "Security group for ALBs in public subnets with internet access"
    Subnet-Type = "public"
  }
}

# ALB Security Group Rules
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "All outbound traffic"
}

# Security Group for EC2 WordPress Instances
resource "aws_security_group" "wordpress" {
  name_prefix = "application-tier-"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "application-tier"
    Purpose     = "Security group for application instances in private subnets"
    Subnet-Type = "private"
  }
}

# EC2 Security Group Rules
resource "aws_security_group_rule" "wordpress_ingress_http_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.wordpress.id
  description              = "HTTP from ALB"
}

resource "aws_security_group_rule" "wordpress_ingress_https_from_alb" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.wordpress.id
  description              = "HTTPS from ALB"
}

# SFTP access for file transfers (matches NACL rule)
resource "aws_security_group_rule" "wordpress_ingress_sftp" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.wordpress.id
  description       = "SFTP for file transfers (no SSH shell access)"
}

# ICMP ping for health checks and troubleshooting (matches NACL rule)
resource "aws_security_group_rule" "wordpress_ingress_icmp" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.wordpress.id
  description       = "ICMP ping for health checks and network troubleshooting"
}

resource "aws_security_group_rule" "wordpress_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.wordpress.id
  description       = "All outbound traffic"
}

# Security Group for RDS Database
resource "aws_security_group" "rds" {
  name_prefix = "database-tier-"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "database-tier"
    Purpose     = "Security group for RDS instances in database subnets"
    Subnet-Type = "database"
  }
}

# RDS Security Group Rules
resource "aws_security_group_rule" "rds_ingress_mysql" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = aws_subnet.private[*].cidr_block
  security_group_id = aws_security_group.rds.id
  description       = "MySQL from private subnets"
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "All outbound traffic"
}
