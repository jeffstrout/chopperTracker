#!/bin/bash
# Setup all infrastructure in ChopperTracker account (038342322731)
# This script creates all necessary AWS resources for the application

set -e

echo "🚁 Setting up ChopperTracker infrastructure..."
echo "Account: 038342322731"
echo "Region: us-east-1"

# Verify we're in the correct account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "038342322731" ]; then
    echo "❌ ERROR: Not in ChopperTracker account. Current account: $CURRENT_ACCOUNT"
    echo "Please configure AWS credentials for account 038342322731"
    exit 1
fi

echo "✅ Confirmed ChopperTracker account"

# Set variables
export AWS_REGION="us-east-1"
export PROJECT_NAME="choppertracker"

# 1. Create S3 bucket for frontend
echo ""
echo "📦 Creating S3 bucket..."
BUCKET_NAME="${PROJECT_NAME}-frontend"
if aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
    echo "Bucket $BUCKET_NAME already exists"
else
    aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION
    echo "Created bucket: $BUCKET_NAME"
fi

# Configure bucket for static website hosting
aws s3api put-bucket-website \
    --bucket $BUCKET_NAME \
    --website-configuration '{
        "IndexDocument": {"Suffix": "index.html"},
        "ErrorDocument": {"Key": "error.html"}
    }'

# Set bucket policy for public read
cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
        }
    ]
}
EOF
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file:///tmp/bucket-policy.json

# Disable ACLs (use bucket policies instead)
aws s3api put-bucket-ownership-controls \
    --bucket $BUCKET_NAME \
    --ownership-controls Rules='[{ObjectOwnership=BucketOwnerEnforced}]'

echo "✅ S3 bucket configured: http://${BUCKET_NAME}.s3-website-${AWS_REGION}.amazonaws.com"

# 2. Create ECR repository
echo ""
echo "🐳 Creating ECR repository..."
ECR_REPO="${PROJECT_NAME}-backend"
if aws ecr describe-repositories --repository-names $ECR_REPO 2>/dev/null; then
    echo "ECR repository $ECR_REPO already exists"
else
    aws ecr create-repository --repository-name $ECR_REPO
    echo "Created ECR repository: $ECR_REPO"
fi
ECR_URI="${CURRENT_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
echo "ECR URI: $ECR_URI"

# 3. Create VPC and security groups (use default VPC)
echo ""
echo "🔒 Setting up security groups..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)
echo "Using default VPC: $VPC_ID"

# ALB security group
ALB_SG=$(aws ec2 create-security-group \
    --group-name ${PROJECT_NAME}-alb-sg \
    --description "Security group for ChopperTracker ALB" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${PROJECT_NAME}-alb-sg" \
    --query 'SecurityGroups[0].GroupId' --output text)

# ECS security group  
ECS_SG=$(aws ec2 create-security-group \
    --group-name ${PROJECT_NAME}-ecs-sg \
    --description "Security group for ChopperTracker ECS" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${PROJECT_NAME}-ecs-sg" \
    --query 'SecurityGroups[0].GroupId' --output text)

# Configure security group rules
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 443 --cidr 0.0.0.0/0 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id $ECS_SG --protocol tcp --port 80 --source-group $ALB_SG 2>/dev/null || true

echo "✅ Security groups configured"

# 4. Create Application Load Balancer
echo ""
echo "⚖️ Creating Application Load Balancer..."
SUBNET1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
SUBNET2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[1].SubnetId' --output text)

ALB_ARN=$(aws elbv2 create-load-balancer \
    --name ${PROJECT_NAME}-alb \
    --subnets $SUBNET1 $SUBNET2 \
    --security-groups $ALB_SG \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || \
    aws elbv2 describe-load-balancers \
    --names ${PROJECT_NAME}-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)

ALB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $ALB_ARN \
    --query 'LoadBalancers[0].DNSName' --output text)

echo "✅ ALB created: $ALB_DNS"

# 5. Create target group
TG_ARN=$(aws elbv2 create-target-group \
    --name ${PROJECT_NAME}-tg \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-path /health \
    --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || \
    aws elbv2 describe-target-groups \
    --names ${PROJECT_NAME}-tg \
    --query 'TargetGroups[0].TargetGroupArn' --output text)

# Create listener
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN 2>/dev/null || true

# 6. Create ECS cluster
echo ""
echo "📦 Creating ECS cluster..."
aws ecs create-cluster --cluster-name ${PROJECT_NAME}-cluster 2>/dev/null || true

# 7. Create CloudWatch log group
aws logs create-log-group --log-group-name /ecs/${PROJECT_NAME} 2>/dev/null || true

# 8. Create ECS task execution role
echo ""
echo "👤 Creating ECS task execution role..."
ROLE_NAME="${PROJECT_NAME}-task-execution-role"
cat > /tmp/trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file:///tmp/trust-policy.json 2>/dev/null || true

aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 2>/dev/null || true

# Output summary
echo ""
echo "✅ Infrastructure setup complete!"
echo ""
echo "Resources created in ChopperTracker account:"
echo "- S3 Bucket: $BUCKET_NAME"
echo "- S3 Website: http://${BUCKET_NAME}.s3-website-${AWS_REGION}.amazonaws.com"
echo "- ECR Repository: $ECR_URI"
echo "- ALB: $ALB_DNS"
echo "- ECS Cluster: ${PROJECT_NAME}-cluster"
echo "- Security Groups: ALB=$ALB_SG, ECS=$ECS_SG"
echo ""
echo "Next steps:"
echo "1. Update GitHub Actions to use ChopperTracker account credentials"
echo "2. Push Docker images to new ECR"
echo "3. Deploy ECS service"
echo "4. Update Route 53 in main account to point to new ALB"

# Save configuration
cat > choppertracker-config.env << EOF
BUCKET_NAME=$BUCKET_NAME
ECR_URI=$ECR_URI
ALB_ARN=$ALB_ARN
ALB_DNS=$ALB_DNS
TARGET_GROUP_ARN=$TG_ARN
ALB_SG=$ALB_SG
ECS_SG=$ECS_SG
VPC_ID=$VPC_ID
SUBNET1=$SUBNET1
SUBNET2=$SUBNET2
EOF

echo ""
echo "Configuration saved to: choppertracker-config.env"