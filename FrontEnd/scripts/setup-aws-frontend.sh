#!/bin/bash

# Flight Tracker Frontend AWS Setup Script
# This script creates the S3 bucket and CloudFront distribution for the frontend

set -e

# Configuration
BUCKET_NAME="flight-tracker-web-ui-$(date +%s)"
REGION="us-east-1"
CLOUDFRONT_COMMENT="Flight Tracker Web UI Distribution"

echo "🚀 Setting up AWS infrastructure for Flight Tracker Frontend"
echo "=================================================="

# Create S3 bucket
echo "📦 Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --acl private

# Enable static website hosting
echo "🌐 Configuring static website hosting"
aws s3 website "s3://$BUCKET_NAME" \
    --index-document index.html \
    --error-document index.html

# Create bucket policy for CloudFront access
echo "🔒 Setting up bucket policy"
cat > /tmp/bucket-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy file:///tmp/bucket-policy.json

# Create CloudFront Origin Access Control
echo "🔐 Creating CloudFront Origin Access Control"
OAC_ID=$(aws cloudfront create-origin-access-control \
    --origin-access-control-config \
    Name="flight-tracker-oac-$(date +%s)",Description="Flight Tracker OAC",SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3 \
    --query 'OriginAccessControl.Id' \
    --output text)

# Create CloudFront distribution
echo "☁️  Creating CloudFront distribution"
cat > /tmp/cloudfront-config.json <<EOF
{
    "CallerReference": "flight-tracker-$(date +%s)",
    "Comment": "$CLOUDFRONT_COMMENT",
    "DefaultRootObject": "index.html",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$BUCKET_NAME",
                "DomainName": "$BUCKET_NAME.s3.$REGION.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                },
                "OriginAccessControlId": "$OAC_ID"
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$BUCKET_NAME",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"]
        },
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "MinTTL": 0,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "Compress": true
    },
    "CustomErrorResponses": {
        "Quantity": 1,
        "Items": [
            {
                "ErrorCode": 404,
                "ResponsePagePath": "/index.html",
                "ResponseCode": "200",
                "ErrorCachingMinTTL": 300
            }
        ]
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100"
}
EOF

DISTRIBUTION_ID=$(aws cloudfront create-distribution \
    --distribution-config file:///tmp/cloudfront-config.json \
    --query 'Distribution.Id' \
    --output text)

CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution \
    --id "$DISTRIBUTION_ID" \
    --query 'Distribution.DomainName' \
    --output text)

# Save configuration
echo "💾 Saving configuration"
cat > .env.production <<EOF
# AWS Configuration (created by setup script)
VITE_API_BASE_URL=https://api.yourdomain.com
S3_BUCKET=$BUCKET_NAME
CLOUDFRONT_DISTRIBUTION_ID=$DISTRIBUTION_ID
CLOUDFRONT_DOMAIN=$CLOUDFRONT_DOMAIN
AWS_REGION=$REGION
EOF

# Clean up temp files
rm -f /tmp/bucket-policy.json /tmp/cloudfront-config.json

echo "✅ Frontend infrastructure setup complete!"
echo "=================================================="
echo "S3 Bucket: $BUCKET_NAME"
echo "CloudFront Distribution ID: $DISTRIBUTION_ID"
echo "CloudFront URL: https://$CLOUDFRONT_DOMAIN"
echo ""
echo "Configuration saved to .env.production"
echo ""
echo "Next steps:"
echo "1. Update VITE_API_BASE_URL in .env.production with your backend API URL"
echo "2. Run 'npm run build' to build the frontend"
echo "3. Deploy with: aws s3 sync dist/ s3://$BUCKET_NAME --delete"
echo "4. Invalidate cache: aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"