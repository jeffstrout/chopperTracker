#!/bin/bash

echo "🪣 Adding S3 permissions to ChopperTracker ECR user"
echo "=================================================="

# Configuration
MAIN_ACCOUNT="958933162000"
ECR_USER_NAME="choppertracker-ecr-user"

# Verify we're in main account
echo "🔍 Verifying we're in main account..."
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "$MAIN_ACCOUNT" ]; then
    echo "❌ ERROR: Not in main account. Current: $CURRENT_ACCOUNT, Expected: $MAIN_ACCOUNT"
    exit 1
fi

echo "✅ Confirmed main account: $CURRENT_ACCOUNT"

# Create S3 deployment policy
echo ""
echo "📝 Creating S3 deployment policy..."
cat > /tmp/s3-deployment-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:GetBucketWebsite",
                "s3:PutBucketWebsite",
                "s3:DeleteBucketWebsite",
                "s3:PutBucketPolicy",
                "s3:GetBucketPolicy",
                "s3:DeleteBucketPolicy",
                "s3:PutBucketPublicAccessBlock",
                "s3:GetBucketPublicAccessBlock",
                "s3:DeleteBucketPublicAccessBlock",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws:s3:::choppertracker-*",
                "arn:aws:s3:::choppertracker-*/*"
            ]
        }
    ]
}
EOF

# Create the S3 policy
POLICY_NAME="ChopperTrackerS3Access"
POLICY_ARN="arn:aws:iam::${MAIN_ACCOUNT}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn $POLICY_ARN >/dev/null 2>&1; then
    echo "Policy $POLICY_NAME already exists"
else
    echo "Creating S3 access policy: $POLICY_NAME"
    aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document file:///tmp/s3-deployment-policy.json \
        --description "S3 deployment permissions for ChopperTracker"
    echo "✅ Created policy: $POLICY_NAME"
fi

# Attach S3 policy to ECR user
echo ""
echo "🔗 Attaching S3 policy to user: $ECR_USER_NAME"
aws iam attach-user-policy \
    --user-name $ECR_USER_NAME \
    --policy-arn $POLICY_ARN

if [ $? -eq 0 ]; then
    echo "✅ S3 policy attached successfully"
else
    echo "❌ Failed to attach S3 policy"
    exit 1
fi

# List all policies attached to user
echo ""
echo "📋 Current policies attached to $ECR_USER_NAME:"
aws iam list-attached-user-policies --user-name $ECR_USER_NAME

echo ""
echo "🎉 S3 permissions added successfully!"
echo ""
echo "The ECR user can now:"
echo "- Access ECR repositories ✅"
echo "- Create/manage S3 buckets ✅"
echo "- Deploy frontend to S3 ✅"

# Clean up
rm -f /tmp/s3-deployment-policy.json