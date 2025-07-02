#!/bin/bash
# Fix S3 cross-account access for GitHub Actions deployment
# This script updates the S3 bucket policy to allow the GitHub Actions user from the sub-account
# to deploy frontend files to the production S3 bucket

BUCKET_NAME="flight-tracker-web-ui-1750266711"
GITHUB_USER_ARN="arn:aws:iam::038342322731:user/choppertracker-github-deploy"

echo "Fixing S3 cross-account access for GitHub Actions..."
echo "Bucket: $BUCKET_NAME"
echo "GitHub User: $GITHUB_USER_ARN"

# Apply the bucket policy
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://s3-bucket-policy.json

echo "✅ S3 bucket policy updated successfully!"
echo ""
echo "The following permissions were granted to $GITHUB_USER_ARN:"
echo "  - s3:ListBucket (list objects)"
echo "  - s3:GetBucketLocation (get bucket region)"
echo "  - s3:PutObject (upload files)"
echo "  - s3:PutObjectAcl (set file permissions)"
echo "  - s3:GetObject (read files)"
echo "  - s3:DeleteObject (delete files for --delete sync)"
echo ""
echo "GitHub Actions should now be able to deploy frontend files successfully!"