#!/bin/bash

# Script to request SSL certificate for choppertracker.com

echo "Requesting SSL certificate for choppertracker.com domains..."
echo ""
echo "Note: This must be done in us-east-1 region for CloudFront"

# Request certificate
CERT_ARN=$(aws acm request-certificate \
    --domain-name choppertracker.com \
    --subject-alternative-names www.choppertracker.com \
    --validation-method DNS \
    --region us-east-1 \
    --query 'CertificateArn' \
    --output text)

if [ $? -eq 0 ]; then
    echo "✅ Certificate requested successfully!"
    echo "Certificate ARN: $CERT_ARN"
    echo ""
    echo "Next steps:"
    echo "1. Go to AWS Certificate Manager in the AWS Console (us-east-1 region)"
    echo "2. Find the certificate for choppertracker.com"
    echo "3. Click on the certificate"
    echo "4. You'll see DNS validation records that need to be added to GoDaddy"
    echo "5. Add the CNAME records shown in ACM to your GoDaddy DNS"
    echo "6. Wait for validation (usually 5-30 minutes)"
    echo "7. Once validated, run update-cloudfront-domains.sh again"
    echo ""
    echo "To check validation status:"
    echo "aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1"
else
    echo "❌ Failed to request certificate"
fi