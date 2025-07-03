#!/bin/bash

echo "🔐 Granting ECR GetAuthorizationToken permission to ChopperTracker GitHub user"
echo "============================================================================"

# This script grants the ECR GetAuthorizationToken permission
# Run this via GitHub Actions or with ChopperTracker account credentials

# Configuration
CHOPPERTRACKER_ACCOUNT="038342322731"
GITHUB_USER="choppertracker-github-deploy"

# Verify we're in ChopperTracker account
echo "🔍 Verifying we're in ChopperTracker account..."
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "$CHOPPERTRACKER_ACCOUNT" ]; then
    echo "❌ ERROR: Not in ChopperTracker account. Current: $CURRENT_ACCOUNT, Expected: $CHOPPERTRACKER_ACCOUNT"
    exit 1
fi

echo "✅ Confirmed ChopperTracker account: $CURRENT_ACCOUNT"

# Create ECR authorization token policy
echo ""
echo "📝 Creating ECR authorization token policy..."
cat > /tmp/ecr-auth-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# Create the policy
POLICY_NAME="ChopperTrackerECRAuthToken"
POLICY_ARN="arn:aws:iam::${CURRENT_ACCOUNT}:policy/${POLICY_NAME}"

echo "Creating policy: $POLICY_NAME"
if aws iam get-policy --policy-arn $POLICY_ARN >/dev/null 2>&1; then
    echo "Policy $POLICY_NAME already exists"
else
    aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document file:///tmp/ecr-auth-policy.json \
        --description "ECR GetAuthorizationToken permission for ChopperTracker GitHub deployment"
    echo "✅ Created policy: $POLICY_NAME"
fi

# Attach policy to user
echo ""
echo "🔗 Attaching policy to user: $GITHUB_USER"
aws iam attach-user-policy \
    --user-name $GITHUB_USER \
    --policy-arn $POLICY_ARN

if [ $? -eq 0 ]; then
    echo "✅ Policy attached successfully"
else
    echo "❌ Failed to attach policy"
    exit 1
fi

# List user policies to verify
echo ""
echo "📋 Verifying user policies:"
aws iam list-attached-user-policies --user-name $GITHUB_USER

echo ""
echo "🎉 ECR authorization token permission granted!"
echo ""
echo "The GitHub Actions should now be able to:"
echo "- Get ECR authorization tokens ✅"
echo "- Login to ECR repositories ✅"
echo "- Push Docker images to main account ECR ✅"

# Clean up
rm -f /tmp/ecr-auth-policy.json