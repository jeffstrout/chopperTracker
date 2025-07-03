#!/bin/bash

echo "🔐 Granting ECR GetAuthorizationToken to ChopperTracker user from main account"
echo "============================================================================"

# This script creates an IAM policy in the main account that allows 
# the ChopperTracker GitHub user to get ECR authorization tokens

# Configuration
MAIN_ACCOUNT="958933162000"
CHOPPERTRACKER_ACCOUNT="038342322731"
GITHUB_USER_ARN="arn:aws:iam::${CHOPPERTRACKER_ACCOUNT}:user/choppertracker-github-deploy"

# Verify we're in main account
echo "🔍 Verifying we're in main account..."
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "$MAIN_ACCOUNT" ]; then
    echo "❌ ERROR: Not in main account. Current: $CURRENT_ACCOUNT, Expected: $MAIN_ACCOUNT"
    echo "Please run this from your main account credentials"
    exit 1
fi

echo "✅ Confirmed main account: $CURRENT_ACCOUNT"

# Create a resource-based policy for ECR that allows the ChopperTracker user
# to get authorization tokens for the main account ECR
echo ""
echo "🔐 Creating ECR resource policy for cross-account access..."

# Note: ECR GetAuthorizationToken is a global action, so we need to add
# the permission to allow cross-account access to ECR itself

# Actually, let's create a role in the main account that the ChopperTracker user can assume
echo "🏗️ Creating cross-account role for ECR access..."

# Create trust policy for the role
cat > /tmp/ecr-cross-account-trust.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${GITHUB_USER_ARN}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create permissions policy for the role
cat > /tmp/ecr-cross-account-permissions.json <<EOF
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
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create the role
ROLE_NAME="ChopperTrackerECRAccess"
ROLE_ARN="arn:aws:iam::${MAIN_ACCOUNT}:role/${ROLE_NAME}"

echo "Creating role: $ROLE_NAME"
if aws iam get-role --role-name $ROLE_NAME >/dev/null 2>&1; then
    echo "Role $ROLE_NAME already exists"
else
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file:///tmp/ecr-cross-account-trust.json \
        --description "Cross-account ECR access for ChopperTracker GitHub deployment"
    echo "✅ Created role: $ROLE_NAME"
fi

# Create the policy
POLICY_NAME="ChopperTrackerECRFullAccess"
POLICY_ARN="arn:aws:iam::${MAIN_ACCOUNT}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn $POLICY_ARN >/dev/null 2>&1; then
    echo "Policy $POLICY_NAME already exists"
else
    echo "Creating policy: $POLICY_NAME"
    aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document file:///tmp/ecr-cross-account-permissions.json \
        --description "ECR permissions for ChopperTracker cross-account access"
    echo "✅ Created policy: $POLICY_NAME"
fi

# Attach policy to role
echo "Attaching policy to role..."
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn $POLICY_ARN

echo ""
echo "🎉 Cross-account ECR role setup complete!"
echo ""
echo "Role ARN: $ROLE_ARN"
echo "Trusted Principal: $GITHUB_USER_ARN"
echo ""
echo "Now update GitHub Actions to assume this role before ECR operations"

# Clean up
rm -f /tmp/ecr-cross-account-trust.json /tmp/ecr-cross-account-permissions.json