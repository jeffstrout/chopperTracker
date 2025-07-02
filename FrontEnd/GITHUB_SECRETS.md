# GitHub Secrets Configuration

To enable automated deployments, add these secrets to your GitHub repository:

## Required GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each:

### AWS Credentials
- **Name**: `AWS_ACCESS_KEY_ID`
- **Value**: Your AWS Access Key ID

- **Name**: `AWS_SECRET_ACCESS_KEY`
- **Value**: Your AWS Secret Access Key

### Frontend Configuration
- **Name**: `S3_BUCKET`
- **Value**: `flight-tracker-web-ui-1750266711`

- **Name**: `CLOUDFRONT_DISTRIBUTION_ID`
- **Value**: `EWPRBI0A74MVL`

- **Name**: `CLOUDFRONT_DOMAIN`
- **Value**: `d2ykgne47c9o7.cloudfront.net`

- **Name**: `VITE_API_BASE_URL`
- **Value**: `http://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com`

### Optional Configuration
- **Name**: `VITE_DEFAULT_REGION`
- **Value**: `etex`

- **Name**: `VITE_REFRESH_INTERVAL`
- **Value**: `15000`

## Verifying Deployment

After adding all secrets:
1. Push to main branch or run workflow manually
2. Check Actions tab for deployment status
3. Visit https://d2ykgne47c9o7.cloudfront.net to see your deployed app

## Current Infrastructure

- **S3 Bucket**: flight-tracker-web-ui-1750266711
- **CloudFront URL**: https://d2ykgne47c9o7.cloudfront.net
- **Region**: us-east-1