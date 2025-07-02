#!/bin/bash
# Build and push Docker image to ECR
# This script should be run from the main AWS account (958933162000)

set -e

echo "Building and pushing Docker image to ECR..."

# Get current commit info
COMMIT_HASH=$(git rev-parse --short HEAD)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ECR_URI="958933162000.dkr.ecr.us-east-1.amazonaws.com/flight-tracker-backend"

echo "Commit: $COMMIT_HASH"
echo "Build time: $BUILD_TIME"
echo "ECR URI: $ECR_URI"

# Get ECR login token
echo "Logging into ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI

# Build Docker image
echo "Building Docker image..."
cd BackEnd
docker build \
  --build-arg COMMIT_HASH=$COMMIT_HASH \
  --build-arg BUILD_TIME=$BUILD_TIME \
  -t $ECR_URI:latest \
  -t $ECR_URI:$COMMIT_HASH \
  .

# Push to ECR
echo "Pushing to ECR..."
docker push $ECR_URI:latest
docker push $ECR_URI:$COMMIT_HASH

echo "✅ Successfully built and pushed $ECR_URI:$COMMIT_HASH"
echo ""
echo "To deploy this image, the ECS service will be updated to use: $ECR_URI:latest"