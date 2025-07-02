# Backend Configuration Requirements for flightTrackerCollector

## Issue Summary
1. **Rate Limiting**: Frontend was hardcoded to 3-second refresh (1,200 requests/hour) vs intended 15-second (240 requests/hour)
2. **SSL/DNS**: Custom domain choppertracker.com configured but needs SSL certificate and proper CORS configuration
3. **Backend API**: Currently using direct ALB URL which doesn't have SSL enabled

## Frontend Fixes Completed ✅
1. **Fixed hardcoded refresh rate** in `src/App.tsx:35`
   - Changed from `refreshInterval: 3000` to `refreshInterval: parseInt(import.meta.env.VITE_REFRESH_INTERVAL || '15000', 10)`
   - Now respects `.env` configuration (15 seconds)
   
2. **Added exponential backoff** in `src/hooks/useFlightData.ts`
   - Handles 429 rate limit responses gracefully
   - Implements exponential backoff: 1s, 2s, 4s, 8s... up to 60s max
   - Automatically retries with increasing delays

## Current Domain Status
- **choppertracker.com**: Resolves to AWS (3.33.251.168, 15.197.225.128)
- **HTTP Redirect**: Working - redirects to S3 bucket
- **HTTPS**: Returns 405 Method Not Allowed (SSL certificate likely not configured)
- **Backend API**: http://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com (HTTP only)

## Backend Changes Required (flightTrackerCollector repository)

### 1. Enable HTTPS on ALB
```yaml
# Add HTTPS listener to ALB configuration
listeners:
  - protocol: HTTPS
    port: 443
    certificates:
      - certificate_arn: "arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID"
  - protocol: HTTP
    port: 80
    # Redirect HTTP to HTTPS
    default_actions:
      - type: redirect
        redirect:
          protocol: HTTPS
          port: 443
          status_code: HTTP_301
```

### 2. Update CORS Configuration
The backend needs to accept requests from both development and production domains:

```python
# Example CORS configuration update
ALLOWED_ORIGINS = [
    "http://localhost:5173",                    # Local development
    "http://localhost:3000",                    # Alternative local port
    "https://choppertracker.com",               # Production domain
    "https://www.choppertracker.com",           # WWW variant
    "http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com",  # S3 direct
    "https://d12345abcde.cloudfront.net"       # CloudFront distribution
]
```

### 3. Rate Limiting Configuration
Implement or verify rate limiting on the backend:

```python
# Example rate limiting (adjust based on your framework)
rate_limit_config = {
    "default": "240/hour",      # 15-second intervals
    "burst": "10/minute",       # Allow short bursts
    "per_ip": True,             # Rate limit per IP address
    "response_headers": {
        "X-RateLimit-Limit": "240",
        "X-RateLimit-Remaining": lambda req: calculate_remaining(req),
        "X-RateLimit-Reset": lambda req: calculate_reset_time(req)
    }
}
```

### 4. SSL Certificate Configuration
Two options for SSL:

#### Option A: Use ALB with ACM Certificate
1. Request/import certificate in AWS Certificate Manager for `choppertracker.com`
2. Attach certificate to ALB HTTPS listener
3. Update Route 53 to point choppertracker.com to ALB

#### Option B: Use CloudFront
1. Configure CloudFront distribution with custom domain
2. Use ACM certificate (must be in us-east-1 for CloudFront)
3. Set ALB as origin
4. Update Route 53 to point to CloudFront

### 5. Environment Variables Update
Update backend configuration:

```env
# Add to backend .env or configuration
ALLOWED_ORIGINS=choppertracker.com,www.choppertracker.com
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS_PER_HOUR=240
RATE_LIMIT_BURST_SIZE=10
ENABLE_HTTPS_REDIRECT=true
```

## Testing After Backend Updates

### 1. Test HTTPS/SSL
```bash
# Test SSL certificate
curl -I https://choppertracker.com
openssl s_client -connect choppertracker.com:443 -servername choppertracker.com

# Test API over HTTPS
curl https://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com/health
```

### 2. Test CORS
```bash
# Test CORS headers
curl -H "Origin: https://choppertracker.com" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: X-Requested-With" \
     -X OPTIONS \
     https://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com/api/v1/etex/flights
```

### 3. Test Rate Limiting
```bash
# Test rate limit responses
for i in {1..250}; do
  curl -w "Status: %{http_code}\n" \
       https://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com/api/v1/etex/flights \
       -o /dev/null -s
  sleep 0.1
done
```

## Frontend Configuration Updates (After Backend Changes)

Once the backend supports HTTPS, update the frontend `.env`:

```env
# Update to HTTPS once backend supports it
VITE_API_BASE_URL=https://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com

# Or use custom domain if configured
VITE_API_BASE_URL=https://api.choppertracker.com
```

## Priority Order
1. **High Priority**: Enable HTTPS on ALB (security requirement)
2. **High Priority**: Update CORS to include choppertracker.com domains
3. **Medium Priority**: Implement proper rate limiting with headers
4. **Low Priority**: Configure custom API subdomain (api.choppertracker.com)

## Cost Considerations
- ACM certificates are free
- HTTPS on ALB has minimal additional cost
- CloudFront may add ~$5-10/month but provides global edge caching
- Current setup at ~$42/month should remain relatively unchanged