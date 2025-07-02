#!/bin/bash

DISTRIBUTION_ID="EWPRBI0A74MVL"

echo "Monitoring CloudFront deployment status..."
echo ""

while true; do
    STATUS=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text)
    LAST_MODIFIED=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.LastModifiedTime' --output text)
    
    clear
    echo "CloudFront Distribution Status: $STATUS"
    echo "Last Modified: $LAST_MODIFIED"
    echo ""
    
    if [ "$STATUS" == "Deployed" ]; then
        echo "✅ CloudFront deployment completed!"
        echo ""
        echo "Your site should now be accessible at:"
        echo "- https://choppertracker.com"
        echo "- https://www.choppertracker.com"
        echo ""
        echo "Testing accessibility..."
        
        # Test the sites
        echo "Testing https://www.choppertracker.com..."
        curl -I -s https://www.choppertracker.com | head -1
        
        echo "Testing https://choppertracker.com..."
        curl -I -s https://choppertracker.com | head -1
        
        break
    else
        echo "⏳ CloudFront is still deploying... (checking every 60 seconds)"
        echo "This typically takes 15-20 minutes."
        echo "Press Ctrl+C to stop monitoring"
    fi
    
    sleep 60
done