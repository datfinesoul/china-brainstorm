# WordPress China Deployment - Compute Resources
# AWS China (cn-north-1) - EC2 Launch Template and Auto Scaling

# Data source to find the latest Bitnami WordPress AMI in China
data "aws_ami" "bitnami_wordpress" {
  most_recent = true
  owners      = ["679593333241"] # Bitnami's AWS account ID

  filter {
    name   = "name"
    values = ["bitnami-wordpress-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# IAM Role for EC2 instances (SSM access)
resource "aws_iam_role" "wordpress_instance" {
  name_prefix        = "wordpress-instance-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "wordpress-instance-role"
    Purpose = "IAM role for WordPress EC2 instances with SSM access"
  }
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "wordpress_ssm" {
  role       = aws_iam_role.wordpress_instance.name
  policy_arn = "arn:aws-cn:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for the IAM role
resource "aws_iam_instance_profile" "wordpress_instance" {
  name_prefix = "wordpress-instance-"
  role        = aws_iam_role.wordpress_instance.name

  tags = {
    Name    = "wordpress-instance-profile"
    Purpose = "Instance profile for WordPress EC2 instances"
  }
}

# Launch Template for WordPress instances
resource "aws_launch_template" "wordpress" {
  name_prefix   = "${var.project_name}-wordpress-"
  description   = "Launch template for WordPress instances with Bitnami AMI"
  image_id      = data.aws_ami.bitnami_wordpress.id
  instance_type = "t3.medium"

  # Security
  vpc_security_group_ids = [aws_security_group.wordpress.id]
  
  # IAM instance profile for SSM access
  iam_instance_profile {
    name = aws_iam_instance_profile.wordpress_instance.name
  }

  # Storage configuration
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # User data script for WordPress configuration
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_host     = aws_db_instance.wordpress.endpoint
    db_name     = aws_db_instance.wordpress.db_name
    db_username = aws_db_instance.wordpress.username
    secret_arn  = aws_secretsmanager_secret.db_password.arn
    region      = var.aws_region
  }))

  # Instance metadata options (IMDSv2)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }

  # Monitoring
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-wordpress"
      Purpose = "WordPress application server"
      Type    = "web-server"
    }
  }

  tags = {
    Name    = "${var.project_name}-wordpress-template"
    Purpose = "Launch template for WordPress instances"
  }
}

# Auto Scaling Group for WordPress
resource "aws_autoscaling_group" "wordpress" {
  name                = "${var.project_name}-wordpress-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.wordpress.arn]
  health_check_type   = "EC2"
  health_check_grace_period = 300

  # Manual control configuration (1/1/1)
  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup       = 300
    }
  }

  # Suspend automatic replacement processes for manual control
  suspended_processes = ["ReplaceUnhealthy"]

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  # Instance protection for manual control
  protect_from_scale_in = true

  tag {
    key                 = "Name"
    value               = "${var.project_name}-wordpress-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Purpose"
    value               = "Auto Scaling Group for WordPress instances"
    propagate_at_launch = false
  }
}
