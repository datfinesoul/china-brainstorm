# WordPress China Deployment - Network ACLs
# AWS China (cn-north-1) - Network Access Control Lists

# Network ACLs (basic security layer)
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name        = "internet-facing"
    Purpose     = "Network ACL for public subnets with internet access (ALB, NAT Gateway)"
    Subnet-Type = "public"
  }
}

# Public NACL Rules
resource "aws_network_acl_rule" "public_ingress_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_ingress_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_ingress_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_egress_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "application-tier"
    Purpose     = "Network ACL for private subnets hosting WordPress instances"
    Subnet-Type = "private"
  }
}

# Private NACL Rules
resource "aws_network_acl_rule" "private_ingress_http" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_vpc.main.cidr_block
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "private_ingress_https" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_vpc.main.cidr_block
  from_port      = 443
  to_port        = 443
}

# SFTP access over existing VPN (port 22)
# Note: No SSH shell access - only SFTP for file transfers
# Instance access is via SSM Session Manager only
resource "aws_network_acl_rule" "private_ingress_sftp" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 120
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_vpc.main.cidr_block
  from_port      = 22
  to_port        = 22
}

# ICMP ping for network troubleshooting and health checks
resource "aws_network_acl_rule" "private_ingress_icmp" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 125
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = aws_vpc.main.cidr_block
  icmp_type      = 8
  icmp_code      = 0
}

resource "aws_network_acl_rule" "private_ingress_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 130
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_egress_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Database subnets will use VPC default NACL
# Security provided by RDS security group (database.tf)
# Rationale: RDS security group already properly configured
# Database subnet isolation maintained by private subnet placement
# Removes 1 NACL to support shared VPC migration (5 NACL limit)
