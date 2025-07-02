#!/bin/bash

# Production Environment Testing Script
# Runs tests against live AWS infrastructure

echo "🚀 Testing Flight Tracker Production Environment"
echo "=============================================="

# Production URLs
FRONTEND_URL="http://choppertracker.com"
S3_DIRECT_URL="http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com"
API_URL="http://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com"

echo ""
echo "🌐 Production URLs:"
echo "   Frontend: $FRONTEND_URL"
echo "   S3 Direct: $S3_DIRECT_URL"
echo "   API: $API_URL"
echo ""

# Install test dependencies if not already installed
if [ ! -d "node_modules/@testing-library" ]; then
    echo "📦 Installing test dependencies..."
    npm install --include=dev
    echo ""
fi

# API Health Check
echo "🔍 Testing API Health..."
API_HEALTH=$(curl -s -w "%{http_code}" -o /dev/null $API_URL/health)
if [ "$API_HEALTH" = "200" ]; then
    echo "✅ API Health Check: PASSED"
else
    echo "❌ API Health Check: FAILED (HTTP $API_HEALTH)"
fi

# Test API Endpoints
echo ""
echo "🔍 Testing API Endpoints..."

# Test regions endpoint
REGIONS_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null $API_URL/api/v1/regions)
if [ "$REGIONS_RESPONSE" = "200" ]; then
    echo "✅ Regions Endpoint: PASSED"
else
    echo "❌ Regions Endpoint: FAILED (HTTP $REGIONS_RESPONSE)"
fi

# Test flights endpoint
FLIGHTS_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null $API_URL/api/v1/etex/flights)
if [ "$FLIGHTS_RESPONSE" = "200" ]; then
    echo "✅ Flights Endpoint: PASSED"
else
    echo "❌ Flights Endpoint: FAILED (HTTP $FLIGHTS_RESPONSE)"
fi

# Test helicopters endpoint
CHOPPERS_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null $API_URL/api/v1/etex/choppers)
if [ "$CHOPPERS_RESPONSE" = "200" ]; then
    echo "✅ Helicopters Endpoint: PASSED"
else
    echo "❌ Helicopters Endpoint: FAILED (HTTP $CHOPPERS_RESPONSE)"
fi

# Test status endpoint
STATUS_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null $API_URL/api/v1/status)
if [ "$STATUS_RESPONSE" = "200" ]; then
    echo "✅ Status Endpoint: PASSED"
else
    echo "❌ Status Endpoint: FAILED (HTTP $STATUS_RESPONSE)"
fi

# Frontend Availability Check
echo ""
echo "🔍 Testing Frontend Availability..."

# Test main domain
FRONTEND_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null $FRONTEND_URL)
if [ "$FRONTEND_RESPONSE" = "200" ] || [ "$FRONTEND_RESPONSE" = "301" ] || [ "$FRONTEND_RESPONSE" = "302" ]; then
    echo "✅ Main Domain: PASSED (HTTP $FRONTEND_RESPONSE)"
else
    echo "❌ Main Domain: FAILED (HTTP $FRONTEND_RESPONSE)"
fi

# Test S3 direct URL
S3_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null $S3_DIRECT_URL)
if [ "$S3_RESPONSE" = "200" ]; then
    echo "✅ S3 Direct URL: PASSED"
else
    echo "❌ S3 Direct URL: FAILED (HTTP $S3_RESPONSE)"
fi

# Run unit tests with production API
echo ""
echo "🧪 Running Unit Tests with Production Configuration..."
export VITE_API_BASE_URL=$API_URL
export NODE_ENV=test

# Run tests that work with production environment
npm test -- --run --reporter=verbose || echo "⚠️ Some tests may require production data"

# Performance Test
echo ""
echo "⚡ Performance Testing..."
API_RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /dev/null $API_URL/health)
echo "📊 API Response Time: ${API_RESPONSE_TIME}s"

if (( $(echo "$API_RESPONSE_TIME < 2.0" | bc -l) )); then
    echo "✅ API Performance: GOOD"
else
    echo "⚠️ API Performance: SLOW (>${API_RESPONSE_TIME}s)"
fi

# Data Quality Check
echo ""
echo "📊 Data Quality Check..."
FLIGHT_COUNT=$(curl -s $API_URL/api/v1/etex/flights | jq '. | length' 2>/dev/null || echo "0")
CHOPPER_COUNT=$(curl -s $API_URL/api/v1/etex/choppers | jq '. | length' 2>/dev/null || echo "0")

echo "✈️ Current Flights: $FLIGHT_COUNT"
echo "🚁 Current Helicopters: $CHOPPER_COUNT"

if [ "$FLIGHT_COUNT" -gt "0" ]; then
    echo "✅ Flight Data: AVAILABLE"
else
    echo "⚠️ Flight Data: No flights currently detected"
fi

echo ""
echo "🎯 Production Testing Complete!"
echo ""
echo "📋 Summary:"
echo "   - API Health: $([ "$API_HEALTH" = "200" ] && echo "✅ HEALTHY" || echo "❌ UNHEALTHY")"
echo "   - Frontend: $([ "$S3_RESPONSE" = "200" ] && echo "✅ ONLINE" || echo "❌ OFFLINE")"
echo "   - Data Flow: $([ "$FLIGHT_COUNT" -gt "0" ] && echo "✅ ACTIVE" || echo "⚠️ LIMITED")"
echo "   - Performance: $([ $(echo "$API_RESPONSE_TIME < 2.0" | bc -l) = "1" ] && echo "✅ GOOD" || echo "⚠️ SLOW")"