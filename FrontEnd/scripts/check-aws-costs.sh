#!/bin/bash

# AWS Cost Monitoring Script for Flight Tracker
# This script shows current costs and helps identify expensive resources

set -e

echo "💰 Flight Tracker AWS Cost Report"
echo "================================="
echo ""

# Get current month dates
START_DATE=$(date -u +"%Y-%m-01")
END_DATE=$(date -u +"%Y-%m-%d")
TOMORROW=$(date -u -v+1d +"%Y-%m-%d" 2>/dev/null || date -u -d tomorrow +"%Y-%m-%d")

# Get month-to-date costs
echo "📅 Month-to-Date Costs (${START_DATE} to ${END_DATE})"
echo "------------------------------------------------"
aws ce get-cost-and-usage \
    --time-period Start=$START_DATE,End=$TOMORROW \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --query 'ResultsByTime[0].Total.UnblendedCost.[Amount,Unit]' \
    --output text | awk '{printf "Total: $%.2f %s\n", $1, $2}'

echo ""
echo "📊 Cost Breakdown by Service"
echo "----------------------------"
aws ce get-cost-and-usage \
    --time-period Start=$START_DATE,End=$TOMORROW \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --query 'ResultsByTime[0].Groups[?Metrics.UnblendedCost.Amount > `0`].[Keys[0],Metrics.UnblendedCost.Amount]' \
    --output text | sort -k2 -rn | while read service cost; do
        printf "%-40s $%.2f\n" "$service" "$cost"
    done

# Get yesterday's costs
YESTERDAY=$(date -u -v-1d +"%Y-%m-%d" 2>/dev/null || date -u -d yesterday +"%Y-%m-%d")
echo ""
echo "📈 Yesterday's Costs (${YESTERDAY})"
echo "--------------------------------"
aws ce get-cost-and-usage \
    --time-period Start=$YESTERDAY,End=$END_DATE \
    --granularity DAILY \
    --metrics "UnblendedCost" \
    --query 'ResultsByTime[0].Total.UnblendedCost.[Amount,Unit]' \
    --output text | awk '{printf "Total: $%.2f %s\n", $1, $2}'

# Get forecasted costs
echo ""
echo "🔮 Forecasted Monthly Cost"
echo "-------------------------"
FORECAST=$(aws ce get-cost-forecast \
    --time-period Start=$TOMORROW,End=$(date -u -v+1m -v1d -v-1d +"%Y-%m-%d" 2>/dev/null || date -u -d "next month" +"%Y-%m-01" -d "-1 day" +"%Y-%m-%d") \
    --metric UNBLENDED_COST \
    --granularity MONTHLY \
    --query 'Total.Amount' \
    --output text 2>/dev/null || echo "0")
CURRENT=$(aws ce get-cost-and-usage \
    --time-period Start=$START_DATE,End=$TOMORROW \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text)
TOTAL_FORECAST=$(echo "$CURRENT + $FORECAST" | bc)
printf "Projected Total: $%.2f\n" $TOTAL_FORECAST

# Check Flight Tracker specific resources
echo ""
echo "🛩️  Flight Tracker Resource Status"
echo "---------------------------------"

# Check ECS tasks
echo -n "ECS Tasks Running: "
aws ecs list-tasks --cluster flight-tracker-cluster --query 'length(taskArns)' --output text

# Check ElastiCache status
echo -n "Redis Cache Status: "
aws elasticache describe-cache-clusters --cache-cluster-id flight-tracker-redis --query 'CacheClusters[0].CacheClusterStatus' --output text

# Check ALB status
echo -n "Load Balancer Status: "
aws elbv2 describe-load-balancers --names flight-tracker-alb --query 'LoadBalancers[0].State.Code' --output text

echo ""
echo "💡 Cost Saving Tips"
echo "------------------"
echo "1. Stop ECS tasks when not in use:"
echo "   aws ecs update-service --cluster flight-tracker-cluster --service flight-tracker-backend --desired-count 0"
echo ""
echo "2. Delete ElastiCache cluster overnight:"
echo "   aws elasticache delete-cache-cluster --cache-cluster-id flight-tracker-redis"
echo ""
echo "3. Use Fargate Spot for 70% savings:"
echo "   Update capacity provider in ECS service"
echo ""
echo "4. Monitor your costs at:"
echo "   https://console.aws.amazon.com/billing/"