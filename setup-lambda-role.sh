#!/bin/bash

# This script creates the Lambda execution role in the ChopperTracker account
# Run this once before your first deployment

echo "Creating Lambda execution role..."

# Create the trust policy
cat > /tmp/lambda-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name lambda-execution-role \
  --assume-role-policy-document file:///tmp/lambda-trust-policy.json \
  --description "Execution role for ChopperTracker Lambda functions"

# Attach the basic Lambda execution policy
aws iam attach-role-policy \
  --role-name lambda-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Create and attach a custom policy for S3 access (if needed)
cat > /tmp/lambda-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::choppertracker-*",
        "arn:aws:s3:::choppertracker-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name ChopperTrackerLambdaPolicy \
  --policy-document file:///tmp/lambda-policy.json

# Get the account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Attach the custom policy
aws iam attach-role-policy \
  --role-name lambda-execution-role \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/ChopperTrackerLambdaPolicy

echo "Lambda execution role created successfully!"
echo "Role ARN: arn:aws:iam::${ACCOUNT_ID}:role/lambda-execution-role"

# Clean up
rm /tmp/lambda-trust-policy.json /tmp/lambda-policy.json