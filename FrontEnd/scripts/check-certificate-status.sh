#!/bin/bash

CERT_ARN="arn:aws:acm:us-east-1:958933162000:certificate/e0a1d79e-a9bb-4519-884a-5cf568238e0f"

echo "Checking certificate validation status..."
echo ""

while true; do
    STATUS=$(aws acm describe-certificate \
        --certificate-arn $CERT_ARN \
        --region us-east-1 \
        --query 'Certificate.Status' \
        --output text)
    
    VALIDATION_STATUS=$(aws acm describe-certificate \
        --certificate-arn $CERT_ARN \
        --region us-east-1 \
        --query 'Certificate.DomainValidationOptions[*].[DomainName,ValidationStatus]' \
        --output table)
    
    clear
    echo "Certificate Status: $STATUS"
    echo ""
    echo "Domain Validation Status:"
    echo "$VALIDATION_STATUS"
    
    if [ "$STATUS" == "ISSUED" ]; then
        echo ""
        echo "✅ Certificate is validated and issued!"
        echo ""
        echo "Next step: Run ./scripts/update-cloudfront-domains.sh to add the domains to CloudFront"
        break
    else
        echo ""
        echo "⏳ Waiting for validation... (checking every 30 seconds)"
        echo "Press Ctrl+C to stop monitoring"
    fi
    
    sleep 30
done