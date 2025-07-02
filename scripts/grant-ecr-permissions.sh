#!/bin/bash
# Grant ECR permissions to choppertracker-github-deploy user
# Run this with admin credentials for the ChopperTracker account (038342322731)

set -e

echo "🔐 Granting ECR permissions to choppertracker-github-deploy user..."

# Verify we're in the correct account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "038342322731" ]; then
    echo "❌ ERROR: Not in ChopperTracker account. Current account: $CURRENT_ACCOUNT"
    echo "Please configure AWS credentials for account 038342322731"
    exit 1
fi

echo "✅ Confirmed ChopperTracker account ($CURRENT_ACCOUNT)"

# Check if user exists
USER_NAME="choppertracker-github-deploy"
if ! aws iam get-user --user-name $USER_NAME >/dev/null 2>&1; then
    echo "❌ ERROR: User $USER_NAME does not exist"
    exit 1
fi

echo "✅ User $USER_NAME exists"

# Create ECR permission policy
echo "Creating ECR permissions policy..."
cat > /tmp/ecr-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:DescribeRepositories",
                "ecr:CreateRepository",
                "ecr:DeleteRepository",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchDeleteImage"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# Create the policy
POLICY_NAME="ChopperTrackerECRAccess"
POLICY_ARN="arn:aws:iam::${CURRENT_ACCOUNT}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn $POLICY_ARN >/dev/null 2>&1; then
    echo "Policy $POLICY_NAME already exists"
else
    echo "Creating policy: $POLICY_NAME"
    aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document file:///tmp/ecr-policy.json \
        --description "ECR permissions for ChopperTracker GitHub deployment"
    echo "✅ Created policy: $POLICY_NAME"
fi

# Attach policy to user
echo "Attaching policy to user: $USER_NAME"
aws iam attach-user-policy \
    --user-name $USER_NAME \
    --policy-arn $POLICY_ARN

echo "✅ Policy attached successfully"

# Create ECR repository now that permissions are granted
echo ""
echo "🐳 Creating ECR repository..."
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
echo "🎉 Setup complete!"
echo ""
echo "Permissions granted to user: $USER_NAME"
echo "ECR Repository: $ECR_URI"
echo ""
echo "The GitHub Actions deployment should now work completely!"
echo "Next deployment will be able to:"
echo "- Create ECR repositories ✅"
echo "- Push Docker images ✅"
echo "- Deploy to ECS ✅"

# Clean up
rm -f /tmp/ecr-policy.json