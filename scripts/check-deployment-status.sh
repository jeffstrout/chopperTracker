#!/bin/bash

echo "🔍 Checking ChopperTracker Deployment Status"
echo "==========================================="

# Configuration
ACCOUNT_ID="038342322731"
REGION="us-east-1"

# Verify we're checking the right account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "Current Account: $CURRENT_ACCOUNT"
echo ""

# Check S3 Frontend
echo "🌐 Frontend Status (S3):"
echo "----------------------"
BUCKET_NAME="choppertracker-frontend"
if aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
    echo "✅ S3 bucket exists: $BUCKET_NAME"
    WEBSITE_URL="http://${BUCKET_NAME}.s3-website-${REGION}.amazonaws.com"
    echo "📍 Website URL: $WEBSITE_URL"
    
    # Check if index.html exists
    if aws s3 ls s3://$BUCKET_NAME/index.html >/dev/null 2>&1; then
        echo "✅ Frontend files deployed"
    else
        echo "❌ Frontend files not found"
    fi
else
    echo "❌ S3 bucket not found"
fi
echo ""

# Check ALB
echo "⚖️ Load Balancer Status:"
echo "----------------------"
ALB_NAME="choppertracker-alb"
ALB_INFO=$(aws elbv2 describe-load-balancers --names $ALB_NAME 2>/dev/null)
if [ $? -eq 0 ]; then
    ALB_DNS=$(echo $ALB_INFO | jq -r '.LoadBalancers[0].DNSName')
    ALB_STATE=$(echo $ALB_INFO | jq -r '.LoadBalancers[0].State.Code')
    echo "✅ ALB exists: $ALB_NAME"
    echo "📍 ALB DNS: http://$ALB_DNS"
    echo "📊 State: $ALB_STATE"
    
    # Check target health
    TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $(echo $ALB_INFO | jq -r '.LoadBalancers[0].LoadBalancerArn') --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
    if [ ! -z "$TARGET_GROUP_ARN" ]; then
        HEALTH=$(aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN --query 'TargetHealthDescriptions[0].TargetHealth.State' --output text 2>/dev/null)
        echo "🎯 Target Health: $HEALTH"
    fi
else
    echo "❌ ALB not found"
fi
echo ""

# Check ECS Service
echo "📊 ECS Service Status:"
echo "--------------------"
CLUSTER_NAME="choppertracker-cluster"
SERVICE_NAME="choppertracker-backend"

# Check if cluster exists
if aws ecs describe-clusters --clusters $CLUSTER_NAME --query 'clusters[0].clusterName' --output text 2>/dev/null | grep -q "$CLUSTER_NAME"; then
    echo "✅ ECS Cluster exists: $CLUSTER_NAME"
    
    # Check service
    SERVICE_INFO=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME 2>/dev/null)
    if [ $? -eq 0 ]; then
        DESIRED_COUNT=$(echo $SERVICE_INFO | jq -r '.services[0].desiredCount')
        RUNNING_COUNT=$(echo $SERVICE_INFO | jq -r '.services[0].runningCount')
        SERVICE_STATUS=$(echo $SERVICE_INFO | jq -r '.services[0].status')
        
        echo "✅ ECS Service exists: $SERVICE_NAME"
        echo "📊 Status: $SERVICE_STATUS"
        echo "🔢 Desired/Running: $DESIRED_COUNT/$RUNNING_COUNT"
        
        # Get task status
        TASK_ARNS=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --query 'taskArns' --output json | jq -r '.[]' 2>/dev/null)
        if [ ! -z "$TASK_ARNS" ]; then
            echo "📦 Tasks:"
            for TASK in $TASK_ARNS; do
                TASK_STATUS=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK --query 'tasks[0].lastStatus' --output text 2>/dev/null)
                echo "  - Task: $(basename $TASK) - Status: $TASK_STATUS"
            done
        fi
    else
        echo "❌ ECS Service not found"
    fi
else
    echo "❌ ECS Cluster not found"
fi
echo ""

# Check ECR Repository
echo "🐳 ECR Repository Status:"
echo "-----------------------"
ECR_REPO="choppertracker-backend"
if aws ecr describe-repositories --repository-names $ECR_REPO 2>/dev/null; then
    echo "✅ ECR repository exists: $ECR_REPO"
    IMAGE_COUNT=$(aws ecr list-images --repository-name $ECR_REPO --query 'length(imageIds)' --output text 2>/dev/null)
    echo "🖼️ Images in repository: $IMAGE_COUNT"
else
    echo "❌ ECR repository not found"
fi
echo ""

# Test API Health
echo "🏥 API Health Check:"
echo "------------------"
if [ ! -z "$ALB_DNS" ]; then
    echo "Testing API endpoint..."
    HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_DNS/health --max-time 5 2>/dev/null || echo "000")
    if [ "$HEALTH_RESPONSE" = "200" ]; then
        echo "✅ API is responding (HTTP $HEALTH_RESPONSE)"
        echo "📍 API URL: http://$ALB_DNS"
    else
        echo "⚠️ API not responding (HTTP $HEALTH_RESPONSE)"
        echo "This might be normal if the service is still starting up"
    fi
fi
echo ""

# Summary
echo "📋 Summary:"
echo "----------"
echo "Frontend URL: $WEBSITE_URL"
echo "API URL: http://$ALB_DNS"
echo ""
echo "🎯 Next Steps:"
echo "1. Visit the frontend URL to see the application"
echo "2. Check the API health at http://$ALB_DNS/health"
echo "3. Set up custom domains (www.choppertracker.com and api.choppertracker.com)"