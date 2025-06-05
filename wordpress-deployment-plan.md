# WordPress Dual Deployment Plan - AWS China & Global

## Project Overview

**Objective**: Deploy WordPress websites in both AWS China (cn-north-1) and AWS Global (us-east-1) regions to serve different geographic audiences while maintaining consistency and manageability.

**Current Date**: June 5, 2025

## Background & Context

### Stakeholder Requirements
- Originally wanted AWS Lightsail for simplicity
- Lightly technical background, minimal security awareness
- Needs manageable infrastructure solution
- Must serve audiences in both China and US

### Technical Constraints
- **AWS Lightsail not available in AWS China (cn-north-1)**
- Must work across AWS partitions (China vs Global)
- VPN-only access via AWS SSM Session Manager
- DevOps team has limited WordPress experience
- Stakeholder will manage day-to-day operations

## Day-One Architecture (Enhanced for Production)

### Updated Deployment Strategy
- **Compute**: Bitnami WordPress AMI via Launch Template + ASG (min/max: 1)
- **Database**: Built-in MySQL (migrate to RDS week 2)
- **Load Balancer**: Application Load Balancer (ALB)
- **CDN**: CloudFront with minimal caching (static assets only)
- **Access**: ALB public, SSM Session Manager for admin
- **IAM**: Identity Center permission sets for user access
- **Auto Scaling**: Instance refresh pattern for zero-downtime updates

### Day-One Regional Strategy (Revised)
```
┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│         AWS China               │    │         AWS Global              │
│         cn-north-1              │    │         us-east-1               │
├─────────────────────────────────┤    ├─────────────────────────────────┤
│ • CloudFront Distribution       │    │ • CloudFront Distribution       │
│ • ALB (public subnets)          │    │ • ALB (public subnets)          │
│ • ASG: 1x t3.medium (private)   │    │ • ASG: 1x t3.medium (private)   │
│ • Launch Template               │    │ • Launch Template               │
│ • Built-in MySQL               │    │ • Built-in MySQL               │
│ • IAM Identity Center          │    │ • IAM Identity Center          │
└─────────────────────────────────┘    └─────────────────────────────────┘
```

## Enhanced Architecture Benefits for Production
- ✅ **Zero-downtime deployments** via ASG instance refresh
- ✅ **Auto-recovery** if instance fails (ASG replaces automatically)
- ✅ **Load balancer health checks** ensure WordPress is responding
- ✅ **CloudFront edge caching** improves global performance
- ✅ **IAM Identity Center** for centralized user management
- ✅ **Launch Template versioning** for consistent deployments
- ✅ **Still zero WordPress knowledge required** - Bitnami handles all

## Day-One Security (Production-Ready)
- ALB with security groups (HTTP/HTTPS public)
- EC2 instances in private subnets (no direct internet access)
- SSM Session Manager for secure admin access (via VPN)
- IAM Identity Center permission sets for user management
- CloudFront with basic security headers
- Change default Bitnami application password
- **Advanced security moved to post-handoff**

## Day-One Cost (Updated for Production Architecture)
### Per Region (USD/month)
- **EC2 t3.medium**: ~$35/month  
- **EBS Storage (default)**: ~$5/month
- **ALB**: ~$20/month
- **CloudFront**: ~$5-10/month (minimal traffic)
- **Data Transfer**: ~$5/month
- **Total per region**: ~$70/month
- **Both regions**: ~$140/month (still no RDS costs)

### **Timeline**: ONE DAY for functional WordPress handoff

### Minimal Viable Deployment (MVP)
**Goal**: Get working WordPress sites in both regions with zero WordPress learning required

### Day-One Deployment Plan (10 hours - Updated)

#### Hour 1-3: Enhanced AWS Foundation
- Create VPC with public/private subnets (if not existing)
- Set up NAT Gateway for private subnet internet access
- Create security groups: ALB (public), EC2 (private), CloudFront
- Set up IAM Identity Center permission sets
- Create SSM VPC endpoints (for private subnet access)

#### Hour 4-5: Load Balancer & CloudFront Setup
- Create Application Load Balancer in public subnets
- Set up target group with health checks for WordPress
- Create CloudFront distribution with ALB as origin
- Configure minimal caching (static assets: css, js, images only)

#### Hour 6-7: Launch Template & Auto Scaling
- Create Launch Template with Bitnami WordPress AMI
- Include user data for basic configuration
- Create Auto Scaling Group (min: 1, max: 1, desired: 1)
- Configure instance refresh settings for zero-downtime updates

#### Hour 8-9: WordPress Configuration
- Connect via SSM to configure WordPress
- Point WordPress to use ALB/CloudFront URLs
- Set up basic admin user for stakeholder
- Test end-to-end functionality

#### Hour 10: Testing & Handoff
- Verify ALB health checks pass
- Test CloudFront caching behavior
- Document all URLs, credentials, access methods
- **DONE** - Production-ready WordPress deployment

### Zero-Learning Deployment Commands

```bash
# 1. Launch instance with Bitnami WordPress AMI
# AMI ID varies by region - use AWS marketplace
# Ensure instance has SSM role attached

# 2. Connect to instance via SSM Session Manager
aws ssm start-session --target i-1234567890abcdef0

# 3. Get application password (once connected)
sudo cat /home/bitnami/bitnami_application_password

# 4. Change default password
sudo /opt/bitnami/ctlscript.sh stop
sudo passwd # Change system password
# WordPress admin password changed via web interface
sudo /opt/bitnami/ctlscript.sh start
```

## Post-Handoff Technical Debt (DO LATER)
1. **Week 2**: Migrate to RDS
2. **Week 3**: Add load balancer, SSL  
3. **Week 4**: Backup strategy
4. **Week 5**: Security hardening

## Day-One Handoff Requirements

### Stakeholder Handoff (30 minutes)
- WordPress admin URL: `http://[IP]/wp-admin`
- Admin username/password
- Emergency contact info
- **That's it - stakeholder is ready to go**

## Day-One Risks (Acceptable for Handoff)

### Immediate Risks - Day One
- **Risk**: No time for WordPress learning
  - **Mitigation**: Use Bitnami AMI "as-is" - zero config needed ✅
- **Risk**: Basic security only
  - **Mitigation**: Acceptable for day-one handoff ✅
- **Risk**: Single point of failure (no RDS)
  - **Mitigation**: Fix in week 2 - not blocking handoff ✅

## 🚨 PRINCIPAL DEVOPS ENGINEER RECOMMENDATIONS

### Critical Architecture Decisions for Day One

#### 1. **CloudFront Caching Strategy** 
**Recommendation**: Use **conservative caching** to avoid WordPress admin issues
```
Cache Behaviors:
- `/wp-admin/*` → No caching (TTL: 0)
- `/wp-content/uploads/*` → Cache for 24h (images, media)
- `*.css, *.js` → Cache for 1h (themes, plugins)
- `/` → No caching initially (dynamic content)
```

#### 2. **Auto Scaling Group Configuration**
**Recommendation**: Use **instance refresh** instead of standard scaling
```
ASG Settings:
- Min: 1, Max: 1, Desired: 1
- Instance Refresh: Rolling replacement
- Health Check: ELB + EC2 (300s grace period)
- Termination Policy: OldestInstance
```

#### 3. **WordPress Persistent Data Challenge**
**Critical Issue**: WordPress uploads, themes, plugins stored on EBS
**Day-One Solution**: 
- Accept single-instance risk for handoff
- **Week 2**: Implement EFS for shared storage OR S3 offloading
- **Alternative**: Use WordPress multisite with shared uploads

#### 4. **Database Considerations**
**Risk Assessment**: Built-in MySQL on same instance
**Mitigation Strategy**:
- Daily EBS snapshots (automated)
- MySQL backup to S3 (via cron)
- **Week 2**: Migrate to RDS with zero-downtime

#### 5. **Cross-Partition Complexity**
**China vs Global Challenges**:
- IAM Identity Center not available in China partition
- CloudFront behavior differences in China
- Different AMI IDs between partitions

**Recommendations**:
- Use **separate IAM Identity Center** in Global, local IAM in China
- Test CloudFront caching behavior in China region specifically
- Create **region-specific** Launch Templates

### Day-One Risk Assessment

#### **HIGH RISK** ⚠️
- **Single point of failure**: Instance + database on same host
- **Data persistence**: Uploads/themes lost on instance replacement
- **No automated backups**: Built-in MySQL not backed up

#### **MEDIUM RISK** ⚠️ 
- **Instance refresh complexity**: WordPress state during replacement
- **CloudFront cache invalidation**: May need manual purging
- **Cross-partition differences**: China-specific behaviors

#### **LOW RISK** ✅
- **Auto Scaling recovery**: Instance replacement works
- **Load balancer health**: ALB will detect failed instances
- **Access management**: IAM Identity Center handles permissions

### Recommended Compromises for Day One

1. **Accept single-instance risk** → Fix with EFS/S3 in week 2
2. **Minimal CloudFront caching** → Expand after testing
3. **Manual backup strategy** → Automate with RDS migration
4. **Basic monitoring only** → Enhanced monitoring week 3

---

**Status**: URGENT - Deploy Today
**Goal**: Functional WordPress handoff only

## DAY-ONE DEPLOYMENT CHECKLIST

### Pre-Launch (45 minutes)
- [ ] Identify Bitnami WordPress AMI in both regions
- [ ] Create VPC with public/private subnets (if needed)
- [ ] Set up NAT Gateway for private subnet access
- [ ] Create IAM Identity Center permission sets
- [ ] Set up SSM VPC endpoints for private subnet access

### Infrastructure Setup (3 hours)
- [ ] **Create Application Load Balancer**:
  - [ ] Public subnets, internet-facing
  - [ ] Security group: HTTP/HTTPS from internet
  - [ ] Target group with health check path: `/`
  
- [ ] **Create CloudFront Distribution**:
  - [ ] Origin: ALB DNS name
  - [ ] Cache behavior: Static assets only (css, js, images)
  - [ ] No caching for `/wp-admin/*`
  
- [ ] **Create Launch Template**:
  - [ ] Bitnami WordPress AMI
  - [ ] t3.medium instance type
  - [ ] IAM role with SSM permissions
  - [ ] Security group for private subnet (ALB → EC2)
  - [ ] User data script for WordPress ALB configuration

### Auto Scaling Group Setup (1 hour)
- [ ] **China Region (cn-north-1)**:
  - [ ] Create ASG with Launch Template
  - [ ] Min/Max/Desired: 1/1/1
  - [ ] Private subnets, attach to ALB target group
  - [ ] Instance refresh settings: Rolling, 50% replacement
  
- [ ] **US Region (us-east-1)**:
  - [ ] Create ASG with Launch Template
  - [ ] Min/Max/Desired: 1/1/1
  - [ ] Private subnets, attach to ALB target group
  - [ ] Instance refresh settings: Rolling, 50% replacement

### Configuration & Testing Phase (2 hours)
- [ ] **WordPress Configuration**:
  - [ ] Connect via SSM: `aws ssm start-session --target i-xxxxx`
  - [ ] Get application password: `sudo cat /home/bitnami/bitnami_application_password`
  - [ ] Configure WordPress to use ALB/CloudFront URLs
  - [ ] Access WordPress admin: `https://[CloudFront-Domain]/wp-admin`
  - [ ] Change admin password to stakeholder-known password
  - [ ] Create stakeholder admin account
  
- [ ] **End-to-End Testing**:
  - [ ] Verify ALB health checks pass (target group healthy)
  - [ ] Test CloudFront static asset caching
  - [ ] Test WordPress admin functionality through CloudFront
  - [ ] Verify SSM access to instances in both regions
  - [ ] Test instance refresh process (optional but recommended)

### Handoff Documentation (1 hour)
- [ ] Document CloudFront URLs for both regions
- [ ] Document all usernames, passwords, access methods
- [ ] Provide IAM Identity Center access instructions
- [ ] Create basic troubleshooting guide
- [ ] Test stakeholder can log into both WordPress sites
- [ ] Schedule post-handoff improvements meeting

### Emergency Contacts for Production Deployment
- **DevOps Team Lead**: [Phone/Email]
- **AWS Support**: Enterprise/Business support case
- **VPN Access Issues**: [IT Contact]
- **SSM Access Issues**: Check IAM roles, VPC endpoints
- **CloudFront Issues**: Check origin health, cache behaviors
- **ASG/ALB Issues**: Check target group health, security groups
- **Bitnami Support**: Community forums (free tier)
