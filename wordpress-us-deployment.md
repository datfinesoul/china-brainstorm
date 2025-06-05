# WordPress US Deployment - Day Two
**AWS Global (us-east-1) - Proven Pattern Replication**

## Project Overview

**Objective**: Deploy production-ready WordPress in AWS Global (us-east-1) using proven patterns from successful China deployment.

**Timeline**: Day Two - 6 hours for replication
**Foundation**: Validated architecture from China deployment

---

## Architecture Overview (Replicated from China)

```
┌─────────────────────────────────────────────────────────┐
│                AWS Global (us-east-1)                   │
├─────────────────────────────────────────────────────────┤
│ Internet                                                │
│    ↓                                                    │
│ CloudFront Distribution (no caching - pass through)     │
│    ↓                                                    │
│ Application Load Balancer (Public Subnets)             │
│    ↓                                                    │
│ Auto Scaling Group: 1x t3.medium (Private Subnet)      │
│                                                         │
│ RDS MySQL (Private Subnets, Multi-AZ)                  │
│                                                         │
│ Access: SSM Session Manager + SFTP (via VPN)           │
│ IAM: Identity Center (Global partition)                │
└─────────────────────────────────────────────────────────┘
```

### **Built on Day One Success**: China deployment patterns proven and ready to adapt
- **Architecture patterns** validated in China partition
- **Security configurations** tested and documented
- **Operational procedures** proven in production
- **CloudFront/ALB behaviors** documented with China-specific notes
- **WordPress configuration** patterns established

## Background & Context

### Stakeholder Requirements
- WordPress site successfully running in China (Day One complete)
- Need parallel deployment in US for global audience
- Maintain consistency with China deployment
- Leverage lessons learned from China deployment

### Technical Advantages from China Experience
- **Proven architecture** patterns from China deployment
- **Documented CloudFront behaviors** and caching strategies
- **Tested WordPress configurations** with ALB/CloudFront
- **Validated ASG/Launch Template** patterns
- **Known WordPress admin workflows** through infrastructure

## Day-Two Architecture (US Global, China-Proven)

### US Deployment Strategy (Enhanced with China Experience)
- **Compute**: Bitnami WordPress AMI via Launch Template + ASG (min/max: 1)
- **Database**: RDS MySQL (separate from compute for data persistence - same pattern as China)
- **Load Balancer**: Application Load Balancer (ALB) - same pattern as China
- **CDN**: CloudFront with no caching (pass-through only - consistent with China)
- **Access**: ALB public, SSM Session Manager + SFTP via VPN
- **IAM**: Identity Center permission sets (Global partition advantage)
- **Auto Scaling**: Manual instance refresh only (no automatic replacement - same as China)

### US Regional Architecture
```
┌─────────────────────────────────┐
│         AWS Global              │
│         us-east-1               │
├─────────────────────────────────┤
│ • CloudFront Distribution (no cache) │
│ • ALB (public subnets)          │
│ • ASG: 1x t3.medium (private)   │
│ • Launch Template               │
│ • RDS MySQL (private subnets)   │
│ • IAM Identity Center          │
│ • VPC: Public/Private subnets   │
│ • NAT Gateway                   │
│ • SSM VPC Endpoints + SFTP      │
└─────────────────────────────────┘
```

## Global Partition Advantages

### IAM Identity Center (Available in Global)
- **Centralized user management** (not available in China partition)
- **SSO integration** for stakeholder access
- **Permission sets** for different access levels
- **Cross-account access** if needed for future expansion

### Enhanced CloudFront Features
- **More edge locations** globally vs China
- **Additional security features** available in Global partition
- **Better integration** with other AWS Global services

### Service Availability
- **Full AWS service catalog** available in Global partition
- **Latest features** typically available in Global first
- **Better third-party integrations** in Global partition

## Day-Two Security (Global Production-Ready)
- ALB with security groups (HTTP/HTTPS public) - same as China
- EC2 instances in private subnets (no direct internet access)
- SSM Session Manager for secure admin access (via VPN)
- **IAM Identity Center permission sets** (Global advantage)
- CloudFront with enhanced security headers (Global features)
- Change default Bitnami application password
- **Advanced security patterns** consistent with China

## Day-Two Cost (US Global Region)
### US Region (USD/month)
- **EC2 t3.medium**: ~$30/month (slightly cheaper than China)
- **RDS db.t3.micro (Multi-AZ)**: ~$22/month
- **EBS Storage (default)**: ~$4/month
- **ALB**: ~$18/month
- **CloudFront**: ~$3-8/month (better pricing in Global)
- **NAT Gateway**: ~$12/month
- **Data Transfer**: ~$3/month
- **Total US region**: ~$92/month

### Combined Cost (China + US)
- **China region**: ~$110/month
- **US region**: ~$92/month  
- **Total both regions**: ~$202/month

## 🚨 PRINCIPAL DEVOPS ENGINEER RECOMMENDATIONS - US GLOBAL

### Leveraging China Experience for US Deployment

#### 1. **CloudFront Caching Strategy (China-Validated)**
**Apply China learnings - no caching approach**:
```
US Cache Behaviors (Consistent with China):
- `/*` → No caching (TTL: 0) - pass through all requests
- Headers: Forward all headers to origin
- Query strings: Forward all query strings
- Cookies: Forward all cookies
- Purpose: Edge distribution without cache complexity
```

#### 2. **Auto Scaling Group Configuration (Proven Pattern)**
```
ASG Settings (Identical to China):
- Min: 1, Max: 1, Desired: 1
- Health Check: EC2 only (disable ELB health checks for manual control)
- Health Check Grace Period: 300s
- Termination Policy: OldestInstance
- Instance Refresh: Manual trigger only
- Suspend: ReplaceUnhealthy process (prevent automatic replacement)
```

#### 3. **Database Strategy (Consistent with China)**
**US Day-Two**: RDS MySQL (separate US-only database, same architecture pattern as China)
**Independence**: US RDS instance completely isolated from China RDS
**Benefits**: 
- Data persistence across instance replacements
- Automated backups and point-in-time recovery
- Multi-AZ deployment for high availability
- Consistent dual-region database architecture (but separate instances)

#### 4. **IAM Identity Center Implementation**
**US Advantage**: Full Identity Center capabilities
**Strategy**: 
- Implement Identity Center for US stakeholder access
- Document patterns for potential China integration (when available)
- Maintain local IAM fallback for consistency

### Day-Two Risk Assessment - US Global

#### **LOW RISK** ✅ (Reduced from China experience)
- **Proven architecture patterns**: Validated in China production
- **Known CloudFront behaviors**: China testing provides baseline
- **Tested WordPress integration**: ALB/CloudFront patterns proven
- **Documented procedures**: SSM access, configuration workflows

#### **MEDIUM RISK** ⚠️ 
- **Global vs China differences**: CloudFront/ALB behavior variations
- **IAM Identity Center complexity**: New authentication pattern
- **Dual-region coordination**: Managing two WordPress instances

#### **MINIMAL RISK** ✅
- **Auto Scaling recovery**: Proven in China
- **Load balancer health**: ALB behavior consistent
- **WordPress configuration**: Patterns established

### China-to-US Adaptation Checklist

#### **Infrastructure Adaptations**
- [ ] Update Launch Template for us-east-1 AMI
- [ ] Configure VPC in us-east-1 (same pattern as China)
- [ ] Set up IAM Identity Center (Global partition feature)
- [ ] Adapt security groups for Global partition
- [ ] Configure CloudFront with Global optimizations

#### **Operational Consistency**
- [ ] Use same SSM access procedures as China
- [ ] Apply same backup strategies
- [ ] Implement consistent monitoring
- [ ] Use same update procedures

## DAY-TWO US DEPLOYMENT CHECKLIST

### Pre-Launch US (30 minutes - Faster due to China experience)
- [ ] Identify Bitnami WordPress AMI in us-east-1
- [ ] Create VPC with public/private subnets in us-east-1 (using China pattern)
- [ ] Set up NAT Gateway for private subnet access
- [ ] Configure IAM Identity Center permission sets
- [ ] Set up SSM VPC endpoints for private subnet access

### Infrastructure Setup US (3 hours - includes RDS setup)
- [ ] **Create Application Load Balancer (us-east-1)**:
  - [ ] Public subnets, internet-facing (same pattern as China)
  - [ ] Security group: HTTP/HTTPS from internet
  - [ ] Target group with health check path: `/`
  
- [ ] **Create CloudFront Distribution (Global)**:
  - [ ] Origin: ALB DNS name
  - [ ] No caching configuration (pass-through only - consistent with China)
  - [ ] Forward all headers, cookies, query strings
  - [ ] Enhanced security headers (Global features)
  
- [ ] **Create RDS MySQL Database (us-east-1)**:
  - [ ] db.t3.micro instance (Multi-AZ for availability) - US-specific
  - [ ] MySQL 8.0 engine, 20GB storage with auto-scaling
  - [ ] Private subnets only, database subnet group
  - [ ] Security group allowing access from EC2 instances
  - [ ] 7-day backup retention with automated snapshots
  - [ ] Note: Completely separate from China RDS instance
  
- [ ] **Create Launch Template (us-east-1)**:
  - [ ] Bitnami WordPress AMI (Global-specific)
  - [ ] t3.medium instance type
  - [ ] IAM role with SSM permissions
  - [ ] Security group for private subnet (ALB → EC2)
  - [ ] User data script adapted from China deployment

### Auto Scaling Group Setup US (45 minutes - Proven pattern)
- [ ] **US Region (us-east-1)**:
  - [ ] Create ASG with Launch Template (China-proven pattern)
  - [ ] Min/Max/Desired: 1/1/1
  - [ ] Private subnets, attach to ALB target group
  - [ ] Instance refresh settings: Rolling, 50% replacement

### Configuration & Testing Phase US (1.5 hours - Streamlined)
- [ ] **WordPress Configuration**:
  - [ ] Connect via SSM: `aws ssm start-session --target i-xxxxx --region us-east-1`
  - [ ] Get application password: `sudo cat /home/bitnami/bitnami_application_password`
  - [ ] Configure WordPress to use RDS MySQL database (update wp-config.php)
  - [ ] Test database connection and WordPress functionality
  - [ ] Configure WordPress to use ALB/CloudFront URLs
  - [ ] Access WordPress admin: `https://[CloudFront-Domain]/wp-admin`
  - [ ] Change admin password to stakeholder-known password
  - [ ] Create stakeholder admin account
  
- [ ] **US-Specific Testing**:
  - [ ] Verify ALB health checks pass (target group healthy)
  - [ ] Test CloudFront pass-through behavior (no caching)
  - [ ] Test WordPress admin functionality through CloudFront
  - [ ] Test IAM Identity Center access
  - [ ] Verify SSM access works from VPN in Global
  - [ ] Test SFTP access via VPN for file deployment
  - [ ] Cross-reference behavior with China deployment

### Handoff Documentation US (45 minutes)
- [ ] Document CloudFront URL for US region
- [ ] Document IAM Identity Center access procedures
- [ ] Update combined China+US troubleshooting guide
- [ ] Test stakeholder can access both WordPress sites
- [ ] Document performance/behavior differences between regions
- [ ] Plan dual-region operational procedures

### US Deployment Commands

```bash
# US-specific deployment commands
export AWS_REGION=us-east-1

# 1. Launch ASG with Launch Template (Global AMI)
# AMI ID for us-east-1 - use AWS marketplace Global

# 2. Connect to instance via SSM Session Manager
aws ssm start-session --target i-1234567890abcdef0 --region us-east-1

# 3. Get application password (once connected)
sudo cat /home/bitnami/bitnami_application_password

# 4. Configure WordPress for Global CloudFront/ALB
sudo /opt/bitnami/ctlscript.sh stop
# WordPress admin password changed via web interface
sudo /opt/bitnami/ctlscript.sh start
```

## Dual-Region Operations

### Managing Both Deployments
- **China WordPress**: `https://[china-cloudfront-domain]` (China RDS backend)
- **US WordPress**: `https://[us-cloudfront-domain]` (US RDS backend)
- **Database Isolation**: Each region has completely separate RDS instances
- **Admin Access**: IAM Identity Center (US) + Local IAM (China)
- **Monitoring**: Consistent CloudWatch dashboards both regions

### Week 2+ Improvements (Both Regions)
1. **Enhanced monitoring** and alerting for both China and US
2. **Coordinated backup strategy** across both separate RDS deployments
3. **Enhanced security** patterns applied to both regions
4. **Performance optimization** based on regional usage patterns
5. **Cross-region disaster recovery** planning (keeping databases separate)

## Emergency Contacts for US Deployment
- **DevOps Team Lead**: [Phone/Email]
- **AWS Support Global**: Enterprise/Business support case
- **VPN Access Issues**: [IT Contact] 
- **SSM Access Issues**: Check IAM roles, VPC endpoints
- **CloudFront Issues Global**: Check origin health, cache behaviors
- **ASG/ALB Issues**: Check target group health, security groups
- **IAM Identity Center Issues**: Check permission sets, user assignments
- **Bitnami Support**: Community forums (free tier)

---

**Status**: Day Two - Deploy US using China-proven patterns  
**Goal**: Functional WordPress in US + Dual-region operations
**Foundation**: China success enables rapid US deployment
