#!/bin/bash

echo "🔐 Granting global ECR authorization token permission to ChopperTracker user"
echo "==========================================================================="

# This approach creates an IAM policy in the main account that allows
# the ChopperTracker user to get ECR authorization tokens globally

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

# ECR GetAuthorizationToken is a special permission that can be granted
# through resource-based policies. Let's update our ECR repository policy
# to include this permission.

echo ""
echo "🔐 Updating ECR repository policy to include GetAuthorizationToken..."

ECR_REPO="choppertracker-backend"

cat > /tmp/ecr-enhanced-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowChopperTrackerGitHubUser",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${GITHUB_USER_ARN}"
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

# Apply the updated policy
aws ecr set-repository-policy \
    --repository-name $ECR_REPO \
    --policy-text file:///tmp/ecr-enhanced-policy.json \
    --region us-east-1

if [ $? -eq 0 ]; then
    echo "✅ ECR repository policy updated successfully"
else
    echo "❌ Failed to update ECR repository policy"
    exit 1
fi

# Unfortunately, GetAuthorizationToken is a global ECR action that can't be granted
# via repository policies. We need to create a custom resource-based policy or
# grant the permission differently.

echo ""
echo "🏗️ Creating IAM user in main account for ChopperTracker to use directly..."

# Alternative approach: Create a user in the main account specifically for ChopperTracker ECR access
ECR_USER_NAME="choppertracker-ecr-user"

# Check if user exists
if aws iam get-user --user-name $ECR_USER_NAME >/dev/null 2>&1; then
    echo "User $ECR_USER_NAME already exists"
else
    echo "Creating IAM user: $ECR_USER_NAME"
    aws iam create-user --user-name $ECR_USER_NAME --path /choppertracker/
fi

# Create policy for ECR access
POLICY_NAME="ChopperTrackerECRDirectAccess"
POLICY_ARN="arn:aws:iam::${MAIN_ACCOUNT}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn $POLICY_ARN >/dev/null 2>&1; then
    echo "Policy $POLICY_NAME already exists"
else
    echo "Creating ECR access policy: $POLICY_NAME"
    
    cat > /tmp/ecr-direct-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ],
            "Resource": "arn:aws:ecr:us-east-1:${MAIN_ACCOUNT}:repository/${ECR_REPO}"
        }
    ]
}
EOF

    aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document file:///tmp/ecr-direct-policy.json \
        --description "Direct ECR access for ChopperTracker deployment"
fi

# Attach policy to user
echo "Attaching policy to user..."
aws iam attach-user-policy \
    --user-name $ECR_USER_NAME \
    --policy-arn $POLICY_ARN

# Create access key for the user
echo ""
echo "🔑 Creating access key for ECR user..."
ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name $ECR_USER_NAME --output json)

if [ $? -eq 0 ]; then
    ACCESS_KEY_ID=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.AccessKeyId')
    SECRET_KEY=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.SecretAccessKey')
    
    echo "✅ Access key created successfully"
    echo ""
    echo "🔐 NEW GITHUB SECRETS NEEDED:"
    echo "=============================="
    echo "ECR_AWS_ACCESS_KEY_ID: $ACCESS_KEY_ID"
    echo "ECR_AWS_SECRET_ACCESS_KEY: $SECRET_KEY"
    echo ""
    echo "Add these to GitHub repository secrets for ECR access"
else
    echo "❌ Failed to create access key"
fi

echo ""
echo "🎉 ECR direct access setup complete!"
echo ""
echo "Next steps:"
echo "1. Add the new GitHub secrets for ECR access"
echo "2. Update GitHub Actions to use separate ECR credentials"
echo "3. Test the deployment"

# Clean up
rm -f /tmp/ecr-enhanced-policy.json /tmp/ecr-direct-policy.json