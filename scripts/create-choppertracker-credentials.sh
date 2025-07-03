#!/bin/bash
# Create or update credentials for ChopperTracker account
# Run this script with admin credentials for the ChopperTracker account (038342322731)

set -e

echo "🔐 Creating ChopperTracker credentials..."

# Verify we're in the correct account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "038342322731" ]; then
    echo "❌ ERROR: Not in ChopperTracker account. Current account: $CURRENT_ACCOUNT"
    echo "Please configure AWS credentials for account 038342322731 first"
    echo ""
    echo "If you don't have ChopperTracker admin credentials, you'll need to:"
    echo "1. Contact the ChopperTracker account owner"
    echo "2. Or create the ChopperTracker AWS account if it doesn't exist"
    exit 1
fi

echo "✅ Confirmed ChopperTracker account ($CURRENT_ACCOUNT)"

# User details
USER_NAME="choppertracker-github-deploy"
echo "Managing user: $USER_NAME"

# Check if user exists, create if not
if aws iam get-user --user-name $USER_NAME >/dev/null 2>&1; then
    echo "✅ User $USER_NAME already exists"
else
    echo "Creating user: $USER_NAME"
    aws iam create-user \
        --user-name $USER_NAME \
        --tags Key=Purpose,Value=GitHubDeployment Key=Project,Value=ChopperTracker
    echo "✅ Created user: $USER_NAME"
fi

# Create comprehensive deployment policy
echo "Creating deployment policy..."
cat > /tmp/choppertracker-deployment-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::choppertracker-*",
                "arn:aws:s3:::choppertracker-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elbv2:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetRole",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:PassRole"
            ],
            "Resource": [
                "arn:aws:iam::038342322731:role/choppertracker-*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# Create or update the policy
POLICY_NAME="ChopperTrackerFullDeployment"
POLICY_ARN="arn:aws:iam::${CURRENT_ACCOUNT}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn $POLICY_ARN >/dev/null 2>&1; then
    echo "Updating existing policy: $POLICY_NAME"
    # Get the current policy version
    VERSION=$(aws iam get-policy --policy-arn $POLICY_ARN --query 'Policy.DefaultVersionId' --output text)
    # Create new version
    aws iam create-policy-version \
        --policy-arn $POLICY_ARN \
        --policy-document file:///tmp/choppertracker-deployment-policy.json \
        --set-as-default
    echo "✅ Updated policy: $POLICY_NAME"
else
    echo "Creating policy: $POLICY_NAME"
    aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document file:///tmp/choppertracker-deployment-policy.json \
        --description "Full deployment permissions for ChopperTracker GitHub Actions"
    echo "✅ Created policy: $POLICY_NAME"
fi

# Attach policy to user
echo "Attaching deployment policy to user..."
aws iam attach-user-policy \
    --user-name $USER_NAME \
    --policy-arn $POLICY_ARN

echo "✅ Policy attached to user"

# Create access key (delete old ones first if they exist)
echo "Managing access keys..."
EXISTING_KEYS=$(aws iam list-access-keys --user-name $USER_NAME --query 'AccessKeyMetadata[].AccessKeyId' --output text)
if [ ! -z "$EXISTING_KEYS" ]; then
    echo "Deleting existing access keys..."
    for key in $EXISTING_KEYS; do
        aws iam delete-access-key --user-name $USER_NAME --access-key-id $key
        echo "Deleted old access key: $key"
    done
fi

echo "Creating new access key..."
CREDENTIALS=$(aws iam create-access-key --user-name $USER_NAME --output json)
ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.AccessKey.AccessKeyId')
SECRET_KEY=$(echo $CREDENTIALS | jq -r '.AccessKey.SecretAccessKey')

echo ""
echo "🎉 ChopperTracker credentials created successfully!"
echo ""
echo "=================================="
echo "SAVE THESE CREDENTIALS SECURELY:"
echo "=================================="
echo "AWS_ACCESS_KEY_ID=$ACCESS_KEY"
echo "AWS_SECRET_ACCESS_KEY=$SECRET_KEY"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Save these credentials to your password manager"
echo "2. Configure AWS profile:"
echo "   aws configure --profile choppertracker"
echo "   # Use the credentials above"
echo "3. Update GitHub repository secrets:"
echo "   - AWS_ACCESS_KEY_ID: $ACCESS_KEY"
echo "   - AWS_SECRET_ACCESS_KEY: $SECRET_KEY"
echo "4. Test the deployment"
echo ""
echo "The user $USER_NAME now has full deployment permissions for ChopperTracker resources."

# Clean up
rm -f /tmp/choppertracker-deployment-policy.json