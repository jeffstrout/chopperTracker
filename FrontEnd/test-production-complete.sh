#!/bin/bash

# Flight Tracker Production Testing Suite
# Comprehensive testing script for AWS production environment
# Usage: ./test-production-complete.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Production Configuration
API_URL="http://flight-tracker-alb-790028972.us-east-1.elb.amazonaws.com"
FRONTEND_URL="http://choppertracker.com"
S3_DIRECT_URL="http://flight-tracker-web-ui-1750266711.s3-website-us-east-1.amazonaws.com"
DEFAULT_REGION="etex"
ECS_CLUSTER="flight-tracker-cluster"
ECS_SERVICE="flight-tracker-backend"
S3_BUCKET="flight-tracker-web-ui-1750266711"
REDIS_CLUSTER_ID="flight-tracker-redis"

# Test Results
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0
TOTAL_TESTS=0
START_TIME=$(date +%s)
RESULTS_FILE="test-results-$(date +%Y-%m-%d-%H%M%S).json"

# Initialize results JSON
echo "{" > "$RESULTS_FILE"
echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"," >> "$RESULTS_FILE"
echo "  \"environment\": \"production\"," >> "$RESULTS_FILE"
echo "  \"tests\": {" >> "$RESULTS_FILE"

# Helper Functions
print_header() {
    echo -e "\n${CYAN}$1${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

print_test() {
    local status=$1
    local test_name=$2
    local details=$3
    local time_taken=$4
    
    ((TOTAL_TESTS++))
    
    case $status in
        "PASS")
            echo -e "✅ ${GREEN}$test_name${NC}: $details ${BLUE}(${time_taken}ms)${NC}"
            ((PASSED_TESTS++))
            ;;
        "FAIL")
            echo -e "❌ ${RED}$test_name${NC}: $details ${BLUE}(${time_taken}ms)${NC}"
            ((FAILED_TESTS++))
            ;;
        "WARN")
            echo -e "⚠️  ${YELLOW}$test_name${NC}: $details ${BLUE}(${time_taken}ms)${NC}"
            ((WARNING_TESTS++))
            ;;
    esac
    
    # Add to JSON results
    echo "    \"$(echo $test_name | tr ' ' '_' | tr '[:upper:]' '[:lower:]')\": {" >> "$RESULTS_FILE"
    echo "      \"status\": \"$status\"," >> "$RESULTS_FILE"
    echo "      \"details\": \"$details\"," >> "$RESULTS_FILE"
    echo "      \"time_ms\": $time_taken" >> "$RESULTS_FILE"
    echo "    }," >> "$RESULTS_FILE"
}

check_dependencies() {
    print_header "🔍 Checking Dependencies"
    
    # Check AWS CLI
    local start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    if command -v aws >/dev/null 2>&1; then
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "PASS" "AWS CLI" "Available" $((end_time - start_time))
    else
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "FAIL" "AWS CLI" "Not installed - install via 'brew install awscli'" $((end_time - start_time))
        return 1
    fi
    
    # Check curl
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    if command -v curl >/dev/null 2>&1; then
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "PASS" "curl" "Available" $((end_time - start_time))
    else
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "FAIL" "curl" "Not available" $((end_time - start_time))
        return 1
    fi
    
    # Check jq (install if missing)
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    if command -v jq >/dev/null 2>&1; then
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "PASS" "jq" "Available" $((end_time - start_time))
    else
        echo -e "${YELLOW}Installing jq...${NC}"
        if command -v brew >/dev/null 2>&1; then
            brew install jq >/dev/null 2>&1
            local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
            print_test "PASS" "jq" "Installed via Homebrew" $((end_time - start_time))
        else
            local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
            print_test "WARN" "jq" "Not available, some tests may be limited" $((end_time - start_time))
        fi
    fi
    
    # Check AWS credentials
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    if aws sts get-caller-identity >/dev/null 2>&1; then
        local identity=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "PASS" "AWS Credentials" "Account: $identity" $((end_time - start_time))
    else
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "FAIL" "AWS Credentials" "Not configured - run 'aws configure'" $((end_time - start_time))
        return 1
    fi
    
    return 0
}

test_infrastructure() {
    print_header "🔧 Infrastructure Health Tests"
    
    # Test ECS Service
    local start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local ecs_status=$(aws ecs describe-services \
        --cluster "$ECS_CLUSTER" \
        --services "$ECS_SERVICE" \
        --query 'services[0].{running:runningCount,desired:desiredCount,status:status}' \
        --output json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$ecs_status" != "null" ]; then
        local running=$(echo "$ecs_status" | jq -r '.running')
        local desired=$(echo "$ecs_status" | jq -r '.desired')
        local status=$(echo "$ecs_status" | jq -r '.status')
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        
        if [ "$running" = "$desired" ] && [ "$status" = "ACTIVE" ]; then
            print_test "PASS" "ECS Service" "$running/$desired tasks running" $((end_time - start_time))
        else
            print_test "WARN" "ECS Service" "$running/$desired tasks, status: $status" $((end_time - start_time))
        fi
    else
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "FAIL" "ECS Service" "Cannot access service status" $((end_time - start_time))
    fi
    
    # Test Redis Cache
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local redis_status=$(aws elasticache describe-cache-clusters \
        --cache-cluster-id "$REDIS_CLUSTER_ID" \
        --query 'CacheClusters[0].CacheClusterStatus' \
        --output text 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$redis_status" = "available" ]; then
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "PASS" "Redis Cache" "Status: $redis_status" $((end_time - start_time))
    else
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "WARN" "Redis Cache" "Status: ${redis_status:-unknown}" $((end_time - start_time))
    fi
    
    # Test S3 Bucket
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local s3_objects=$(aws s3 ls "s3://$S3_BUCKET/" --summarize 2>/dev/null | grep "Total Objects" | awk '{print $3}')
    local s3_size=$(aws s3 ls "s3://$S3_BUCKET/" --summarize --human-readable 2>/dev/null | grep "Total Size" | awk '{print $3 " " $4}')
    
    if [ $? -eq 0 ] && [ -n "$s3_objects" ]; then
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "PASS" "S3 Bucket" "$s3_objects objects, $s3_size" $((end_time - start_time))
    else
        local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
        print_test "FAIL" "S3 Bucket" "Cannot access bucket" $((end_time - start_time))
    fi
}

test_api_endpoints() {
    print_header "🌐 API Endpoint Tests"
    
    # Test Health Endpoint
    local start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local health_response=$(curl -s -w "%{http_code}:%{time_total}" "$API_URL/health" 2>/dev/null)
    local http_code=$(echo "$health_response" | cut -d':' -f1)
    local response_time=$(echo "$health_response" | cut -d':' -f2)
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [ "$http_code" = "200" ]; then
        local response_ms=$(echo "$response_time * 1000" | bc 2>/dev/null || echo "0")
        print_test "PASS" "Health Check" "HTTP $http_code, ${response_ms%.*}ms response" $((end_time - start_time))
    else
        print_test "FAIL" "Health Check" "HTTP ${http_code:-000}" $((end_time - start_time))
    fi
    
    # Test Regions Endpoint
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local regions_response=$(curl -s -w "%{http_code}" "$API_URL/api/v1/regions" 2>/dev/null)
    local regions_code="${regions_response: -3}"
    local regions_body="${regions_response%???}"
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [ "$regions_code" = "200" ]; then
        local region_count=$(echo "$regions_body" | jq '.regions | length' 2>/dev/null || echo "unknown")
        print_test "PASS" "Regions Endpoint" "$region_count regions available" $((end_time - start_time))
    else
        print_test "FAIL" "Regions Endpoint" "HTTP $regions_code" $((end_time - start_time))
    fi
    
    # Test Flights Endpoint
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local flights_response=$(curl -s -w "%{http_code}" "$API_URL/api/v1/$DEFAULT_REGION/flights" 2>/dev/null)
    local flights_code="${flights_response: -3}"
    local flights_body="${flights_response%???}"
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [ "$flights_code" = "200" ]; then
        local flight_count=$(echo "$flights_body" | jq '. | length' 2>/dev/null || echo "unknown")
        print_test "PASS" "Flights Endpoint" "$flight_count aircraft found" $((end_time - start_time))
    else
        print_test "FAIL" "Flights Endpoint" "HTTP $flights_code" $((end_time - start_time))
    fi
    
    # Test Helicopters Endpoint
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local choppers_response=$(curl -s -w "%{http_code}" "$API_URL/api/v1/$DEFAULT_REGION/choppers" 2>/dev/null)
    local choppers_code="${choppers_response: -3}"
    local choppers_body="${choppers_response%???}"
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [ "$choppers_code" = "200" ]; then
        local chopper_count=$(echo "$choppers_body" | jq '. | length' 2>/dev/null || echo "unknown")
        print_test "PASS" "Helicopters Endpoint" "$chopper_count helicopters found" $((end_time - start_time))
    else
        print_test "FAIL" "Helicopters Endpoint" "HTTP $choppers_code" $((end_time - start_time))
    fi
    
    # Test Status Endpoint
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local status_response=$(curl -s -w "%{http_code}:%{time_total}" "$API_URL/api/v1/status" 2>/dev/null)
    local status_code=$(echo "$status_response" | cut -d':' -f1)
    local status_time=$(echo "$status_response" | cut -d':' -f2)
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [ "$status_code" = "200" ]; then
        local status_ms=$(echo "$status_time * 1000" | bc 2>/dev/null || echo "0")
        if (( $(echo "$status_time > 2.0" | bc -l 2>/dev/null || echo 0) )); then
            print_test "WARN" "Status Endpoint" "HTTP $status_code, slow response ${status_ms%.*}ms" $((end_time - start_time))
        else
            print_test "PASS" "Status Endpoint" "HTTP $status_code, ${status_ms%.*}ms response" $((end_time - start_time))
        fi
    else
        print_test "FAIL" "Status Endpoint" "HTTP ${status_code:-000}" $((end_time - start_time))
    fi
    
    # Test CSV Export
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local csv_response=$(curl -s -w "%{http_code}" "$API_URL/api/v1/$DEFAULT_REGION/flights/tabular" 2>/dev/null)
    local csv_code="${csv_response: -3}"
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [ "$csv_code" = "200" ]; then
        print_test "PASS" "CSV Export" "Tabular data available" $((end_time - start_time))
    else
        print_test "FAIL" "CSV Export" "HTTP $csv_code" $((end_time - start_time))
    fi
}

test_frontend() {
    print_header "💻 Frontend Tests"
    
    # Test Domain Redirect
    local start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local redirect_response=$(curl -s -I -w "%{http_code}:%{redirect_url}" "$FRONTEND_URL" 2>/dev/null)
    local redirect_code=$(echo "$redirect_response" | tail -1 | cut -d':' -f1)
    local redirect_url=$(echo "$redirect_response" | tail -1 | cut -d':' -f2-)
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [[ "$redirect_code" =~ ^(200|301|302)$ ]]; then
        print_test "PASS" "Domain Redirect" "HTTP $redirect_code to S3" $((end_time - start_time))
    else
        print_test "FAIL" "Domain Redirect" "HTTP ${redirect_code:-000}" $((end_time - start_time))
    fi
    
    # Test S3 Direct Access
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local s3_response=$(curl -s -w "%{http_code}:%{size_download}" "$S3_DIRECT_URL" 2>/dev/null)
    local s3_code=$(echo "$s3_response" | tail -1 | cut -d':' -f1)
    local s3_size=$(echo "$s3_response" | tail -1 | cut -d':' -f2)
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [ "$s3_code" = "200" ]; then
        local size_kb=$((s3_size / 1024))
        print_test "PASS" "S3 Website" "HTTP $s3_code, ${size_kb}KB loaded" $((end_time - start_time))
    else
        print_test "FAIL" "S3 Website" "HTTP ${s3_code:-000}" $((end_time - start_time))
    fi
    
    # Test CORS Preflight
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local cors_response=$(curl -s -I -X OPTIONS \
        -H "Origin: $S3_DIRECT_URL" \
        -H "Access-Control-Request-Method: GET" \
        -w "%{http_code}" "$API_URL/api/v1/$DEFAULT_REGION/flights" 2>/dev/null)
    local cors_code="${cors_response: -3}"
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [[ "$cors_code" =~ ^(200|204)$ ]]; then
        print_test "PASS" "CORS Preflight" "HTTP $cors_code, cross-origin enabled" $((end_time - start_time))
    else
        print_test "WARN" "CORS Preflight" "HTTP ${cors_code:-000}, may affect frontend" $((end_time - start_time))
    fi
}

test_performance() {
    print_header "⚡ Performance Tests"
    
    # Concurrent API Requests Test
    local start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    echo -e "${BLUE}Running concurrent requests test...${NC}"
    
    local temp_dir=$(mktemp -d)
    local concurrent_requests=5
    
    for i in $(seq 1 $concurrent_requests); do
        (curl -s -w "%{time_total}" "$API_URL/api/v1/$DEFAULT_REGION/flights" > "$temp_dir/response_$i.txt" 2>&1) &
    done
    wait
    
    local total_time=0
    local successful_requests=0
    for i in $(seq 1 $concurrent_requests); do
        if [ -f "$temp_dir/response_$i.txt" ]; then
            local response_time=$(tail -1 "$temp_dir/response_$i.txt" 2>/dev/null)
            if [[ "$response_time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                total_time=$(echo "$total_time + $response_time" | bc 2>/dev/null || echo "$total_time")
                ((successful_requests++))
            fi
        fi
    done
    
    rm -rf "$temp_dir"
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [ $successful_requests -eq $concurrent_requests ]; then
        local avg_time=$(echo "scale=3; $total_time / $concurrent_requests" | bc 2>/dev/null || echo "0")
        print_test "PASS" "Concurrent Requests" "$successful_requests/$concurrent_requests successful, avg ${avg_time}s" $((end_time - start_time))
    else
        print_test "WARN" "Concurrent Requests" "$successful_requests/$concurrent_requests successful" $((end_time - start_time))
    fi
    
    # Data Freshness Test
    start_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    local status_data=$(curl -s "$API_URL/api/v1/status" 2>/dev/null)
    local last_collection=$(echo "$status_data" | jq -r '.last_collection // empty' 2>/dev/null)
    local end_time=$(gdate +%s%3N 2>/dev/null || date +%s000)
    
    if [ -n "$last_collection" ] && [ "$last_collection" != "null" ]; then
        local collection_time=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${last_collection%.*}" +%s 2>/dev/null || echo "0")
        local current_time=$(date +%s)
        local age_minutes=$(( (current_time - collection_time) / 60 ))
        
        if [ $age_minutes -le 5 ]; then
            print_test "PASS" "Data Freshness" "Last collection ${age_minutes}m ago" $((end_time - start_time))
        else
            print_test "WARN" "Data Freshness" "Last collection ${age_minutes}m ago (stale)" $((end_time - start_time))
        fi
    else
        print_test "WARN" "Data Freshness" "Cannot determine collection time" $((end_time - start_time))
    fi
}

generate_summary() {
    print_header "📊 Test Summary"
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    
    echo -e "${CYAN}Test Results:${NC}"
    echo -e "  ✅ Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "  ❌ Failed: ${RED}$FAILED_TESTS${NC}"
    echo -e "  ⚠️  Warnings: ${YELLOW}$WARNING_TESTS${NC}"
    echo -e "  📊 Total: $TOTAL_TESTS tests"
    echo -e "  ⏱️  Duration: ${total_duration}s"
    
    # Overall Status
    echo ""
    if [ $FAILED_TESTS -eq 0 ]; then
        if [ $WARNING_TESTS -eq 0 ]; then
            echo -e "🎯 ${GREEN}Overall Status: HEALTHY${NC}"
        else
            echo -e "🎯 ${YELLOW}Overall Status: HEALTHY with warnings${NC}"
        fi
    else
        echo -e "🎯 ${RED}Overall Status: ISSUES DETECTED${NC}"
    fi
    
    # Complete JSON results
    echo "  }," >> "$RESULTS_FILE"
    echo "  \"summary\": {" >> "$RESULTS_FILE"
    echo "    \"passed\": $PASSED_TESTS," >> "$RESULTS_FILE"
    echo "    \"failed\": $FAILED_TESTS," >> "$RESULTS_FILE"
    echo "    \"warnings\": $WARNING_TESTS," >> "$RESULTS_FILE"
    echo "    \"total\": $TOTAL_TESTS," >> "$RESULTS_FILE"
    echo "    \"duration_seconds\": $total_duration" >> "$RESULTS_FILE"
    echo "  }" >> "$RESULTS_FILE"
    echo "}" >> "$RESULTS_FILE"
    
    echo ""
    echo -e "📋 Detailed results saved to: ${BLUE}$RESULTS_FILE${NC}"
    
    # Production URLs
    echo ""
    echo -e "${PURPLE}Production URLs:${NC}"
    echo -e "  🌐 Main App: $FRONTEND_URL"
    echo -e "  📱 S3 Direct: $S3_DIRECT_URL"
    echo -e "  🔗 API: $API_URL"
}

# Main Execution
main() {
    echo -e "${CYAN}"
    echo "🚀 Flight Tracker Production Test Suite"
    echo "========================================"
    echo -e "${NC}"
    echo "Testing production environment at: $API_URL"
    echo "Timestamp: $(date)"
    echo ""
    
    # Run all test suites
    if ! check_dependencies; then
        echo -e "\n${RED}❌ Dependency check failed. Please resolve issues before continuing.${NC}"
        exit 1
    fi
    
    test_infrastructure
    test_api_endpoints
    test_frontend
    test_performance
    
    # Generate final summary
    generate_summary
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -gt 0 ]; then
        exit 1
    elif [ $WARNING_TESTS -gt 0 ]; then
        exit 2
    else
        exit 0
    fi
}

# Run main function
main "$@"