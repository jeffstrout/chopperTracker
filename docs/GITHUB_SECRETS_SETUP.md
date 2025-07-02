# GitHub Secrets Setup for ChopperTracker Deployment

## Overview

The ChopperTracker deployment uses GitHub Actions with two different AWS accounts:
- **Choppertracker Account** (038342322731): Used for general deployment tasks
- **Main Account** (958933162000): Contains ECR, ECS, and other production resources

## Required GitHub Secrets

### 1. Choppertracker Account Credentials (Already Configured)
These are used for S3 frontend deployment:
- `AWS_ACCESS_KEY_ID`: Access key for choppertracker-github-deploy user
- `AWS_SECRET_ACCESS_KEY`: Secret key for choppertracker-github-deploy user

### 2. Main Account Credentials (Need to be Added)
These are required for ECR Docker image push:
- `MAIN_AWS_ACCESS_KEY_ID`: Access key for main account user with ECR permissions
- `MAIN_AWS_SECRET_ACCESS_KEY`: Secret key for main account user

## Setting Up Main Account Credentials

1. **Option A: Use existing flight-tracker-deploy user**
   - This user already has AdministratorAccess in the main account
   - Get credentials from AWS IAM console for user `flight-tracker-deploy`

2. **Option B: Create a dedicated ECR push user**
   ```bash
   # Create user
   aws iam create-user --user-name github-ecr-push
   
   # Attach ECR push policy
   aws iam attach-user-policy \
     --user-name github-ecr-push \
     --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
   
   # Create access key
   aws iam create-access-key --user-name github-ecr-push
   ```

## Adding Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add the following secrets:
   - Name: `MAIN_AWS_ACCESS_KEY_ID`
   - Value: [Your main account access key]
   
   - Name: `MAIN_AWS_SECRET_ACCESS_KEY`
   - Value: [Your main account secret key]

## Verification

After adding the secrets, the deployment will:
1. Use choppertracker account for S3 operations
2. Switch to main account credentials for ECR operations
3. Build and push Docker images with correct commit hash
4. Update ECS service with the new image

## Security Notes

- Keep these credentials secure and never commit them to the repository
- Consider using AWS IAM roles with OIDC for better security (future enhancement)
- Regularly rotate access keys
- Use least-privilege policies when possible