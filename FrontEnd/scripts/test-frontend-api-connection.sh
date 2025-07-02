#!/bin/bash

echo "Testing frontend-to-API connectivity..."
echo ""

# Test API directly
echo "1. Testing API directly:"
API_RESPONSE=$(curl -s http://api.choppertracker.com/health)
echo "API Health: $API_RESPONSE"

# Test API with CORS headers
echo ""
echo "2. Testing API with CORS headers from frontend domains:"

for domain in "https://www.choppertracker.com" "https://choppertracker.com"; do
    echo "Testing from $domain:"
    CORS_RESPONSE=$(curl -s -H "Origin: $domain" http://api.choppertracker.com/health)
    echo "  Response: $CORS_RESPONSE"
done

# Test if frontend is accessible
echo ""
echo "3. Testing frontend accessibility:"
FRONTEND_STATUS=$(curl -I -s https://www.choppertracker.com | head -1)
echo "Frontend Status: $FRONTEND_STATUS"

# Test if API returns flight data
echo ""
echo "4. Testing flight data:"
FLIGHT_COUNT=$(curl -s http://api.choppertracker.com/api/v1/etex/flights | jq length 2>/dev/null || echo "0")
echo "Current aircraft count: $FLIGHT_COUNT"

echo ""
echo "All tests completed!"
echo ""
echo "If frontend shows 'offline':"
echo "1. Wait 5-10 minutes for new deployment to complete"
echo "2. Clear browser cache (Ctrl+F5 or Cmd+Shift+R)"
echo "3. Check browser console for any error messages"