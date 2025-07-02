#!/bin/bash

# Create a redirect bucket for www.choppertracker.com
BUCKET_NAME="www.choppertracker.com"
TARGET_URL="http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com"

echo "Creating S3 bucket for redirect: $BUCKET_NAME"

# Create bucket
aws s3 mb s3://$BUCKET_NAME --region us-east-1

# Enable static website hosting with redirect
aws s3 website s3://$BUCKET_NAME \
    --redirect-all-requests-to "HostName=$TARGET_URL" \
    --region us-east-1

# Set bucket policy for public access
cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket $BUCKET_NAME \
    --policy file:///tmp/bucket-policy.json \
    --region us-east-1

# Remove public block
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
    --region us-east-1

echo ""
echo "✅ Redirect bucket created!"
echo ""
echo "Now update GoDaddy DNS:"
echo "Change the www CNAME to: $BUCKET_NAME.s3-website-us-east-1.amazonaws.com"

rm /tmp/bucket-policy.json