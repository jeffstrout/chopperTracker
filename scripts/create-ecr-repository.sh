#!/bin/bash
# Create ECR repository in ChopperTracker account
# Run this with admin credentials for the ChopperTracker account

set -e

echo "🐳 Creating ECR repository in ChopperTracker account..."

# Verify we're in the correct account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "038342322731" ]; then
    echo "❌ ERROR: Not in ChopperTracker account. Current account: $CURRENT_ACCOUNT"
    echo "Please configure AWS credentials for account 038342322731"
    exit 1
fi

echo "✅ Confirmed ChopperTracker account ($CURRENT_ACCOUNT)"

# Create ECR repository
ECR_REPO="choppertracker-backend"
if aws ecr describe-repositories --repository-names $ECR_REPO 2>/dev/null; then
    echo "✅ ECR repository $ECR_REPO already exists"
else
    echo "Creating ECR repository: $ECR_REPO"
    aws ecr create-repository --repository-name $ECR_REPO
    echo "✅ Created ECR repository: $ECR_REPO"
fi

# Get repository URI
ECR_URI=$(aws ecr describe-repositories --repository-names $ECR_REPO --query 'repositories[0].repositoryUri' --output text)
echo ""
echo "ECR Repository: $ECR_URI"
echo ""
echo "To push images:"
echo "1. Login: aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI"
echo "2. Build: docker build -t $ECR_URI:latest ."
echo "3. Push: docker push $ECR_URI:latest"
echo ""
echo "GitHub Actions can now use this repository for deployments."