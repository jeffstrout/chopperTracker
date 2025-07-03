#!/bin/bash

echo "🔐 Creating OrganizationAccountAccessRole in ChopperTracker account"
echo "=================================================================="

# Configuration
MAIN_ACCOUNT="958933162000"
CHOPPERTRACKER_ACCOUNT="038342322731"
ROLE_NAME="OrganizationAccountAccessRole"

# Verify we're in the main account
echo "🔍 Verifying we're in the main account..."
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "$MAIN_ACCOUNT" ]; then
    echo "❌ ERROR: Not in main account. Current: $CURRENT_ACCOUNT, Expected: $MAIN_ACCOUNT"
    exit 1
fi

echo "✅ Confirmed main account: $CURRENT_ACCOUNT"

# Create the trust policy for the role
echo ""
echo "📝 Creating trust policy for cross-account access..."
cat > /tmp/org-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${MAIN_ACCOUNT}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role in the ChopperTracker account using organization management
echo ""
echo "🏗️ Creating role in ChopperTracker account..."

# Note: AWS Organizations automatically creates this role when creating accounts,
# but if it doesn't exist, we need to use a different approach

# First, let's check if we can already assume the role
echo "Testing if OrganizationAccountAccessRole already exists..."
if aws sts assume-role \
    --role-arn "arn:aws:iam::${CHOPPERTRACKER_ACCOUNT}:role/${ROLE_NAME}" \
    --role-session-name "test-session" >/dev/null 2>&1; then
    echo "✅ Role already exists! You can switch to it."
else
    echo "❌ Role doesn't exist or can't be assumed."
    echo ""
    echo "The OrganizationAccountAccessRole should have been created automatically"
    echo "when the account was created through AWS Organizations."
    echo ""
    echo "Alternative options:"
    echo "1. Reset the root password for choppertracker@strout.us"
    echo "2. Contact AWS Support to help with account access"
fi

echo ""
echo "📋 To switch to the ChopperTracker account in the AWS Console:"
echo "1. Click your username in the top-right corner"
echo "2. Select 'Switch Role'"
echo "3. Enter:"
echo "   - Account: ${CHOPPERTRACKER_ACCOUNT}"
echo "   - Role: ${ROLE_NAME}"
echo "   - Display Name: ChopperTracker"
echo ""
echo "Or use this direct link:"
echo "https://signin.aws.amazon.com/switchrole?roleName=${ROLE_NAME}&account=${CHOPPERTRACKER_ACCOUNT}&displayName=ChopperTracker"

# Clean up
rm -f /tmp/org-trust-policy.json