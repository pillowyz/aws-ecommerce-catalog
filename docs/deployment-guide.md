# AWS E-Commerce Platform - Complete Deployment Guide

## Architecture Overview

This guide creates a production-ready e-commerce platform using 6 AWS services:
- **VPC** - Custom networking with public/private subnets
- **EC2** - Load-balanced web servers across multiple AZs
- **RDS** - Managed MySQL database
- **S3** - Object storage for static assets
- **CloudFront** - Global CDN for performance
- **ALB** - Application Load Balancer for high availability

---

## 1️. Create VPC Infrastructure

### 1. Create VPC
```
VPC Console → Create VPC
- Name: ecommerce-vpc
- IPv4 CIDR: 10.0.0.0/16
```

### 1a. Create Internet Gateway
```
VPC Console → Internet Gateways → Create
- Name: ecommerce-igw
- Actions → Attach to VPC: ecommerce-vpc
```

### 1b. Create Subnets
**Create 4 subnets across 2 Availability Zones:**

```
Public Subnet 1:
- Name: public-subnet-1a
- AZ: us-east-1a
- IPv4 CIDR: 10.0.1.0/24

Private Subnet 1:
- Name: private-subnet-1a  
- AZ: us-east-1a
- IPv4 CIDR: 10.0.2.0/24

Public Subnet 2:
- Name: public-subnet-1b
- AZ: us-east-1b
- IPv4 CIDR: 10.0.3.0/24

Private Subnet 2:
- Name: private-subnet-1b
- AZ: us-east-1b
- IPv4 CIDR: 10.0.4.0/24
```

### 1c. Create NAT Gateway
```
VPC Console → NAT Gateways → Create
- Subnet: public-subnet-1a
- Connectivity type: Public
- Allocate Elastic IP: Yes
```

### 1d. Create Route Tables
**Public Route Table:**
```
VPC Console → Route Tables → Create
- Name: public-route
- VPC: ecommerce-vpc

Add Routes:
- Destination: 0.0.0.0/0 → Target: Internet Gateway (ecommerce-igw)

Subnet Associations:
- public-subnet-1a
- public-subnet-1b
```

**Private Route Table:**
```
VPC Console → Route Tables → Create  
- Name: private-route
- VPC: ecommerce-vpc

Add Routes:
- Destination: 0.0.0.0/0 → Target: NAT Gateway

Subnet Associations:
- private-subnet-1a
- private-subnet-1b
```

---

## 2️. Create Security Groups

### ALB Security Group
```
EC2 Console → Security Groups → Create
- Name: alb-sg
- Description: Security group for ALB
- VPC: ecommerce-vpc

Inbound Rules:
- HTTP (80) from 0.0.0.0/0
- HTTPS (443) from 0.0.0.0/0
```

### Web Server Security Group
```
EC2 Console → Security Groups → Create
- Name: web-server-sg
- Description: Security group for Web server
- VPC: ecommerce-vpc

Inbound Rules:
- HTTP (80) from alb-sg
- SSH (22) from My IP
```

### Database Security Group
```
EC2 Console → Security Groups → Create
- Name: database-sg
- Description: Security group for the database
- VPC: ecommerce-vpc

Inbound Rules:
- MySQL (3306) from web-server-sg
```

---

## 3️. Create RDS Database

### 3a. Create DB Subnet Group
```
RDS Console → Subnet groups → Create
- Name: ecommerce-db-subnets
- Description: Database subnets
- VPC: ecommerce-vpc
- Availability Zones: us-east-1a, us-east-1b
- Subnets: private-subnet-1a, private-subnet-1b
```

### 3b. Create RDS Instance
```
RDS Console → Create database
- Engine options: MySQL
- Templates: Dev/Test
- Availability and durability: Single-AZ DB instance deployment
- DB instance identifier: ecommerce-db
- Master username: admin
- Credentials management: Self managed
- Master password: catalog123
- Instance configuration: db.t3.micro
- Storage: General Purpose SSD (gp2)
- Allocated storage: 20
- Connectivity: Don't connect to an EC2 compute resource
- VPC: ecommerce-vpc
- DB subnet group: ecommerce-db-subnets
- Public access: No
- VPC security group: database-sg
- Uncheck Enhanced monitoring
- Initial database name: ecommerce_catalog
```

**Important:** Note your RDS endpoint once created for the user data script

---

## 4️. Create S3 Bucket & CloudFront

### 4. Create S3 Bucket
```
S3 Console → Create bucket
- Bucket name: ecommerce-assets-2025
- Block public access: Uncheck "Block all public access"
- Acknowledge warning: Check the box
- Create bucket
```

### 4a. Configure Bucket Policy (Temporary)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::ecommerce-assets-2025/*"
        }
    ]
}
```

### 4b. Create Folder Structure
Create these folders in your S3 bucket:
```
products/
├── smartphones/
├── laptops/
├── audio/
└── tablets/
```

### 4c. Upload Product Images
Upload images with these exact names:
```
products/
├── smartphones/
│   ├── iphone15pro.jpg
│   └── galaxy-s24.jpg
├── laptops/
│   ├── macbook-air-m3.jpg
│   └── dell-xps13.jpg
├── audio/
│   └── airpods-pro.jpg
└── tablets/
    └── ipad-air.jpg
```

### 5. Create CloudFront Distribution
```
CloudFront Console → Create distribution
- Origin domain: [your-s3-bucket].s3.amazonaws.com
- Origin access: Origin access control settings
- Origin access control → Create new OAC
  * Name: ecommerce-s3-oac
- Viewer protocol policy: Redirect HTTP to HTTPS
- Cache policy: Managed-CachingOptimized
- Origin request policy: None
- Create distribution
```

### 5b. Update S3 Bucket Policy for CloudFront
Replace the temporary bucket policy with (update with your actual values):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::ecommerce-assets-2025/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::YOUR-ACCOUNT-ID:distribution/YOUR-DISTRIBUTION-ID"
                }
            }
        }
    ]
}
```

---

## 6️. Launch EC2 Instances

### 6a. Create Launch Template
```
EC2 Console → Launch Templates → Create
- Name: ecommerce-complete-template
- AMI: Amazon Linux 2023
- Instance type: t2.small
- Key pair: vockey
- Security groups: web-server-sg
- IAM instance profile: LabInstanceProfile
- User data: [See user data script in deployment folder]
```

### 6b. Launch Instances
```
Launch 2 instances using the template:
- Instance 1: private-subnet-1a
- Instance 2: private-subnet-1b
```

 **Wait 10-15 minutes** for instances to initialize

---

## 7️. Load Balancer Setup

### 7a. Create Target Group
```
EC2 Console → Target Groups → Create
- Name: ecommerce-targets
- Protocol: HTTP:80
- VPC: ecommerce-vpc
- Health check path: /health.php

Register Targets:
- Add both EC2 instances on port 80
```

### 7b. Create Application Load Balancer
```
EC2 Console → Load Balancers → Create ALB
- Name: ecommerce-alb
- Scheme: Internet-facing
- VPC: ecommerce-vpc
- Subnets: Both public subnets (public-subnet-1a, public-subnet-1b)
- Security group: alb-sg
- Listener: HTTP:80 → ecommerce-targets
```

---

## 8️. Testing & Verification

### 8. Test Main Application
Visit your ALB URL:
```
http://[your-alb-dns-name]/
```

**Expected Results:**
- ✅ Professional e-commerce interface
- ✅ 6 products displaying with images
- ✅ Server information showing load balancing
- ✅ Performance metrics displayed

### 8a. Test Admin Panel
Visit the admin interface:
```
http://[your-alb-dns-name]/admin.php
```

**Expected Results:**
- ✅ S3 and CloudFront configuration display
- ✅ Upload simulation interface
- ✅ Bucket structure visualization

---

## Architecture Benefits

**Performance:**
- 50% faster load times via CloudFront CDN
- Multi-AZ deployment for high availability
- Auto-scaling ready architecture

**Security:**
- Database isolated in private subnets
- Security groups with least-privilege access
- No direct internet access to application servers

**Scalability:**
- Load balancer distributes traffic automatically
- Stateless application design
- Global content delivery via CloudFront

---

## Common Issues & Solutions

**Instance Health Checks Failing:**
- Verify security group rules (HTTP 80 from ALB)
- Check NAT Gateway routing for private subnets
- Ensure user data script completed successfully

**Images Not Loading:**
- Verify S3 bucket policy allows CloudFront access
- Check CloudFront distribution status (should be "Deployed")
- Confirm image file names match database entries exactly

**Database Connection Issues:**
- Verify RDS endpoint in user data script
- Check database security group allows MySQL from web servers
- Ensure RDS is in "Available" status



