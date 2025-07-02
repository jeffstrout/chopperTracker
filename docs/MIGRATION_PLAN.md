# ChopperTracker AWS Account Migration Plan

## Overview
Migrate all application resources from main account (958933162000) to ChopperTracker org account (038342322731).

## Current State

### Main Account (958933162000)
- S3: flight-tracker-web-ui-1750266711
- ECR: flight-tracker-backend
- ECS: flight-tracker-cluster, flight-tracker-backend service
- ALB: flight-tracker-alb
- VPC: Default VPC with security groups
- ElastiCache: flight-tracker-redis (if exists)
- Route 53: choppertracker.com domain (KEEP HERE)

### ChopperTracker Account (038342322731)
- IAM User: choppertracker-github-deploy
- Currently empty of application resources

## Migration Steps

### Phase 1: Prepare ChopperTracker Account
1. Create S3 bucket for frontend
2. Create ECR repository  
3. Set up VPC and security groups
4. Create ALB

### Phase 2: Deploy Application
1. Push Docker images to new ECR
2. Create ECS cluster and service
3. Deploy frontend to new S3 bucket
4. Test application functionality

### Phase 3: Update DNS
1. Update Route 53 to point to new ALB
2. Update CNAME records as needed
3. Test domain resolution

### Phase 4: Cleanup Old Resources
1. Stop old ECS service
2. Delete old resources (keeping backups)
3. Update documentation

## Resource Naming Convention
All resources in ChopperTracker account will use consistent naming:
- S3: `choppertracker-frontend`
- ECR: `choppertracker-backend`
- ECS Cluster: `choppertracker-cluster`
- ECS Service: `choppertracker-backend`
- ALB: `choppertracker-alb`
- Log Group: `/ecs/choppertracker`

## Benefits
1. Single account deployment - no cross-account complexity
2. Simplified IAM permissions
3. Better cost tracking
4. Full control in ChopperTracker org
5. Cleaner GitHub Actions workflow