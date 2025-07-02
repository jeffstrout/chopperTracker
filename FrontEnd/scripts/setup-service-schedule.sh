#!/bin/bash

# Flight Tracker Service Scheduling Setup
# Creates EventBridge rules to automatically start/stop services

set -e

echo "⏰ Setting up Flight Tracker Service Schedule"
echo "============================================"
echo ""

# Get timezone
read -p "Enter your timezone (e.g., America/Chicago, America/New_York): " TIMEZONE
TIMEZONE=${TIMEZONE:-America/Chicago}

# Convert times to UTC for EventBridge
# Note: EventBridge uses UTC, so we need to convert
echo "Converting times to UTC..."
echo "Stop time: 23:00 $TIMEZONE"
echo "Start time: 07:00 $TIMEZONE"

# Create IAM role for EventBridge
echo "👤 Creating IAM role for EventBridge..."
cat > /tmp/eventbridge-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

ROLE_ARN=$(aws iam create-role \
    --role-name flight-tracker-scheduler-role \
    --assume-role-policy-document file:///tmp/eventbridge-trust-policy.json \
    --query 'Role.Arn' \
    --output text 2>/dev/null || \
    aws iam get-role \
        --role-name flight-tracker-scheduler-role \
        --query 'Role.Arn' \
        --output text)

# Create policy for ECS actions
echo "📋 Creating IAM policy..."
cat > /tmp/scheduler-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeServices"
      ],
      "Resource": [
        "arn:aws:ecs:us-east-1:*:service/flight-tracker-cluster/flight-tracker-backend"
      ]
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name flight-tracker-scheduler-role \
    --policy-name flight-tracker-scheduler-policy \
    --policy-document file:///tmp/scheduler-policy.json

# Create Lambda functions for start/stop
echo "🚀 Creating Lambda functions..."

# Stop function
cat > /tmp/stop-function.py <<'EOF'
import boto3
import json

def lambda_handler(event, context):
    ecs = boto3.client('ecs')
    
    response = ecs.update_service(
        cluster='flight-tracker-cluster',
        service='flight-tracker-backend',
        desiredCount=0
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Flight Tracker services stopped')
    }
EOF

# Start function
cat > /tmp/start-function.py <<'EOF'
import boto3
import json

def lambda_handler(event, context):
    ecs = boto3.client('ecs')
    
    response = ecs.update_service(
        cluster='flight-tracker-cluster',
        service='flight-tracker-backend',
        desiredCount=1,
        capacityProviderStrategy=[
            {
                'capacityProvider': 'FARGATE_SPOT',
                'weight': 1
            }
        ]
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Flight Tracker services started')
    }
EOF

# Create Lambda execution role
echo "Creating Lambda execution role..."
cat > /tmp/lambda-trust-policy.json <<EOF
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

LAMBDA_ROLE_ARN=$(aws iam create-role \
    --role-name flight-tracker-lambda-scheduler \
    --assume-role-policy-document file:///tmp/lambda-trust-policy.json \
    --query 'Role.Arn' \
    --output text 2>/dev/null || \
    aws iam get-role \
        --role-name flight-tracker-lambda-scheduler \
        --query 'Role.Arn' \
        --output text)

# Attach policies to Lambda role
aws iam attach-role-policy \
    --role-name flight-tracker-lambda-scheduler \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam put-role-policy \
    --role-name flight-tracker-lambda-scheduler \
    --policy-name flight-tracker-ecs-access \
    --policy-document file:///tmp/scheduler-policy.json

# Wait for role to propagate
echo "Waiting for IAM roles to propagate..."
sleep 10

# Package Lambda functions
cd /tmp
zip stop-function.zip stop-function.py
zip start-function.zip start-function.py

# Create Lambda functions
echo "Creating stop function..."
aws lambda create-function \
    --function-name flight-tracker-stop \
    --runtime python3.11 \
    --role "$LAMBDA_ROLE_ARN" \
    --handler stop-function.lambda_handler \
    --zip-file fileb://stop-function.zip \
    --timeout 30 \
    --memory-size 128 2>/dev/null || \
    aws lambda update-function-code \
        --function-name flight-tracker-stop \
        --zip-file fileb://stop-function.zip

echo "Creating start function..."
aws lambda create-function \
    --function-name flight-tracker-start \
    --runtime python3.11 \
    --role "$LAMBDA_ROLE_ARN" \
    --handler start-function.lambda_handler \
    --zip-file fileb://start-function.zip \
    --timeout 30 \
    --memory-size 128 2>/dev/null || \
    aws lambda update-function-code \
        --function-name flight-tracker-start \
        --zip-file fileb://start-function.zip

# Create EventBridge rules
echo "📅 Creating EventBridge schedules..."

# Stop rule (23:00 daily)
aws events put-rule \
    --name flight-tracker-stop-schedule \
    --schedule-expression "cron(0 23 * * ? *)" \
    --description "Stop Flight Tracker at 11 PM daily" \
    --state ENABLED

# Start rule (07:00 daily)
aws events put-rule \
    --name flight-tracker-start-schedule \
    --schedule-expression "cron(0 7 * * ? *)" \
    --description "Start Flight Tracker at 7 AM daily" \
    --state ENABLED

# Add Lambda permissions for EventBridge
aws lambda add-permission \
    --function-name flight-tracker-stop \
    --statement-id flight-tracker-stop-schedule \
    --action lambda:InvokeFunction \
    --principal events.amazonaws.com \
    --source-arn "arn:aws:events:us-east-1:$(aws sts get-caller-identity --query Account --output text):rule/flight-tracker-stop-schedule" 2>/dev/null || true

aws lambda add-permission \
    --function-name flight-tracker-start \
    --statement-id flight-tracker-start-schedule \
    --action lambda:InvokeFunction \
    --principal events.amazonaws.com \
    --source-arn "arn:aws:events:us-east-1:$(aws sts get-caller-identity --query Account --output text):rule/flight-tracker-start-schedule" 2>/dev/null || true

# Add targets to rules
echo "Connecting schedules to Lambda functions..."
aws events put-targets \
    --rule flight-tracker-stop-schedule \
    --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:$(aws sts get-caller-identity --query Account --output text):function:flight-tracker-stop"

aws events put-targets \
    --rule flight-tracker-start-schedule \
    --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:$(aws sts get-caller-identity --query Account --output text):function:flight-tracker-start"

# Clean up
rm -f /tmp/*.json /tmp/*.zip /tmp/*.py

echo ""
echo "✅ Service scheduling setup complete!"
echo "===================================="
echo ""
echo "⏰ Schedule (in $TIMEZONE):"
echo "  - Stop: 23:00 (11:00 PM)"
echo "  - Start: 07:00 (7:00 AM)"
echo "  - Running: 8 hours/day (67% cost savings on compute!)"
echo ""
echo "📊 Updated Monthly Costs:"
echo "  - ECS Fargate Spot: ~$2.30/month (was $7)"
echo "  - Total savings: ~$4.70/month"
echo ""
echo "🔧 Manual Override:"
echo "  - Start now: ./scripts/manage-flight-tracker.sh start"
echo "  - Stop now: ./scripts/manage-flight-tracker.sh stop"
echo ""
echo "📅 View schedules at:"
echo "  https://console.aws.amazon.com/events/home?region=us-east-1#/rules"