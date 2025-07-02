# DNS Setup Guide for choppertracker.com

## Current AWS Resources
- **Frontend (S3)**: http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com
- **Backend API (ALB)**: https://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com
- **CloudFront Distribution**: EWPRBI0A74MVL

## GoDaddy DNS Configuration

### Option 1: Simple HTTP Setup (Quickest)

**Important**: GoDaddy doesn't support CNAME records for root domains (@). Use this approach:

#### Step 1: Add DNS Records in GoDaddy

In GoDaddy DNS Management, add these records:

1. **Frontend - www.choppertracker.com**
   - Type: `CNAME`
   - Name: `www`
   - Value: `flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com`
   - TTL: 600 seconds

2. **Backend API - api.choppertracker.com**
   - Type: `CNAME`
   - Name: `api`
   - Value: `flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com`
   - TTL: 600 seconds

#### Step 2: Set Up Domain Forwarding for Root Domain

1. In GoDaddy, go to your domain settings
2. Find the "Forwarding" section
3. Set up forwarding:
   - Forward to: `http://www.choppertracker.com`
   - Forward type: `Permanent (301)`
   - Settings: `Forward with masking` (optional - keeps choppertracker.com in URL bar)

### Option 2: HTTPS Setup with CloudFront (Recommended)

To use HTTPS, you'll need to:

1. **Enable CloudFront for your S3 bucket**
   - Get the CloudFront domain name (format: `d1234567890.cloudfront.net`)
   - Configure CloudFront to serve from your S3 bucket
   - Add SSL certificate for choppertracker.com in AWS Certificate Manager

2. **Then add these DNS records in GoDaddy:**
   - Type: `CNAME`
   - Name: `@` and `www`
   - Value: `[your-cloudfront-distribution].cloudfront.net`
   - TTL: 1 hour

## After DNS Setup

### 1. Update CORS Configuration on S3 Bucket

Add choppertracker.com to allowed origins:

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "HEAD"],
        "AllowedOrigins": [
            "http://choppertracker.com",
            "http://www.choppertracker.com",
            "https://choppertracker.com",
            "https://www.choppertracker.com",
            "http://localhost:*"
        ],
        "ExposeHeaders": [],
        "MaxAgeSeconds": 3000
    }
]
```

### 2. Update Backend CORS Configuration

The backend API will also need to allow the new domain. Update your backend CORS settings to include:
- http://choppertracker.com
- http://www.choppertracker.com
- https://choppertracker.com (if using HTTPS)
- https://www.choppertracker.com (if using HTTPS)

### 3. Update Frontend API Configuration

Update the environment variable to use the new API domain:

```bash
VITE_API_BASE_URL=https://api.choppertracker.com
```

Or if staying with direct ALB access:
```bash
VITE_API_BASE_URL=https://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com
```

## DNS Propagation

- DNS changes can take 5 minutes to 48 hours to propagate globally
- You can check propagation status at: https://www.whatsmydns.net/
- Test with: `nslookup choppertracker.com`

## Troubleshooting

1. **CORS Errors**: Make sure both S3 and backend API have the new domain in their CORS policies
2. **404 Errors**: Ensure S3 bucket has index.html set as the index document
3. **SSL Errors**: If using HTTPS, you'll need to set up CloudFront with an SSL certificate

## Notes

- GoDaddy doesn't support ALIAS records for root domains pointing to AWS resources
- For HTTPS support, you must use CloudFront
- The backend API will remain HTTP unless you configure SSL on the ALB