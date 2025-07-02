#!/bin/bash

# Quick Production Health Check
# Usage: ./test-quick.sh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

API_URL="http://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com"
FRONTEND_URL="http://choppertracker.com"

echo "🚀 Quick Production Health Check"
echo "================================"

# API Health
echo -n "🔍 API Health... "
if curl -s "$API_URL/health" | grep -q "healthy"; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Flight Data
echo -n "✈️  Flight Data... "
FLIGHT_COUNT=$(curl -s "$API_URL/api/v1/etex/flights" | jq '. | length' 2>/dev/null || echo "0")
if [ "$FLIGHT_COUNT" -gt "0" ]; then
    echo -e "${GREEN}✅ $FLIGHT_COUNT aircraft${NC}"
else
    echo -e "${YELLOW}⚠️  No flights${NC}"
fi

# Frontend
echo -n "🌐 Frontend... "
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL")
if [[ "$FRONTEND_STATUS" =~ ^(200|301|302)$ ]]; then
    echo -e "${GREEN}✅ HTTP $FRONTEND_STATUS${NC}"
else
    echo -e "${RED}❌ HTTP $FRONTEND_STATUS${NC}"
fi

echo ""
echo "For comprehensive testing run: ./test-production-complete.sh"