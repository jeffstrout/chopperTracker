#!/bin/bash

# Script to update CORS configuration for choppertracker.com
# This updates the S3 bucket CORS policy to allow the new domain

BUCKET_NAME="flight-tracker-web-ui-1750266711"
REGION="us-east-1"

# Create CORS configuration file
cat > /tmp/cors-config.json << 'EOF'
{
    "CORSRules": [
        {
            "AllowedHeaders": ["*"],
            "AllowedMethods": ["GET", "HEAD", "PUT", "POST", "DELETE"],
            "AllowedOrigins": [
                "http://www.choppertracker.com",
                "https://www.choppertracker.com",
                "http://choppertracker.com",
                "https://choppertracker.com",
                "http://api.choppertracker.com",
                "https://api.choppertracker.com",
                "http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com",
                "http://localhost:3000",
                "http://localhost:5173"
            ],
            "ExposeHeaders": [
                "ETag",
                "x-amz-version-id"
            ],
            "MaxAgeSeconds": 3000
        }
    ]
}
EOF

echo "Updating CORS configuration for S3 bucket: $BUCKET_NAME"

# Apply CORS configuration to S3 bucket
aws s3api put-bucket-cors \
    --bucket $BUCKET_NAME \
    --cors-configuration file:///tmp/cors-config.json \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ CORS configuration updated successfully!"
    echo ""
    echo "Allowed origins now include:"
    echo "  - http://choppertracker.com"
    echo "  - http://www.choppertracker.com"
    echo "  - https://choppertracker.com"
    echo "  - https://www.choppertracker.com"
    echo "  - http://api.choppertracker.com"
else
    echo "❌ Failed to update CORS configuration"
    exit 1
fi

# Clean up
rm /tmp/cors-config.json

echo ""
echo "Next steps:"
echo "1. Configure DNS records in GoDaddy as per DNS_SETUP_GUIDE.md"
echo "2. Update backend CORS configuration to allow choppertracker.com"
echo "3. Update frontend .env to use new API URL (if using api.choppertracker.com)"
echo "4. Wait for DNS propagation (5 minutes to 48 hours)"