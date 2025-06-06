# WordPress China Deployment - Load Balancer
# AWS China (cn-north-1) - Application Load Balancer and CloudFront

# Application Load Balancer
resource "aws_lb" "wordpress" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name    = "${var.project_name}-alb"
    Purpose = "Application Load Balancer for WordPress"
    Type    = "load-balancer"
  }
}

# ALB Target Group for WordPress
resource "aws_lb_target_group" "wordpress" {
  name     = "${var.project_name}-wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200,301,302"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name    = "${var.project_name}-wordpress-tg"
    Purpose = "Target group for WordPress instances"
  }
}

# ALB Listener for HTTP (direct traffic instead of redirect)
resource "aws_lb_listener" "wordpress_http" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }

  tags = {
    Name    = "${var.project_name}-alb-http-listener"
    Purpose = "HTTP listener for WordPress traffic"
  }
}

# ALB Listener for HTTPS (conditional on domain_name)
# Commented out until domain is ready
# resource "aws_lb_listener" "wordpress_https" {
#   count = var.domain_name != "" ? 1 : 0
#   
#   load_balancer_arn = aws_lb.wordpress.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = aws_acm_certificate_validation.wordpress[0].certificate_arn
# 
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.wordpress.arn
#   }
# 
#   tags = {
#     Name    = "${var.project_name}-alb-https-listener"
#     Purpose = "HTTPS listener for WordPress traffic"
#   }
# }

# ACM Certificate for HTTPS (conditional on domain_name)
# Commented out until domain is ready
# resource "aws_acm_certificate" "wordpress" {
#   count = var.domain_name != "" ? 1 : 0
#   
#   domain_name       = var.domain_name
#   validation_method = "DNS"
# 
#   subject_alternative_names = [
#     "*.${var.domain_name}"
#   ]
# 
#   lifecycle {
#     create_before_destroy = true
#   }
# 
#   tags = {
#     Name    = "${var.project_name}-certificate"
#     Purpose = "SSL certificate for WordPress domain"
#   }
# }

# Certificate validation (requires DNS records to be created manually)
# Commented out until domain is ready
# resource "aws_acm_certificate_validation" "wordpress" {
#   count = var.domain_name != "" ? 1 : 0
#   
#   certificate_arn = aws_acm_certificate.wordpress[0].arn
#   
#   timeouts {
#     create = "5m"
#   }
# }

# CloudFront Distribution (Pass-through, no caching)
# Commented out until domain is ready
# resource "aws_cloudfront_distribution" "wordpress" {
#   count = var.domain_name != "" ? 1 : 0
#   
#   origin {
#     domain_name = aws_lb.wordpress.dns_name
#     origin_id   = "${var.project_name}-alb"
# 
#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "https-only"
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
#   }
# 
#   enabled = true
#   aliases = [var.domain_name]
# 
#   # Pass-through caching behavior (no caching)
#   default_cache_behavior {
#     allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
#     cached_methods         = ["GET", "HEAD"]
#     target_origin_id       = "${var.project_name}-alb"
#     compress               = true
#     viewer_protocol_policy = "redirect-to-https"
# 
#     # No caching configuration
#     forwarded_values {
#       query_string = true
#       headers      = ["*"]
#       
#       cookies {
#         forward = "all"
#       }
#     }
#     
#     min_ttl     = 0
#     default_ttl = 0
#     max_ttl     = 0
#   }
# 
#   # Price class for China region
#   price_class = "PriceClass_All"
# 
#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }
# 
#   viewer_certificate {
#     acm_certificate_arn      = aws_acm_certificate_validation.wordpress[0].certificate_arn
#     ssl_support_method       = "sni-only"
#     minimum_protocol_version = "TLSv1.2_2021"
#   }
# 
#   tags = {
#     Name    = "${var.project_name}-cloudfront"
#     Purpose = "CloudFront distribution for WordPress (pass-through, no caching)"
#     Type    = "cdn"
#   }
# }


