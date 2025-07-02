#!/bin/bash

# Script to add choppertracker.com domains to CloudFront distribution

DISTRIBUTION_ID="EWPRBI0A74MVL"

echo "Getting current CloudFront configuration..."

# Get the current distribution config
aws cloudfront get-distribution-config --id $DISTRIBUTION_ID > /tmp/cloudfront-config.json

# Extract just the config portion and ETag
ETAG=$(jq -r '.ETag' /tmp/cloudfront-config.json)
jq '.DistributionConfig' /tmp/cloudfront-config.json > /tmp/distribution-config.json

# Check current aliases
echo "Current aliases:"
jq '.Aliases' /tmp/distribution-config.json

# Update the aliases to include choppertracker.com domains
echo "Adding choppertracker.com domains..."

# Also update the certificate
CERT_ARN="arn:aws:acm:us-east-1:958933162000:certificate/e0a1d79e-a9bb-4519-884a-5cf568238e0f"

jq --arg cert "$CERT_ARN" '.Aliases = {
    "Quantity": 2,
    "Items": [
        "www.choppertracker.com",
        "choppertracker.com"
    ]
} | .ViewerCertificate = {
    "ACMCertificateArn": $cert,
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021",
    "Certificate": $cert,
    "CertificateSource": "acm"
}' /tmp/distribution-config.json > /tmp/updated-config.json

echo "Updated aliases:"
jq '.Aliases' /tmp/updated-config.json

echo ""
echo "⚠️  WARNING: This update requires a valid SSL certificate for the domains."
echo "CloudFront needs an SSL certificate in AWS Certificate Manager (ACM) for custom domains."
echo ""
echo "Press Enter to continue with the update, or Ctrl+C to cancel..."
read

# Update the distribution
echo "Updating CloudFront distribution..."
aws cloudfront update-distribution \
    --id $DISTRIBUTION_ID \
    --distribution-config file:///tmp/updated-config.json \
    --if-match $ETAG

if [ $? -eq 0 ]; then
    echo "✅ CloudFront distribution updated successfully!"
    echo ""
    echo "Note: The changes may take 15-20 minutes to fully deploy."
    echo ""
    echo "Next steps:"
    echo "1. Wait for CloudFront deployment to complete"
    echo "2. Test access via https://www.choppertracker.com"
    echo "3. If HTTPS is needed, create an SSL certificate in ACM"
else
    echo "❌ Failed to update CloudFront distribution"
    echo "This might be because SSL certificate is required for custom domains."
    echo ""
    echo "To fix this:"
    echo "1. Go to AWS Certificate Manager (ACM) in us-east-1 region"
    echo "2. Request a certificate for:"
    echo "   - choppertracker.com"
    echo "   - www.choppertracker.com"
    echo "3. Validate the certificate (DNS or email validation)"
    echo "4. Run this script again after certificate is issued"
fi

# Cleanup
rm -f /tmp/cloudfront-config.json /tmp/distribution-config.json /tmp/updated-config.json