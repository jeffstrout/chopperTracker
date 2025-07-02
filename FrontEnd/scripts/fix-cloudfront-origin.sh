#!/bin/bash

# Fix CloudFront origin to use S3 website endpoint instead of S3 bucket

DISTRIBUTION_ID="EWPRBI0A74MVL"
S3_WEBSITE_ENDPOINT="flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com"

echo "Fixing CloudFront origin configuration..."

# Get current distribution config
aws cloudfront get-distribution-config --id $DISTRIBUTION_ID > /tmp/cloudfront-config.json

# Extract ETag and config
ETAG=$(jq -r '.ETag' /tmp/cloudfront-config.json)
jq '.DistributionConfig' /tmp/cloudfront-config.json > /tmp/distribution-config.json

echo "Current origin:"
jq '.Origins.Items[0].DomainName' /tmp/distribution-config.json

# Update origin to use website endpoint
jq --arg endpoint "$S3_WEBSITE_ENDPOINT" '
.Origins.Items[0] = {
    "Id": "S3-flight-tracker-web-ui-1750266711",
    "DomainName": $endpoint,
    "OriginPath": "",
    "CustomHeaders": {
        "Quantity": 0
    },
    "CustomOriginConfig": {
        "HTTPPort": 80,
        "HTTPSPort": 443,
        "OriginProtocolPolicy": "http-only",
        "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
        },
        "OriginReadTimeout": 30,
        "OriginKeepaliveTimeout": 5
    },
    "ConnectionAttempts": 3,
    "ConnectionTimeout": 10,
    "OriginShield": {
        "Enabled": false
    }
}' /tmp/distribution-config.json > /tmp/updated-config.json

echo "Updated origin:"
jq '.Origins.Items[0].DomainName' /tmp/updated-config.json

# Update the distribution
echo "Updating CloudFront distribution..."
aws cloudfront update-distribution \
    --id $DISTRIBUTION_ID \
    --distribution-config file:///tmp/updated-config.json \
    --if-match $ETAG

if [ $? -eq 0 ]; then
    echo "✅ CloudFront origin updated successfully!"
    echo ""
    echo "The distribution is now deploying with the S3 website endpoint."
    echo "This will fix SPA routing and should resolve Safari compatibility issues."
    echo ""
    echo "Deployment will take 15-20 minutes to complete."
else
    echo "❌ Failed to update CloudFront distribution"
fi

# Cleanup
rm -f /tmp/cloudfront-config.json /tmp/distribution-config.json /tmp/updated-config.json