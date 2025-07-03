#!/bin/bash

echo "🔐 Granting ECR permissions to ChopperTracker GitHub user from main account"
echo "=========================================================================="

# Configuration
MAIN_ACCOUNT="958933162000"
CHOPPERTRACKER_ACCOUNT="038342322731"
GITHUB_USER="choppertracker-github-deploy"

# Verify we're in main account
echo "🔍 Verifying we're in main account..."
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "$MAIN_ACCOUNT" ]; then
    echo "❌ ERROR: Not in main account. Current: $CURRENT_ACCOUNT, Expected: $MAIN_ACCOUNT"
    echo "Please run this from your main account credentials"
    exit 1
fi

echo "✅ Confirmed main account: $CURRENT_ACCOUNT"

# The GitHub user is in the ChopperTracker account, so we need to grant cross-account access
# Let's create the ECR repository in the main account and give the ChopperTracker user access

ECR_REPO="choppertracker-backend"
echo ""
echo "🏗️ Creating ECR repository in main account: $ECR_REPO"

if aws ecr describe-repositories --repository-names $ECR_REPO --region us-east-1 2>/dev/null; then
    echo "✅ ECR repository $ECR_REPO already exists"
else
    echo "Creating ECR repository: $ECR_REPO" 
    aws ecr create-repository --repository-name $ECR_REPO --region us-east-1
    echo "✅ Created ECR repository: $ECR_REPO"
fi

# Set repository policy to allow ChopperTracker GitHub user
echo ""
echo "🔐 Setting cross-account repository policy..."

cat > /tmp/ecr-cross-account-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowChopperTrackerGitHubUser",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${CHOPPERTRACKER_ACCOUNT}:user/${GITHUB_USER}"
      },
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability", 
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
  ]
}
EOF

aws ecr set-repository-policy \
    --repository-name $ECR_REPO \
    --policy-text file:///tmp/ecr-cross-account-policy.json \
    --region us-east-1

if [ $? -eq 0 ]; then
    echo "✅ Cross-account ECR policy set successfully"
else
    echo "❌ Failed to set ECR policy"
    exit 1
fi

# Get repository URI
ECR_URI=$(aws ecr describe-repositories --repository-names $ECR_REPO --region us-east-1 --query 'repositories[0].repositoryUri' --output text)

echo ""
echo "🎉 Cross-account ECR setup complete!"
echo ""
echo "ECR Repository: $ECR_URI"
echo "Authorized User: arn:aws:iam::${CHOPPERTRACKER_ACCOUNT}:user/${GITHUB_USER}"
echo ""
echo "The GitHub Actions can now push to this ECR repository from the ChopperTracker account!"

# Clean up
rm -f /tmp/ecr-cross-account-policy.json