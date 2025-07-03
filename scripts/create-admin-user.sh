#!/bin/bash

echo "👤 Creating Admin IAM User for Role Switching"
echo "============================================="

# Configuration
USER_NAME="jeff-admin"
MAIN_ACCOUNT="958933162000"

# Verify we're in the main account
echo "🔍 Verifying we're in the main account..."
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "$MAIN_ACCOUNT" ]; then
    echo "❌ ERROR: Not in main account. Current: $CURRENT_ACCOUNT, Expected: $MAIN_ACCOUNT"
    exit 1
fi

echo "✅ Confirmed main account: $CURRENT_ACCOUNT"

# Check if user already exists
echo ""
echo "🔍 Checking if user already exists..."
if aws iam get-user --user-name $USER_NAME >/dev/null 2>&1; then
    echo "✅ User $USER_NAME already exists"
    echo ""
    echo "📋 To create console access for this user:"
    echo "1. Go to IAM → Users → $USER_NAME"
    echo "2. Security credentials tab → Manage console access"
    echo "3. Enable console access and set password"
else
    echo "Creating new IAM user: $USER_NAME"
    
    # Create the user
    aws iam create-user --user-name $USER_NAME
    
    # Attach AdministratorAccess policy
    echo "Attaching AdministratorAccess policy..."
    aws iam attach-user-policy \
        --user-name $USER_NAME \
        --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
    
    echo "✅ User created with admin permissions"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Go to IAM in the AWS Console"
echo "2. Find user: $USER_NAME"
echo "3. Set up console password"
echo "4. Log out of root account"
echo "5. Log in as $USER_NAME"
echo "6. Then you can switch to the ChopperTracker role"
echo ""
echo "🔗 Direct link to IAM Users:"
echo "https://console.aws.amazon.com/iam/home?region=us-east-1#/users"
echo ""
echo "⚠️  IMPORTANT: Write down the password when you create it!"