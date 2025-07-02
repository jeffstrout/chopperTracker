# ChopperTracker AWS Account Migration Guide

## Account Information
- **Main Account ID**: 958933162000
- **ChopperTracker Account ID**: 038342322731
- **ChopperTracker Account Email**: choppertracker@strout.us

## GitHub Actions Credentials
**IMPORTANT**: The AWS credentials have been provided separately for security.
Add them as GitHub secrets in your repository settings:
- **AWS_ACCESS_KEY_ID**: (provided separately)
- **AWS_SECRET_ACCESS_KEY**: (provided separately)
- **AWS_REGION**: `us-east-1` (or your preferred region)

## Migration Steps

### 1. Identify Current Resources
First, identify all ChopperTracker resources in your main account:
```bash
# S3 buckets
aws s3 ls | grep -i chopper

# CloudFront distributions
aws cloudfront list-distributions --query "DistributionList.Items[*].[Id,DomainName,Comment]" --output table

# Lambda functions
aws lambda list-functions --query "Functions[?contains(FunctionName, 'chopper') || contains(FunctionName, 'Chopper')].[FunctionName]" --output table

# DynamoDB tables
aws dynamodb list-tables | grep -i chopper

# API Gateway APIs
aws apigateway get-rest-apis --query "items[*].[id,name]" --output table
```

### 2. Export Data
Before migration, export any data:
```bash
# Export DynamoDB tables
aws dynamodb create-backup --table-name YOUR_TABLE_NAME --backup-name pre-migration-backup

# Download S3 bucket contents
aws s3 sync s3://YOUR-BUCKET-NAME ./backup/YOUR-BUCKET-NAME
```

### 3. Deploy to New Account
Update your deployment scripts to use the new account credentials and redeploy your infrastructure.

### 4. Update DNS/Domain Settings
If using Route53 or custom domains, update them to point to resources in the new account.

### 5. Verify and Test
- Test all application functionality
- Verify data integrity
- Check CloudWatch logs

### 6. Cleanup Old Resources
Once migration is verified, remove resources from the main account to avoid duplicate charges.

## Cross-Account Access
To access the ChopperTracker account from your main account:
```bash
aws sts assume-role \
  --role-arn arn:aws:iam::038342322731:role/OrganizationAccountAccessRole \
  --role-session-name MySession
```

## Billing
The ChopperTracker account will appear as a separate line item in your consolidated billing, making it easier to track costs.