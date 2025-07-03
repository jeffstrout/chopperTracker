#!/bin/bash

echo "🐳 Creating ECR repository for ChopperTracker deployment"
echo "======================================================="

# Configuration
ECR_REPO="choppertracker-backend"
AWS_REGION="us-east-1"

# Verify account
echo "🔍 Verifying AWS account..."
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "Current Account: $CURRENT_ACCOUNT"

if [ "$CURRENT_ACCOUNT" != "038342322731" ]; then
    echo "❌ ERROR: Not in ChopperTracker account. Expected: 038342322731"
    echo "Current account: $CURRENT_ACCOUNT"
    exit 1
fi

echo "✅ Confirmed ChopperTracker account"

# Create ECR repository
echo ""
echo "🏗️ Creating ECR repository: $ECR_REPO"

if aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION 2>/dev/null; then
    echo "✅ ECR repository $ECR_REPO already exists"
else
    echo "Creating ECR repository: $ECR_REPO"
    aws ecr create-repository \
        --repository-name $ECR_REPO \
        --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        echo "✅ Created ECR repository: $ECR_REPO"
    else
        echo "❌ Failed to create ECR repository"
        exit 1
    fi
fi

# Get repository URI
ECR_URI=$(aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION --query 'repositories[0].repositoryUri' --output text)

echo ""
echo "🎉 ECR repository ready!"
echo "Repository URI: $ECR_URI"
echo ""
echo "✅ GitHub Actions should now be able to push Docker images"