#!/bin/bash
# =============================================================================
# TEST SUITE - Comprehensive tests for dev and prod environments
# =============================================================================

set -e

BASE_URL="https://localhost:8443"
PASSED=0
FAILED=0
TOTAL=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
run_test() {
    local name="$1"
    local url="$2"
    local expected_code="$3"
    local check_json="${4:-false}"
    
    TOTAL=$((TOTAL + 1))
    
    # Make request
    response=$(curl -sk -w "\n%{http_code}" "$url" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    # Check status code
    if [ "$http_code" = "$expected_code" ]; then
        # If JSON check required, verify it's valid JSON
        if [ "$check_json" = "true" ]; then
            if echo "$body" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $name (HTTP $http_code)"
                PASSED=$((PASSED + 1))
                return 0
            else
                echo -e "  ${RED}✗${NC} $name - Invalid JSON response"
                FAILED=$((FAILED + 1))
                return 1
            fi
        else
            echo -e "  ${GREEN}✓${NC} $name (HTTP $http_code)"
            PASSED=$((PASSED + 1))
            return 0
        fi
    else
        echo -e "  ${RED}✗${NC} $name - Expected $expected_code, got $http_code"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Test POST and return ID
test_create_user() {
    local env="$1"
    local api_path="$2"
    
    TOTAL=$((TOTAL + 1))
    
    response=$(curl -sk -X POST "$BASE_URL$api_path/users" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test User","message":"Automated test message"}' \
        -w "\n%{http_code}" 2>/dev/null)
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ]; then
        user_id=$(echo "$body" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
        if [ -n "$user_id" ]; then
            echo -e "  ${GREEN}✓${NC} Create user in $env (ID: $user_id)" >&2
            PASSED=$((PASSED + 1))
            echo "$user_id"
            return 0
        fi
    fi
    
    echo -e "  ${RED}✗${NC} Create user in $env - Failed (HTTP $http_code)" >&2
    FAILED=$((FAILED + 1))
    echo ""
    return 1
}

# Test DELETE
test_delete_user() {
    local env="$1"
    local api_path="$2"
    local user_id="$3"
    
    TOTAL=$((TOTAL + 1))
    
    response=$(curl -sk -X DELETE "$BASE_URL$api_path/users/$user_id" -w "\n%{http_code}" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "  ${GREEN}✓${NC} Delete user in $env (ID: $user_id)"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} Delete user in $env - Failed (HTTP $http_code)"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Print header
echo ""
echo "=============================================="
echo "       KUBERNETES APP TEST SUITE"
echo "=============================================="
echo ""

# Check if server is running
if ! curl -sk "$BASE_URL" >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Server not running at $BASE_URL${NC}"
    echo "Run 'make run' or 'make start' first"
    exit 1
fi

# =============================================================================
# PROD ENVIRONMENT TESTS
# =============================================================================
echo -e "${YELLOW}[PROD] Testing production environment (/)${NC}"
echo ""

echo "  API Endpoints:"
run_test "GET /api/health" "$BASE_URL/api/health" "200" "true"
run_test "GET /api/users" "$BASE_URL/api/users" "200" "true"
run_test "GET /api/info" "$BASE_URL/api/info" "200" "true"

echo ""
echo "  Frontend:"
run_test "GET / (frontend)" "$BASE_URL/" "200"

echo ""
echo "  CRUD Operations:"
prod_user_id=$(test_create_user "prod" "/api")
if [ -n "$prod_user_id" ] && [ "$prod_user_id" != "0" ]; then
    run_test "GET created user" "$BASE_URL/api/users" "200" "true"
    test_delete_user "prod" "/api" "$prod_user_id"
fi

echo ""

# =============================================================================
# DEV ENVIRONMENT TESTS
# =============================================================================
echo -e "${YELLOW}[DEV] Testing development environment (/dev/)${NC}"
echo ""

echo "  API Endpoints:"
run_test "GET /dev/api/health" "$BASE_URL/dev/api/health" "200" "true"
run_test "GET /dev/api/users" "$BASE_URL/dev/api/users" "200" "true"
run_test "GET /dev/api/info" "$BASE_URL/dev/api/info" "200" "true"

echo ""
echo "  Frontend:"
run_test "GET /dev/ (frontend)" "$BASE_URL/dev/" "200"

echo ""
echo "  CRUD Operations:"
dev_user_id=$(test_create_user "dev" "/dev/api")
if [ -n "$dev_user_id" ] && [ "$dev_user_id" != "0" ]; then
    run_test "GET created user" "$BASE_URL/dev/api/users" "200" "true"
    test_delete_user "dev" "/dev/api" "$dev_user_id"
fi

echo ""

# =============================================================================
# CLUSTER INFO TESTS
# =============================================================================
echo -e "${YELLOW}[INFO] Cluster information${NC}"
echo ""

# Get prod info
prod_info=$(curl -sk "$BASE_URL/api/info" 2>/dev/null)
prod_node=$(echo "$prod_info" | python3 -c "import sys,json; print(json.load(sys.stdin).get('node_name','unknown'))" 2>/dev/null)
prod_pod=$(echo "$prod_info" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hostname','unknown'))" 2>/dev/null)
echo "  Prod - Node: $prod_node, Pod: $prod_pod"

# Get dev info
dev_info=$(curl -sk "$BASE_URL/dev/api/info" 2>/dev/null)
dev_node=$(echo "$dev_info" | python3 -c "import sys,json; print(json.load(sys.stdin).get('node_name','unknown'))" 2>/dev/null)
dev_pod=$(echo "$dev_info" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hostname','unknown'))" 2>/dev/null)
echo "  Dev  - Node: $dev_node, Pod: $dev_pod"

echo ""

# =============================================================================
# SUMMARY
# =============================================================================
echo "=============================================="
echo "                  RESULTS"
echo "=============================================="
echo ""
echo -e "  Total:  $TOTAL"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed! ✗${NC}"
    exit 1
fi
