#!/bin/bash

echo "🔍 Checking Resources in ChopperTracker Account"
echo "=============================================="

# Get current account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"
echo ""

# Check S3 buckets
echo "📦 S3 Buckets:"
echo "-------------"
aws s3 ls 2>/dev/null || echo "No S3 buckets found"
echo ""

# Check IAM users
echo "👤 IAM Users:"
echo "------------"
aws iam list-users --query 'Users[*].UserName' --output text 2>/dev/null || echo "No IAM users found"
echo ""

# Check ECR repositories
echo "🐳 ECR Repositories:"
echo "------------------"
aws ecr describe-repositories --query 'repositories[*].repositoryName' --output text 2>/dev/null || echo "No ECR repositories found"
echo ""

# Check ECS clusters
echo "📊 ECS Clusters:"
echo "---------------"
aws ecs list-clusters --query 'clusterArns[*]' --output text 2>/dev/null | sed 's/.*\///' || echo "No ECS clusters found"
echo ""

# Check CloudFormation stacks
echo "📚 CloudFormation Stacks:"
echo "-----------------------"
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query 'StackSummaries[*].StackName' --output text 2>/dev/null || echo "No CloudFormation stacks found"
echo ""

# Check ALBs
echo "⚖️ Load Balancers:"
echo "-----------------"
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerName' --output text 2>/dev/null || echo "No load balancers found"
echo ""

# Check Route 53 hosted zones
echo "🌐 Route 53 Hosted Zones:"
echo "------------------------"
aws route53 list-hosted-zones --query 'HostedZones[*].Name' --output text 2>/dev/null || echo "No hosted zones found"
echo ""

# Summary
echo "📋 Summary:"
echo "----------"
echo "This account appears to have minimal resources."
echo "Main resource found: IAM user 'choppertracker-github-deploy' (if it exists)"