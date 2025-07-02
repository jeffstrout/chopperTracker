#!/bin/bash

# Flight Tracker Management Script
# Start, stop, and manage Flight Tracker services to control costs

set -e

CLUSTER="flight-tracker-cluster"
SERVICE="flight-tracker-backend"
REDIS_ID="flight-tracker-redis"

function show_usage {
    echo "Flight Tracker Management Script"
    echo "================================"
    echo ""
    echo "Usage: $0 [start|stop|status|costs]"
    echo ""
    echo "Commands:"
    echo "  start   - Start all Flight Tracker services"
    echo "  stop    - Stop all services (saves money when not in use)"
    echo "  status  - Show current status of all services"
    echo "  costs   - Show estimated monthly costs"
    echo ""
}

function start_services {
    echo "🚀 Starting Flight Tracker services..."
    
    # Start ECS service
    echo "Starting ECS service..."
    aws ecs update-service \
        --cluster $CLUSTER \
        --service $SERVICE \
        --desired-count 1 \
        --capacity-provider-strategy capacityProvider=FARGATE_SPOT,weight=1 \
        --output text
    
    echo "✅ Services starting. Full startup takes 2-3 minutes."
    echo "API will be available at: http://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com"
}

function stop_services {
    echo "🛑 Stopping Flight Tracker services..."
    
    # Stop ECS service
    echo "Stopping ECS service..."
    aws ecs update-service \
        --cluster $CLUSTER \
        --service $SERVICE \
        --desired-count 0 \
        --output text
    
    echo "✅ Services stopped. You're not being charged for compute resources."
    echo "Note: ALB, Redis, and storage still incur minimal charges."
}

function show_status {
    echo "📊 Flight Tracker Status"
    echo "========================"
    
    # ECS Status
    echo -n "ECS Tasks Running: "
    RUNNING=$(aws ecs describe-services \
        --cluster $CLUSTER \
        --services $SERVICE \
        --query 'services[0].runningCount' \
        --output text)
    echo "$RUNNING"
    
    # Capacity Provider
    echo -n "Using Spot Instances: "
    SPOT=$(aws ecs describe-services \
        --cluster $CLUSTER \
        --services $SERVICE \
        --query 'services[0].capacityProviderStrategy[0].capacityProvider' \
        --output text)
    if [ "$SPOT" == "FARGATE_SPOT" ]; then
        echo "Yes (70% savings!)"
    else
        echo "No"
    fi
    
    # Redis Status
    echo -n "Redis Status: "
    aws elasticache describe-cache-clusters \
        --cache-cluster-id $REDIS_ID \
        --query 'CacheClusters[0].CacheClusterStatus' \
        --output text
    
    # ALB Status
    echo -n "Load Balancer: "
    aws elbv2 describe-load-balancers \
        --names flight-tracker-alb \
        --query 'LoadBalancers[0].State.Code' \
        --output text
    
    # Test API
    echo ""
    echo "Testing API..."
    if curl -s http://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com/api/v1/status > /dev/null 2>&1; then
        echo "✅ API is responding"
    else
        echo "❌ API is not responding (may still be starting)"
    fi
}

function show_costs {
    echo "💰 Estimated Monthly Costs"
    echo "=========================="
    echo ""
    echo "Current Configuration:"
    echo "- ECS Fargate Spot: ~$7/month (was $25)"
    echo "- ElastiCache t3.micro: ~$15/month"
    echo "- Application Load Balancer: ~$20/month"
    echo "- S3 + CloudFront: ~$2/month"
    echo ""
    echo "Total: ~$44/month (under your $50 budget!)"
    echo ""
    echo "💡 Additional Savings:"
    echo "- Stop services when not in use: Save $7/month"
    echo "- Delete ALB (use API directly): Save $20/month"
    echo "- Schedule services (e.g., business hours only): Save 70%"
}

# Main script
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    status)
        show_status
        ;;
    costs)
        show_costs
        ;;
    *)
        show_usage
        exit 1
        ;;
esac