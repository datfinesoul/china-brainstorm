# WordPress China Deployment

Production-ready WordPress deployment for AWS China (cn-north-1) using OpenTofu.

## Architecture Overview

- **Compute**: Auto Scaling Group with Bitnami WordPress AMI
- **Database**: RDS MySQL 8.0 (separate from compute)
- **Load Balancer**: Application Load Balancer (ALB)
- **CDN**: CloudFront (optional, pass-through only)
- **Access**: SSM Session Manager + SFTP via VPN
- **Security**: WAF, Security Groups, NACLs
- **Monitoring**: CloudWatch Logs and Metrics

## Quick Start

### 1. Prerequisites

- OpenTofu/Terraform installed
- AWS CLI configured for China partition
- Access to AWS China account with appropriate permissions

### 2. Configuration

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit variables for your deployment
# Set domain_name if you have a domain, leave empty for ALB-only
vim terraform.tfvars
```

### 3. Deploy Infrastructure

```bash
# Initialize OpenTofu
tofu init

# Plan deployment
tofu plan

# Deploy infrastructure
tofu apply
```

### 4. Access WordPress

After deployment completes, get the WordPress URL:

```bash
# Get WordPress URL
tofu output wordpress_url

# Get WordPress admin URL
tofu output wordpress_admin_url
```

### 5. Initial WordPress Setup

Connect to the instance via SSM:

```bash
# Get instance ID from AWS Console or CLI
aws ec2 describe-instances --region cn-north-1 --filters "Name=tag:Name,Values=*wordpress*"

# Connect via SSM
aws ssm start-session --target i-XXXXXXXXX --region cn-north-1

# Get Bitnami application password
sudo cat /home/bitnami/bitnami_application_password
```

Access WordPress admin:
- URL: `http://your-alb-dns-name/wp-admin` (or your domain if configured)
- Username: `user`
- Password: (from the command above)

## Architecture Details

### Database Configuration

- **Engine**: MySQL 8.0
- **Instance**: db.t3.small (Multi-AZ)
- **Storage**: 20GB GP3 with auto-scaling
- **Backup**: 7-day retention
- **Security**: Private subnets only

### Auto Scaling Configuration

- **Min/Max/Desired**: 1/1/1 (manual control)
- **Instance Type**: t3.medium
- **Health Check**: EC2 only
- **Replace**: Manual instance refresh only

### Security Features

- Private subnets for compute and database
- Security groups with least privilege
- NACLs for additional network security
- SSM access only (no SSH keys)
- SFTP access via VPN
- Encrypted EBS volumes

### Load Balancer Setup

- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Health Check**: HTTP on port 80, path "/"
- **SSL**: Optional (if domain configured)

### CloudFront (Optional)

- **Purpose**: Global edge distribution
- **Caching**: Disabled (pass-through only)
- **SSL**: Uses ACM certificate
- **Behavior**: Forwards all headers, cookies, query strings

## Operational Procedures

### Manual Instance Refresh

```bash
# Start instance refresh (zero-downtime)
aws autoscaling start-instance-refresh \
    --auto-scaling-group-name wordpress-china-wordpress-asg \
    --region cn-north-1
```

### Database Management

```bash
# Database endpoint
tofu output database_endpoint

# Connect to database (from EC2 instance)
mysql -h <endpoint> -u wpuser -p wordpress
```

### File Management via SFTP

```bash
# Connect via SFTP over VPN
sftp bitnami@<instance-private-ip>

# WordPress files location
cd /opt/bitnami/wordpress/
```

### Monitoring and Logs

```bash
# View WordPress logs
aws logs describe-log-groups --region cn-north-1 | grep wordpress

# CloudWatch metrics
aws cloudwatch list-metrics --namespace AWS/ApplicationELB --region cn-north-1
```

## Cost Optimization

Current monthly costs (China region):
- EC2 t3.medium: ~$35
- RDS db.t3.small: ~$35
- ALB: ~$20
- CloudFront: ~$5-10
- EBS/Storage: ~$10
- **Total**: ~$105-115/month

## Security Hardening (Post-Deployment)

1. **WordPress Security**:
   - Change default admin password
   - Install security plugins
   - Regular updates

2. **Infrastructure Security**:
   - Enable WAF on ALB
   - Configure CloudTrail
   - Set up security monitoring

3. **Access Control**:
   - Use IAM Identity Center
   - Implement least privilege
   - Regular access reviews

## Troubleshooting

### Instance Not Healthy

```bash
# Check instance logs
aws ssm start-session --target i-XXXXXXXXX
sudo tail -f /var/log/wordpress-config.log
```

### Database Connection Issues

```bash
# Test database connectivity
wp db check --path=/opt/bitnami/wordpress --allow-root
```

### ALB Health Check Failures

```bash
# Check Apache status
sudo /opt/bitnami/ctlscript.sh status
sudo systemctl status bitnami
```

## Global Compatibility

This deployment is designed to work identically in AWS Global regions:

- Same architecture patterns
- Same security configurations  
- Same operational procedures
- Region-specific: AMI IDs, IAM ARNs, service availability

To deploy in Global regions:
1. Update `aws_region` variable
2. Update `availability_zones` for target region
3. Verify Bitnami AMI availability
4. Deploy using same process

## Support

- **AWS Support**: Use Business/Enterprise support for production issues
- **Bitnami Support**: Community forums for WordPress-specific issues
- **OpenTofu**: GitHub issues for infrastructure-as-code problems
