#!/bin/bash
# Migrate data from main account to ChopperTracker account
# Run this after setting up infrastructure in ChopperTracker account

set -e

echo "🚁 Starting migration to ChopperTracker account..."

# Check we have both account credentials
echo "Checking AWS credentials..."
echo "Current identity:"
aws sts get-caller-identity

# 1. Copy Docker images from old ECR to new ECR
echo ""
echo "🐳 Migrating Docker images..."
echo "Note: This requires docker to be running and credentials for both accounts"

OLD_ECR="958933162000.dkr.ecr.us-east-1.amazonaws.com/flight-tracker-backend"
NEW_ECR="038342322731.dkr.ecr.us-east-1.amazonaws.com/choppertracker-backend"

echo "To migrate Docker images manually:"
echo "1. Login to old ECR (main account):"
echo "   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $OLD_ECR"
echo ""
echo "2. Pull latest image:"
echo "   docker pull $OLD_ECR:latest"
echo ""
echo "3. Switch to ChopperTracker account credentials"
echo ""
echo "4. Login to new ECR:"
echo "   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $NEW_ECR"
echo ""
echo "5. Tag and push:"
echo "   docker tag $OLD_ECR:latest $NEW_ECR:latest"
echo "   docker push $NEW_ECR:latest"

# 2. Copy S3 frontend files
echo ""
echo "📦 Migrating frontend files..."
echo "This requires credentials for the main account to read from old bucket"

OLD_BUCKET="flight-tracker-web-ui-1750266711"
NEW_BUCKET="choppertracker-frontend"

echo "To migrate S3 files:"
echo "1. With main account credentials:"
echo "   aws s3 sync s3://$OLD_BUCKET /tmp/frontend-backup"
echo ""
echo "2. Switch to ChopperTracker account credentials"
echo ""
echo "3. Upload to new bucket:"
echo "   aws s3 sync /tmp/frontend-backup s3://$NEW_BUCKET"

# 3. Update GitHub secrets
echo ""
echo "🔐 Update GitHub Secrets..."
echo "Remove these secrets (no longer needed):"
echo "- MAIN_AWS_ACCESS_KEY_ID"
echo "- MAIN_AWS_SECRET_ACCESS_KEY"
echo ""
echo "Ensure these are set to ChopperTracker account credentials:"
echo "- AWS_ACCESS_KEY_ID"
echo "- AWS_SECRET_ACCESS_KEY"

# 4. DNS Update instructions
echo ""
echo "🌐 DNS Update Instructions..."
echo "After verifying the new infrastructure works:"
echo ""
echo "1. Get the new ALB DNS name:"
echo "   aws elbv2 describe-load-balancers --names choppertracker-alb --query 'LoadBalancers[0].DNSName' --output text"
echo ""
echo "2. In the main account Route 53:"
echo "   - Update 'choppertracker.com' A record to point to new ALB"
echo "   - Update 'api.choppertracker.com' A record to point to new ALB"
echo ""

# 5. Verification steps
echo ""
echo "✅ Verification Steps..."
echo "1. Test new S3 website: http://choppertracker-frontend.s3-website-us-east-1.amazonaws.com"
echo "2. Test new ALB health: http://[NEW-ALB-DNS]/health"
echo "3. Deploy via GitHub Actions to new infrastructure"
echo "4. Update DNS and test domains"

echo ""
echo "🎯 Migration checklist saved to: migration-checklist.txt"

cat > migration-checklist.txt << EOF
ChopperTracker Migration Checklist
==================================

[ ] 1. Run setup-choppertracker-infrastructure.sh in ChopperTracker account
[ ] 2. Migrate Docker images from old ECR to new ECR
[ ] 3. Copy frontend files from old S3 to new S3
[ ] 4. Update GitHub repository secrets
[ ] 5. Push code to trigger GitHub Actions deployment
[ ] 6. Verify new infrastructure is working
[ ] 7. Update Route 53 DNS records in main account
[ ] 8. Test domain names resolve to new infrastructure
[ ] 9. Monitor for 24 hours
[ ] 10. Delete old resources from main account

Old Resources to Delete (after migration):
- S3: flight-tracker-web-ui-1750266711
- ECR: flight-tracker-backend
- ECS: flight-tracker-cluster, flight-tracker-backend service
- ALB: flight-tracker-alb
- Security Groups: flight-tracker-*-sg
- CloudWatch Logs: /ecs/flight-tracker
EOF