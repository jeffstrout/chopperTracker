# Flight Tracker Production Testing Guide

## Overview

This directory contains comprehensive testing scripts designed to validate your Flight Tracker production environment on AWS. All tests run against live production infrastructure and provide detailed health, performance, and data quality validation.

## Quick Start

```bash
# Clone and navigate to the project
cd /Users/jeffstrout/Projects/flightTrackerWebUI

# Quick health check (10 seconds)
./test-quick.sh

# Comprehensive test suite (2-3 minutes)
./test-production-complete.sh
```

## Available Testing Scripts

### 1. `test-production-complete.sh` - Comprehensive Testing Suite

**Purpose**: Complete validation of production environment including infrastructure, API endpoints, frontend, and performance testing.

**Features**:
- 🏗️ **Infrastructure Health**: AWS ECS, Redis, S3, Load Balancer status
- 🌐 **API Testing**: All 18+ endpoints with response validation
- 💻 **Frontend Validation**: Domain forwarding, CORS, asset loading
- ⚡ **Performance Testing**: Response times, concurrent requests, load testing
- 📊 **Data Quality**: Live flight data validation and helicopter detection
- 📋 **Detailed Reporting**: JSON results file with metrics and timing

**Usage**:
```bash
./test-production-complete.sh
```

**Sample Output**:
```
🚀 Flight Tracker Production Test Suite
========================================

🔍 Checking Dependencies
==================================================
✅ AWS CLI: Available (45ms)
✅ curl: Available (12ms)
✅ jq: Available (8ms)
✅ AWS Credentials: Account: 958933162000 (234ms)

🔧 Infrastructure Health Tests
==================================================
✅ ECS Service: 2/2 tasks running (567ms)
✅ Redis Cache: Status: available (345ms)
✅ S3 Bucket: 234 objects, 1.2 MiB (123ms)

🌐 API Endpoint Tests
==================================================
✅ Health Check: HTTP 200, 89ms response (156ms)
✅ Regions Endpoint: 3 regions available (234ms)
✅ Flights Endpoint: 47 aircraft found (445ms)
✅ Helicopters Endpoint: 12 helicopters found (398ms)
✅ Status Endpoint: HTTP 200, 156ms response (189ms)
✅ CSV Export: Tabular data available (567ms)

💻 Frontend Tests
==================================================
✅ Domain Redirect: HTTP 301 to S3 (234ms)
✅ S3 Website: HTTP 200, 118KB loaded (567ms)
✅ CORS Preflight: HTTP 200, cross-origin enabled (123ms)

⚡ Performance Tests
==================================================
✅ Concurrent Requests: 5/5 successful, avg 1.234s (2345ms)
✅ Data Freshness: Last collection 2m ago (89ms)

📊 Test Summary
==================================================
Test Results:
  ✅ Passed: 15
  ❌ Failed: 0
  ⚠️  Warnings: 1
  📊 Total: 16 tests
  ⏱️  Duration: 8s

🎯 Overall Status: HEALTHY with warnings

📋 Detailed results saved to: test-results-2025-06-30-142335.json

Production URLs:
  🌐 Main App: http://choppertracker.com
  📱 S3 Direct: http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com
  🔗 API: http://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com
```

### 2. `test-quick.sh` - Rapid Health Check

**Purpose**: Fast validation of core production services for daily monitoring.

**Features**:
- ⚡ **Speed**: Completes in ~10 seconds
- 🎯 **Essential Checks**: API health, flight data availability, frontend status
- 🔍 **Minimal Dependencies**: Works with basic curl and jq

**Usage**:
```bash
./test-quick.sh
```

**Sample Output**:
```
🚀 Quick Production Health Check
================================
🔍 API Health... ✅ OK
✈️  Flight Data... ✅ 47 aircraft
🌐 Frontend... ✅ HTTP 301

For comprehensive testing run: ./test-production-complete.sh
```

## Production Environment Details

### Infrastructure Under Test

**AWS Services**:
- **ECS Cluster**: `flight-tracker-cluster`
- **ECS Service**: `flight-tracker-backend`
- **Application Load Balancer**: `flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com`
- **ElastiCache Redis**: `flight-tracker-redis`
- **S3 Bucket**: `flight-tracker-web-ui-1750266711`
- **Region**: `us-east-1`

**Production URLs**:
- **Main Application**: http://choppertracker.com
- **S3 Direct Access**: http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com
- **API Endpoint**: http://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com
- **Default Test Region**: `etex` (East Texas)

### API Endpoints Tested

The comprehensive test suite validates all production API endpoints:

**Core Data Endpoints**:
- `GET /health` - Basic health check
- `GET /api/v1/status` - System status and metrics
- `GET /api/v1/regions` - Available data collection regions
- `GET /api/v1/{region}/flights` - All aircraft data for region
- `GET /api/v1/{region}/choppers` - Helicopter-only data for region
- `GET /api/v1/{region}/stats` - Regional statistics
- `GET /api/v1/{region}/flights/tabular` - CSV export of flight data
- `GET /api/v1/{region}/choppers/tabular` - CSV export of helicopter data

**Admin & Monitoring Endpoints**:
- `GET /api/v1/costs/current` - Current AWS costs
- `GET /api/v1/costs/daily` - Daily cost breakdown
- `GET /api/v1/costs/budget` - Budget status
- `GET /api/v1/costs/forecast` - Cost forecasting
- `GET /api/v1/costs/summary` - Cost summary
- `GET /admin/api-keys/stats` - API key usage statistics
- `GET /admin/region` - Admin region information

**Debug Endpoints**:
- `GET /debug/memory` - Memory usage information
- `GET /debug/logs-info` - Log file information
- `GET /logs` - Application logs (with pagination)

## Prerequisites

### Required Tools

**Automatically Checked/Installed**:
- **AWS CLI**: Used for infrastructure testing (must be pre-configured)
- **curl**: HTTP request testing (usually pre-installed on macOS)
- **jq**: JSON parsing (auto-installed via Homebrew if missing)
- **bc**: Mathematical calculations (usually pre-installed on macOS)

**Optional Enhancements**:
- **gdate**: High-precision timing (install via `brew install coreutils`)
- **Homebrew**: For automatic dependency installation

### AWS Configuration

The scripts use your existing AWS CLI configuration. Ensure you have:

1. **AWS CLI Installed**: `aws --version`
2. **Credentials Configured**: `aws configure list`
3. **Permissions**: Same permissions used for GitHub Actions deployment
4. **Account Access**: Access to account `958933162000` (your production account)

**Required AWS Permissions**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeServices",
                "ecs:DescribeClusters",
                "elasticache:DescribeCacheClusters",
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

## Test Categories Explained

### 1. Infrastructure Health Tests

**Purpose**: Validate AWS infrastructure components are operational

**Tests Performed**:
- **ECS Service Status**: Verifies desired vs running task count
- **Redis Cache Availability**: Confirms ElastiCache cluster is accessible
- **S3 Bucket Access**: Validates frontend deployment bucket
- **Credential Validation**: Confirms AWS access and account identity

**Success Criteria**:
- ECS service has desired number of running tasks
- Redis cluster status is "available"
- S3 bucket is accessible with deployed content
- AWS credentials are valid and have necessary permissions

### 2. API Endpoint Tests

**Purpose**: Validate all REST API endpoints return correct responses

**Tests Performed**:
- **HTTP Status Codes**: Ensures endpoints return 200 OK
- **Response Content**: Validates JSON structure and data presence
- **Response Times**: Measures API performance
- **Data Validation**: Confirms flight and helicopter data is current

**Success Criteria**:
- All endpoints return HTTP 200
- Response times under 2 seconds (warning if slower)
- Valid JSON responses with expected data structure
- Non-zero aircraft data (when available)

### 3. Frontend Tests

**Purpose**: Validate web application is accessible and functional

**Tests Performed**:
- **Domain Forwarding**: Tests choppertracker.com → S3 redirect
- **S3 Website Access**: Direct access to static website
- **CORS Validation**: Cross-origin request handling
- **Asset Loading**: Confirms JavaScript/CSS assets load correctly

**Success Criteria**:
- Domain forwarding works (HTTP 301/302 redirect)
- S3 website returns HTTP 200 with content
- CORS preflight requests succeed
- Frontend assets load without errors

### 4. Performance Tests

**Purpose**: Validate system performance under realistic load

**Tests Performed**:
- **Concurrent Requests**: Multiple simultaneous API calls
- **Response Time Analysis**: Average and maximum response times
- **Data Freshness**: Validates data collection is current
- **Load Capacity**: Tests system behavior under stress

**Success Criteria**:
- Concurrent requests complete successfully
- Average response times under acceptable thresholds
- Data collection within last 5 minutes
- No performance degradation under load

## Interpreting Results

### Exit Codes

- **0**: All tests passed
- **1**: One or more tests failed (critical issues)
- **2**: Tests passed with warnings (monitor recommended)

### Status Indicators

- **✅ PASS**: Test completed successfully
- **❌ FAIL**: Test failed (requires immediate attention)
- **⚠️ WARN**: Test passed with concerns (monitor recommended)

### JSON Results File

Each comprehensive test run generates a detailed JSON results file:

```json
{
  "timestamp": "2025-06-30T14:23:35Z",
  "environment": "production",
  "tests": {
    "health_check": {
      "status": "PASS",
      "details": "HTTP 200, 89ms response",
      "time_ms": 156
    },
    "ecs_service": {
      "status": "PASS",
      "details": "2/2 tasks running",
      "time_ms": 567
    }
  },
  "summary": {
    "passed": 15,
    "failed": 0,
    "warnings": 1,
    "total": 16,
    "duration_seconds": 8
  }
}
```

## Troubleshooting

### Common Issues

**AWS CLI Not Configured**:
```bash
Error: AWS Credentials: Not configured
Solution: Run 'aws configure' with your access keys
```

**Missing Dependencies**:
```bash
Error: jq: Not available
Solution: Install via 'brew install jq' or let script auto-install
```

**API Connection Failures**:
```bash
Error: Health Check: HTTP 000
Solution: Check if ECS service is running and ALB is healthy
```

**Permission Denied**:
```bash
Error: ECS Service: Cannot access service status
Solution: Verify IAM permissions for ECS describe operations
```

### Debug Mode

For detailed debugging, run with verbose output:

```bash
# Enable curl verbose output
export CURL_VERBOSE=1
./test-production-complete.sh

# Enable AWS CLI debug output
export AWS_DEBUG=1
./test-production-complete.sh
```

## Automation and Monitoring

### Scheduled Testing

Set up automated testing via cron:

```bash
# Edit crontab
crontab -e

# Add hourly production checks
0 * * * * cd /Users/jeffstrout/Projects/flightTrackerWebUI && ./test-quick.sh >> /var/log/flight-tracker-health.log 2>&1

# Add daily comprehensive testing
0 6 * * * cd /Users/jeffstrout/Projects/flightTrackerWebUI && ./test-production-complete.sh >> /var/log/flight-tracker-comprehensive.log 2>&1
```

### Alerting Integration

**Slack Integration Example**:
```bash
#!/bin/bash
# slack-alert.sh
if ! ./test-production-complete.sh; then
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"🚨 Flight Tracker production tests failed!"}' \
        YOUR_SLACK_WEBHOOK_URL
fi
```

**Email Alerts Example**:
```bash
#!/bin/bash
# email-alert.sh
if ! ./test-quick.sh > /tmp/test-results.txt 2>&1; then
    mail -s "Flight Tracker Alert" admin@yourcompany.com < /tmp/test-results.txt
fi
```

### CI/CD Integration

Add post-deployment testing to GitHub Actions:

```yaml
# .github/workflows/post-deployment-test.yml
name: Post-Deployment Testing
on:
  workflow_run:
    workflows: ["Deploy Backend to AWS", "Deploy Frontend to AWS"]
    types: [completed]

jobs:
  test-production:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - name: Run production tests
        run: ./test-production-complete.sh
```

## Performance Benchmarks

### Expected Response Times

**API Endpoints**:
- Health check: < 200ms
- Flight data: < 1000ms
- Status endpoint: < 500ms
- CSV export: < 2000ms

**Infrastructure**:
- ECS service check: < 1000ms
- Redis status: < 500ms
- S3 bucket access: < 300ms

**Frontend**:
- S3 website load: < 1000ms
- Domain redirect: < 500ms

### Concurrent Load Capacity

**Tested Scenarios**:
- 5 concurrent API requests: Should complete successfully
- Average response time: Should remain under 2 seconds
- Success rate: 100% for healthy system

## Security Considerations

### Data Exposure

- **No Sensitive Data**: Tests only read public endpoints
- **Read-Only Operations**: No data modification or creation
- **AWS Permissions**: Minimal read-only AWS access required

### Network Security

- **HTTPS Validation**: Tests CORS and security headers
- **Origin Checking**: Validates cross-origin request handling
- **Rate Limiting**: Respects API rate limits during testing

## Contributing

### Adding New Tests

1. **Add Test Function**: Follow existing pattern in scripts
2. **Update Documentation**: Document new test cases here
3. **Update Exit Codes**: Ensure proper result reporting
4. **Test Thoroughly**: Validate against production environment

### Test Function Template

```bash
test_new_feature() {
    print_header "🆕 New Feature Tests"
    
    local start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    # Your test logic here
    local result="success or failure"
    
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [ "$result" = "success" ]; then
        print_test "PASS" "New Feature" "Test details" $((end_time - start_time))
    else
        print_test "FAIL" "New Feature" "Error details" $((end_time - start_time))
    fi
}
```

## Support

For issues with the testing scripts:

1. **Check Prerequisites**: Ensure all dependencies are installed
2. **Verify AWS Access**: Confirm credentials and permissions
3. **Review Logs**: Check detailed JSON results for specific errors
4. **Update Scripts**: Ensure you have the latest version

The testing scripts are designed to provide comprehensive validation of your Flight Tracker production environment while being easy to use and maintain.