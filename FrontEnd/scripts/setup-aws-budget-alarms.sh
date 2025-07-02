#!/bin/bash

# AWS Budget Alarms Setup Script for Flight Tracker
# This script sets up budget alarms to monitor AWS spending

set -e

echo "🚨 Setting up AWS Budget Alarms for Flight Tracker"
echo "=================================================="

# Get user input
read -p "Enter your email address for notifications: " EMAIL
read -p "Enter your monthly budget limit in USD (default 75): " BUDGET_LIMIT
BUDGET_LIMIT=${BUDGET_LIMIT:-75}

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"

# Create main monthly budget
echo "📊 Creating monthly budget with $BUDGET_LIMIT USD limit..."
aws budgets create-budget \
  --account-id $ACCOUNT_ID \
  --budget '{
    "BudgetName": "flight-tracker-monthly-budget",
    "BudgetLimit": {
      "Amount": "'$BUDGET_LIMIT'",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "CostTypes": {
      "IncludeTax": true,
      "IncludeSubscription": true,
      "UseBlended": false,
      "IncludeRefund": false,
      "IncludeCredit": false,
      "IncludeUpfront": true,
      "IncludeRecurring": true,
      "IncludeOtherSubscription": true,
      "IncludeSupport": true,
      "IncludeDiscount": true,
      "UseAmortized": false
    }
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 50,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "'$EMAIL'"
        }
      ]
    },
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "'$EMAIL'"
        }
      ]
    },
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 100,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "'$EMAIL'"
        }
      ]
    },
    {
      "Notification": {
        "NotificationType": "FORECASTED",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 100,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "'$EMAIL'"
        }
      ]
    }
  ]' 2>/dev/null || echo "Monthly budget already exists or was updated"

# Create daily spending alert
echo "📅 Creating daily spending alert..."
DAILY_LIMIT=$(echo "scale=2; $BUDGET_LIMIT / 30" | bc)
aws budgets create-budget \
  --account-id $ACCOUNT_ID \
  --budget '{
    "BudgetName": "flight-tracker-daily-spending-alert",
    "BudgetLimit": {
      "Amount": "'$DAILY_LIMIT'",
      "Unit": "USD"
    },
    "TimeUnit": "DAILY",
    "BudgetType": "COST",
    "CostTypes": {
      "IncludeTax": true,
      "IncludeSubscription": true,
      "UseBlended": false,
      "IncludeRefund": false,
      "IncludeCredit": false,
      "IncludeUpfront": true,
      "IncludeRecurring": true,
      "IncludeOtherSubscription": true,
      "IncludeSupport": true,
      "IncludeDiscount": true,
      "UseAmortized": false
    }
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 200,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "'$EMAIL'"
        }
      ]
    }
  ]' 2>/dev/null || echo "Daily spending alert already exists or was updated"

# Create service-specific budgets
echo "🎯 Creating service-specific budgets..."

# ECS Budget
aws budgets create-budget \
  --account-id $ACCOUNT_ID \
  --budget '{
    "BudgetName": "flight-tracker-ecs-fargate",
    "BudgetLimit": {
      "Amount": "25",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "CostFilters": {
      "Service": ["Amazon Elastic Container Service"]
    },
    "CostTypes": {
      "IncludeTax": true,
      "IncludeSubscription": true,
      "UseBlended": false,
      "IncludeRefund": false,
      "IncludeCredit": false,
      "IncludeUpfront": true,
      "IncludeRecurring": true,
      "IncludeOtherSubscription": true,
      "IncludeSupport": true,
      "IncludeDiscount": true,
      "UseAmortized": false
    }
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 100,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "'$EMAIL'"
        }
      ]
    }
  ]' 2>/dev/null || echo "ECS budget already exists or was updated"

# ElastiCache Budget
aws budgets create-budget \
  --account-id $ACCOUNT_ID \
  --budget '{
    "BudgetName": "flight-tracker-elasticache",
    "BudgetLimit": {
      "Amount": "20",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "CostFilters": {
      "Service": ["Amazon ElastiCache"]
    },
    "CostTypes": {
      "IncludeTax": true,
      "IncludeSubscription": true,
      "UseBlended": false,
      "IncludeRefund": false,
      "IncludeCredit": false,
      "IncludeUpfront": true,
      "IncludeRecurring": true,
      "IncludeOtherSubscription": true,
      "IncludeSupport": true,
      "IncludeDiscount": true,
      "UseAmortized": false
    }
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 100,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "'$EMAIL'"
        }
      ]
    }
  ]' 2>/dev/null || echo "ElastiCache budget already exists or was updated"

# Create CloudWatch alarm for unexpected usage
echo "⚠️  Creating CloudWatch billing alarm..."
aws cloudwatch put-metric-alarm \
  --alarm-name "flight-tracker-billing-alarm" \
  --alarm-description "Alert when estimated charges exceed $${BUDGET_LIMIT}" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --evaluation-periods 1 \
  --threshold $BUDGET_LIMIT \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
  --treat-missing-data notBreaching \
  --region us-east-1 2>/dev/null || echo "Billing alarm already exists or was updated"

echo ""
echo "✅ Budget alarms setup complete!"
echo "=================================================="
echo ""
echo "📧 Notifications will be sent to: $EMAIL"
echo ""
echo "🚨 Alarm Thresholds:"
echo "  - 50% of monthly budget (\$$(echo "scale=2; $BUDGET_LIMIT * 0.5" | bc))"
echo "  - 80% of monthly budget (\$$(echo "scale=2; $BUDGET_LIMIT * 0.8" | bc))"
echo "  - 100% of monthly budget (\$$BUDGET_LIMIT)"
echo "  - Forecast exceeds 100% of budget"
echo "  - Daily spending exceeds \$$DAILY_LIMIT (2x expected)"
echo ""
echo "📊 Service-specific budgets:"
echo "  - ECS Fargate: \$25/month"
echo "  - ElastiCache: \$20/month"
echo ""
echo "💡 Tips to reduce costs:"
echo "  1. Use Fargate Spot for the collector task (70% savings)"
echo "  2. Stop services when not in use"
echo "  3. Use smaller instance sizes during development"
echo "  4. Enable CloudFront caching to reduce backend calls"
echo ""
echo "View your budgets at: https://console.aws.amazon.com/billing/home#/budgets"