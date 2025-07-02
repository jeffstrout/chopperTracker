# Flight Tracker Production Testing Scripts

> **One-command testing for your entire AWS production environment**

## Quick Start

```bash
# Quick health check (10 seconds)
./test-quick.sh

# Comprehensive testing (2-3 minutes)  
./test-production-complete.sh
```

## What Gets Tested

### 🏗️ AWS Infrastructure
- **ECS Service**: Task health and desired vs running count
- **Redis Cache**: ElastiCache cluster availability 
- **S3 Bucket**: Frontend deployment validation
- **Load Balancer**: Target group health

### 🌐 API Endpoints  
All production endpoints tested:
- `/health` - Basic health check
- `/api/v1/regions` - Available regions
- `/api/v1/etex/flights` - Flight data
- `/api/v1/etex/choppers` - Helicopter data
- `/api/v1/status` - System status
- Plus 13+ additional endpoints

### 💻 Frontend
- **Domain Forwarding**: choppertracker.com → S3
- **Website Loading**: Asset delivery and performance
- **CORS Validation**: Cross-origin request handling

### ⚡ Performance
- **Response Times**: All endpoints under 2 seconds
- **Concurrent Load**: Multiple simultaneous requests
- **Data Freshness**: Recent data collection validation

## Scripts Overview

| Script | Duration | Purpose |
|--------|----------|---------|
| `test-quick.sh` | ~10 sec | Daily health monitoring |
| `test-production-complete.sh` | ~2-3 min | Full system validation |

## Sample Output

```
🚀 Flight Tracker Production Test Suite
========================================

🔧 Infrastructure Health Tests
✅ ECS Service: 2/2 tasks running (567ms)
✅ Redis Cache: Status: available (345ms)  
✅ S3 Bucket: 234 objects, 1.2 MiB (123ms)

🌐 API Endpoint Tests
✅ Health Check: HTTP 200, 89ms response (156ms)
✅ Flights Endpoint: 47 aircraft found (445ms)
✅ Helicopters Endpoint: 12 helicopters found (398ms)

💻 Frontend Tests  
✅ Domain Redirect: HTTP 301 to S3 (234ms)
✅ S3 Website: HTTP 200, 118KB loaded (567ms)

📊 Test Summary
✅ Passed: 15  ❌ Failed: 0  ⚠️ Warnings: 1
🎯 Overall Status: HEALTHY with warnings
```

## Requirements

- **AWS CLI**: Pre-configured with production credentials
- **curl**: HTTP testing (pre-installed on macOS)
- **jq**: JSON parsing (auto-installed if missing)

## Production Environment

**Infrastructure**:
- AWS Account: `958933162000`
- ECS Cluster: `flight-tracker-cluster`
- Region: `us-east-1`

**URLs**:
- **Main App**: http://choppertracker.com
- **API**: http://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com
- **S3 Direct**: http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com

## Results & Monitoring

Each comprehensive test generates:
- **Colored terminal output** with pass/fail/warning indicators
- **JSON results file** with detailed metrics and timing
- **Performance benchmarks** for response times and load capacity
- **Exit codes** for automation (0=pass, 1=fail, 2=warnings)

## Troubleshooting

**Common Issues**:
- `AWS Credentials: Not configured` → Run `aws configure`
- `jq: Not available` → Will auto-install via Homebrew
- `API Connection Failures` → Check ECS service health

## Documentation

📖 **Complete Guide**: [TESTING.md](./TESTING.md) - Comprehensive documentation  
📋 **Frontend Docs**: [CLAUDE.md](./CLAUDE.md) - Frontend testing integration  
🔧 **Backend Docs**: [../flightTrackerCollector/CLAUDE.md](../flightTrackerCollector/CLAUDE.md) - Backend testing

---

**Need help?** Check the [TESTING.md](./TESTING.md) guide for detailed documentation, troubleshooting, and automation setup.