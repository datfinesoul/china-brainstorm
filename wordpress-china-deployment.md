# WordPress China Deployment - Day One
**AWS China (cn-north-1) - Production Ready**

## 🌍 GLOBAL COMPATIBILITY MANDATE

**CRITICAL**: All patterns, configurations, and decisions made for China deployment MUST be designed to work identically in AWS Global regions. This is not just a China deployment - it's a template for global WordPress deployment.

### Global Compatibility Requirements:
- Architecture patterns must work in both AWS partitions
- IAM Identity Center available in both China and Global regions
- CloudFront configurations must be portable (no caching strategy)
- Launch Templates must be region-agnostic with parameter substitution
- SFTP deployment procedures must work in both partitions
- All scripts and automation must work in both partitions

---

## Project Overview

**Objective**: Deploy production-ready WordPress in AWS China (cn-north-1) as the foundation for global WordPress deployment strategy.

**Timeline**: Day One - 8 hours for functional handoff
**Focus**: China market deployment with global-compatible patterns

### **Critical Requirement**: All China initiatives must be Global-compatible
- **Security configurations** must be portable across regions
- **IAM Identity Center** available in both China and Global partitions
- **Terraform** templates must support both partitions (CloudFormation only if absolutely needed)
- **Operational procedures** must be standardized across regions
- **SFTP deployment** via VPN must work in both regions

## Background & Context

### Stakeholder Requirements
- Needs manageable infrastructure solution
- **Priority**: China market focus with global-compatible patterns

### Technical Constraints - China Focus
- **AWS Lightsail not available in AWS China (cn-north-1)**
- VPN-only access via AWS SSM Session Manager and SFTP
- DevOps team has limited WordPress experience
- All solutions must be **replicable in other regions as needed**

## Day-One Architecture (China-First, Global-Ready)

### China Deployment Strategy
- **Compute**: Bitnami WordPress AMI via Launch Template + ASG (min/max: 1)
- **Database**: RDS MySQL (separate from compute for data persistence)
- **Load Balancer**: Application Load Balancer (ALB)
- **CDN**: CloudFront with NO caching (pass-through only)
- **Access**: ALB public, SSM Session Manager + SFTP via VPN
- **IAM**: Identity Center (available in China partition)
- **Auto Scaling**: Manual instance refresh only (no automatic replacement)

### China Regional Architecture
```
┌─────────────────────────────────┐
│         AWS China               │
│         cn-north-1              │
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

## Enhanced Architecture Benefits for Production
- ✅ **Zero-downtime deployments** via ASG instance refresh (manual trigger only)
- ⚠️ **Instance replacement** if needed (data preserved in RDS)
- ✅ **Load balancer health checks** ensure WordPress is responding
- ✅ **CloudFront edge distribution** with no caching (pass-through for dynamic content)
- ✅ **RDS MySQL database** ensures data persistence across instance changes
- ✅ **IAM Identity Center management** (available in China partition)
- ✅ **Launch Template versioning** for consistent deployments
- ✅ **SFTP deployment capability** via VPN for file management
- ✅ **Still zero WordPress knowledge required** - Bitnami handles all

### ASG Instance Refresh with 1/1/1 Configuration
**How Zero-Downtime Works with Min:1/Max:1/Desired:1:**
1. **Current State**: 1 instance running, connected to RDS database
2. **Manual Instance Refresh Triggered**: ASG temporarily increases Max to 2
3. **New Instance Launch**: ASG launches replacement instance (now 2 running)
4. **Database Connection**: New instance connects to same RDS database (data preserved)
5. **Health Check Wait**: New instance passes ALB health checks (300s grace period)
6. **Traffic Shift**: ALB starts routing traffic to healthy new instance
7. **Old Instance Termination**: ASG terminates old instance
8. **Final State**: 1 new instance running, all data preserved in RDS

**Result**: Zero downtime + Zero data loss - RDS ensures WordPress content persists

### RDS Database Benefits
- ✅ **Data persistence** across instance replacements
- ✅ **Automated backups** with point-in-time recovery
- ✅ **Multi-AZ deployment** for high availability
- ✅ **Automatic failover** for database layer
- ✅ **Separate scaling** of compute and database resources

## China-Specific Considerations

### CloudFront in China Region
- **No caching strategy** - pass-through configuration only
- **Edge distribution** for performance without cache complexity
- **Same behavior** as Global regions when no caching enabled

### IAM Identity Center in China
- **Full Identity Center support** available in China partition
- **Permission sets** for user management
- **Same patterns** as Global regions

### SFTP Access via VPN
- **File deployment** capability via SFTP over VPN
- **Direct file management** for themes, plugins, uploads
- **Same access patterns** for both China and Global regions

### Bitnami AMI Availability
- **Different AMI IDs** between China and Global partitions
- **Same functionality** but region-specific AMI required
- **Version consistency** may vary between partitions

## Day-One Security (China Production-Ready)
- ALB with security groups (HTTP/HTTPS public)
- EC2 instances in private subnets (no direct internet access)
- SSM Session Manager for secure admin access (via VPN)
- SFTP access for file deployment (via VPN)
- IAM Identity Center permission sets for user management
- CloudFront with no caching (pass-through security)
- Change default Bitnami application password
- **Advanced security moved to post-handoff (both regions)**

## Day-One Cost (China Region Only)
### China Region (USD/month)
- **EC2 t3.medium**: ~$35/month  
- **RDS db.t3.micro (Multi-AZ)**: ~$25/month
- **EBS Storage (default)**: ~$5/month
- **ALB**: ~$20/month
- **CloudFront**: ~$5-10/month (minimal traffic)
- **NAT Gateway**: ~$15/month
- **Data Transfer**: ~$5/month
- **Total China region**: ~$110/month

**Note**: Other region costs will be similar when deployed

## 🚨 PRINCIPAL DEVOPS ENGINEER RECOMMENDATIONS - CHINA FOCUS

### Critical Architecture Decisions for China Day One

#### 1. **CloudFront Distribution Strategy (No Caching)**
**Requirement**: Use **pass-through configuration** - no caching
```
China CloudFront Behaviors:
- `/*` → No caching (TTL: 0) - pass through all requests
- Headers: Forward all headers to origin
- Query strings: Forward all query strings  
- Cookies: Forward all cookies
- Purpose: Edge distribution without cache complexity
```

#### 2. **Auto Scaling Group Configuration (Manual Control)**
```
ASG Settings (Manual replacement only):
- Min: 1, Max: 1, Desired: 1
- Health Check: EC2 only (disable ELB health checks for manual control)
- Health Check Grace Period: 300s
- Termination Policy: OldestInstance
- Instance Refresh: Manual trigger only
- Suspend: ReplaceUnhealthy process (prevent automatic replacement)
- Note: Instance refresh requires manual trigger to prevent unwanted replacements
```

#### 3. **RDS Database Strategy (Data Persistence)**
**Day-One Solution**: RDS MySQL for China region data persistence
- **RDS Instance**: db.t3.micro (Multi-AZ for availability) - China-specific
- **Database Engine**: MySQL 8.0 (compatible with Bitnami WordPress)
- **Storage**: 20GB GP2 with auto-scaling enabled
- **Backup**: 7-day retention with automated snapshots
- **Security**: Private subnets only, security group from EC2
- **Isolation**: China RDS instance specific to China region
- **Benefits**: Data persists across instance replacements, automated backups

#### 4. **Database Strategy (Global-Compatible)**
**China Day-One**: RDS MySQL (separate China-only database for data persistence)
**Global Pattern**: Same RDS architecture can be replicated in other regions
**Independence**: Each region has its own isolated RDS instance and data
**Backup Strategy**: RDS automated backups + snapshots (portable pattern)

#### 5. **IAM Identity Center Strategy (Global-Compatible)**
**China (Day One)**: IAM Identity Center (fully supported in China partition)
**Global Pattern**: Same IAM patterns can be replicated in other AWS partitions
**Compatibility**: Identical IAM patterns work across regions

### Day-One Risk Assessment - China

#### **HIGH RISK** ⚠️
- **Cross-partition deployment**: Patterns not validated for Global
- **Manual instance refresh**: Requires proper testing in production

#### **MEDIUM RISK** ⚠️ 
- **Instance refresh complexity**: WordPress state during replacement
- **China-specific networking**: VPC patterns may differ
- **AMI version differences**: China vs Global AMI availability

#### **LOW RISK** ✅
- **Auto Scaling recovery**: Instance replacement works
- **Load balancer health**: ALB behavior consistent across partitions
- **SSM Session Manager**: Works reliably in China partition

### Global Compatibility Checklist

#### **Infrastructure Patterns (Must be Global-Compatible)**
- [ ] VPC design works in both partitions
- [ ] Security group patterns are portable
- [ ] Launch Template can be adapted for Global region
- [ ] ASG configuration is partition-agnostic
- [ ] ALB/CloudFront patterns work in both regions

#### **Operational Patterns (Must be Standardized)**
- [ ] SSM access procedures work in both partitions
- [ ] Backup strategies are consistent
- [ ] Monitoring approaches are portable
- [ ] Update procedures work in both regions

## TODAY ONLY - China Deployment Actions

### DAY-ONE CHINA DEPLOYMENT CHECKLIST

### Pre-Launch China (45 minutes)
- [ ] Identify Bitnami WordPress AMI in cn-north-1
- [ ] Create VPC with public/private subnets in cn-north-1
- [ ] Set up NAT Gateway for private subnet access
- [ ] Configure IAM Identity Center (full support in China partition)
- [ ] Set up SSM VPC endpoints for private subnet access
- [ ] Configure SFTP access over VPN

### Infrastructure Setup China (3.5 hours)
- [ ] **Create Application Load Balancer (cn-north-1)**:
  - [ ] Public subnets, internet-facing
  - [ ] Security group: HTTP/HTTPS from internet
  - [ ] Target group with health check path: `/`
  - [ ] Document pattern for global replication
  
- [ ] **Create CloudFront Distribution (China)**:
  - [ ] Origin: ALB DNS name
  - [ ] No caching configuration (pass-through only)
  - [ ] Forward all headers, cookies, query strings
  - [ ] Document pass-through behaviors
  
- [ ] **Create Launch Template (cn-north-1)**:
  - [ ] Bitnami WordPress AMI (China-specific)
  - [ ] t3.medium instance type
  - [ ] IAM role with SSM permissions
  - [ ] Security group for private subnet (ALB → EC2)
  - [ ] User data script for WordPress ALB configuration
  - [ ] **Document template for Global adaptation**

- [ ] **Create RDS MySQL Database (cn-north-1)**:
  - [ ] db.t3.micro instance (Multi-AZ for availability)
  - [ ] MySQL 8.0 engine, 20GB storage with auto-scaling
  - [ ] Private subnets only, database subnet group
  - [ ] Security group allowing access from EC2 instances
  - [ ] 7-day backup retention with automated snapshots
  - [ ] Document RDS pattern for global replication

### Auto Scaling Group Setup China (1 hour)
- [ ] **China Region (cn-north-1)**:
  - [ ] Create ASG with Launch Template
  - [ ] Min/Max/Desired: 1/1/1
  - [ ] Private subnets, attach to ALB target group
  - [ ] Instance refresh settings: Rolling, 50% replacement
  - [ ] **Document ASG pattern for US replication**

### Configuration & Testing Phase China (2 hours)
- [ ] **WordPress Configuration**:
  - [ ] Connect via SSM: `aws ssm start-session --target i-xxxxx --region cn-north-1`
  - [ ] Get application password: `sudo cat /home/bitnami/bitnami_application_password`
  - [ ] Configure WordPress to use RDS MySQL database (update wp-config.php)
  - [ ] Test database connection and WordPress functionality
  - [ ] Configure WordPress to use ALB/CloudFront URLs
  - [ ] Access WordPress admin: `https://[CloudFront-Domain]/wp-admin`
  - [ ] Change admin password to stakeholder-known password
  - [ ] Create stakeholder admin account
  
- [ ] **China-Specific Testing**:
  - [ ] Verify ALB health checks pass (target group healthy)
  - [ ] Test CloudFront pass-through behavior (no caching)
  - [ ] Test WordPress admin functionality through CloudFront
  - [ ] Verify SSM access works from VPN in China
  - [ ] Test SFTP access via VPN for file deployment
  - [ ] Verify IAM Identity Center access and permissions
  - [ ] **Document China-specific behaviors for global pattern documentation**

### Handoff Documentation China (1 hour)
- [ ] Document CloudFront URL for China region
- [ ] Document IAM Identity Center access procedures
- [ ] Document SFTP access procedures via VPN
- [ ] Document China-specific configurations
- [ ] Create troubleshooting guide (with Global patterns)
- [ ] Test stakeholder can log into China WordPress site
- [ ] **Document deployment patterns for global replication**

### China Deployment Commands

```bash
# China-specific deployment commands
export AWS_REGION=cn-north-1

# 1. Launch ASG with Launch Template (China AMI)
# AMI ID for cn-north-1 - use AWS marketplace China

# 2. Connect to instance via SSM Session Manager
aws ssm start-session --target i-1234567890abcdef0 --region cn-north-1

# 3. Get application password (once connected)
sudo cat /home/bitnami/bitnami_application_password

# 4. Configure WordPress for China CloudFront/ALB
sudo /opt/bitnami/ctlscript.sh stop
# WordPress admin password changed via web interface
sudo /opt/bitnami/ctlscript.sh start
```

## Post China-Handoff Preparation for US

### Immediate Actions After China Deployment
1. **Document China-specific learnings** for US deployment
2. **Note any CloudFront behavior differences** in China
3. **Validate Global-compatible patterns** work as expected
4. **Prepare US deployment templates** based on China experience

### Tomorrow: US Deployment Preparation
1. **Adapt Launch Template** for us-east-1 region
2. **Configure IAM Identity Center** for US region
3. **Test Global partition differences** in CloudFront/ALB behavior
4. **Deploy using proven China patterns**

## Emergency Contacts for China Deployment
- **DevOps Team Lead**: [Phone/Email]
- **AWS Support China**: Enterprise/Business support case
- **VPN Access Issues**: [IT Contact]
- **SSM Access Issues**: Check IAM Identity Center permissions, VPC endpoints
- **SFTP Access Issues**: Check VPN connection, file permissions
- **CloudFront Issues China**: Check origin health, pass-through configuration
- **ASG/ALB Issues**: Check target group health, security groups
- **IAM Identity Center Issues**: Check permission sets, user assignments
- **Bitnami Support**: Community forums (free tier)

---

**Status**: URGENT - Deploy China Today
**Goal**: Functional WordPress in China + Global-compatible patterns
**Next**: US deployment tomorrow using proven patterns
