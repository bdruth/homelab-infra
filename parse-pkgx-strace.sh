#!/bin/bash

LOG_FILE="$1"

if [ -z "$LOG_FILE" ]; then
  echo "Usage: $0 <strace_log_file>"
  echo "Example: $0 pkgx_strace.log"
  exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
  echo "Error: Log file '$LOG_FILE' not found."
  exit 1
fi

echo "=== PKGX Strace Analysis Report ==="
echo "Log file: $LOG_FILE"
echo "Generated: $(date)"
echo "======================================="
echo ""

# Helper functions for colored output
print_header() {
    echo -e "\n\033[1;34m--- $1 ---\033[0m"
}

print_success() {
    echo -e "\033[1;32m✓ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m✗ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠ $1\033[0m"
}

print_info() {
    echo -e "\033[1;36m→ $1\033[0m"
}

# Extract key information first
MAIN_PID=$(grep -m1 "execve.*pkgx" "$LOG_FILE" | awk '{print $1}')
echo "Main PKGX process PID: $MAIN_PID"

print_header "1. Environment Analysis"

# Check proxy settings
print_info "Proxy Environment Variables:"
if grep -q 'getenv("HTTP_PROXY")' "$LOG_FILE"; then
    grep 'getenv("HTTP_PROXY")' "$LOG_FILE" | while read -r line; do
        if echo "$line" | grep -q "= NULL"; then
            echo "  HTTP_PROXY: Not set"
        else
            # Extract value between quotes after "= "
            temp_line="${line#*= \"}"
            value="${temp_line%\"*}"
            echo "  HTTP_PROXY: $value"
        fi
    done
else
    echo "  HTTP_PROXY: No checks found"
fi

if grep -q 'getenv("HTTPS_PROXY")' "$LOG_FILE"; then
    grep 'getenv("HTTPS_PROXY")' "$LOG_FILE" | while read -r line; do
        if echo "$line" | grep -q "= NULL"; then
            echo "  HTTPS_PROXY: Not set"
        else
            # Extract value between quotes after "= "
            temp_line="${line#*= \"}"
            value="${temp_line%\"*}"
            echo "  HTTPS_PROXY: $value"
        fi
    done
else
    echo "  HTTPS_PROXY: No checks found"
fi

print_header "2. DNS Resolution Analysis"

# DNS servers being queried
print_info "DNS Servers Contacted:"
grep "connect.*sin_port=htons(53)" "$LOG_FILE" | \
  sed 's/.*inet_addr("\([^"]*\)").*/\1/' | \
  sort -u | \
  while read -r dns_ip; do
    echo "  → $dns_ip"
  done

# DNS queries for dist.pkgx.dev
print_info "DNS Resolution Attempts:"
dns_queries=$(grep -c "dist\.pkgx\.dev" "$LOG_FILE" 2>/dev/null || echo "0")
echo "  Total queries for dist.pkgx.dev: $dns_queries"

# Check for successful DNS responses
if grep -q "dist\.pkgx\.dev" "$LOG_FILE"; then
    print_success "DNS queries for dist.pkgx.dev found"
else
    print_warning "No DNS queries for dist.pkgx.dev found"
fi

print_header "3. Network Connection Analysis"

# Find all HTTPS connection attempts
print_info "HTTPS Connection Attempts (port 443):"
grep "connect.*sin_port=htons(443)" "$LOG_FILE" | \
  sed 's/.*inet_addr("\([^"]*\)").*/\1/' | \
  sort | uniq -c | \
  while read -r count ip; do
    echo "  → $ip (attempted $count times)"
  done

# Check for connection results
print_info "Connection Results:"
connection_success=0
connection_failed=0
connection_timeout=0

while read -r line; do
    if echo "$line" | grep -q "sin_port=htons(443)"; then
        pid=$(echo "$line" | awk '{print $1}')
        fd=$(echo "$line" | grep -o "connect([0-9]*" | cut -d'(' -f2)
        # Extract IP address from inet_addr("x.x.x.x") pattern
        temp_line="${line#*inet_addr(\"}"
        ip="${temp_line%%\"*}"
        
        # Look for the result of this connection attempt
        result_line=$(grep -A 1 -E "^$pid.*connect\($fd," "$LOG_FILE" | tail -1)
        
        if echo "$result_line" | grep -q "= 0"; then
            print_success "Connection to $ip succeeded"
            ((connection_success++))
        elif echo "$result_line" | grep -q "ECONNREFUSED"; then
            print_error "Connection to $ip refused (ECONNREFUSED)"
            ((connection_failed++))
        elif echo "$result_line" | grep -q "ETIMEDOUT"; then
            print_error "Connection to $ip timed out (ETIMEDOUT)"
            ((connection_timeout++))
        elif echo "$result_line" | grep -q "EHOSTUNREACH"; then
            print_error "Host $ip unreachable (EHOSTUNREACH)"
            ((connection_failed++))
        elif echo "$result_line" | grep -q "ENETUNREACH"; then
            print_error "Network unreachable to $ip (ENETUNREACH)"
            ((connection_failed++))
        elif echo "$result_line" | grep -q "= -1"; then
            error_type=$(echo "$result_line" | grep -o '[A-Z][A-Z_]*' | head -1)
            print_error "Connection to $ip failed ($error_type)"
            ((connection_failed++))
        fi
    fi
done < <(grep "connect.*sin_port=htons(443)" "$LOG_FILE")

print_header "4. Error Summary"

echo "Connection Statistics:"
echo "  ✓ Successful connections: $connection_success"
echo "  ✗ Failed connections: $connection_failed"
echo "  ⏱ Timed out connections: $connection_timeout"

# Look for specific error patterns
print_info "Detailed Error Analysis:"

# Connection refused errors
refused_count=$(grep -c "ECONNREFUSED" "$LOG_FILE" 2>/dev/null | head -1)
refused_count=${refused_count:-0}
if [ "$refused_count" -gt 0 ]; then
    print_error "Found $refused_count connection refused errors"
    echo "  This typically indicates:"
    echo "    - The target server is not listening on port 443"
    echo "    - A firewall is blocking the connection"
    echo "    - The service is down"
fi

# Timeout errors
timeout_count=$(grep -c "ETIMEDOUT" "$LOG_FILE" 2>/dev/null | head -1)
timeout_count=${timeout_count:-0}
if [ "$timeout_count" -gt 0 ]; then
    print_error "Found $timeout_count timeout errors"
    echo "  This typically indicates:"
    echo "    - Network latency issues"
    echo "    - Packet loss"
    echo "    - Firewall dropping packets silently"
fi

# Host unreachable errors
unreachable_count=$(grep -c "EHOSTUNREACH" "$LOG_FILE" 2>/dev/null | head -1)
unreachable_count=${unreachable_count:-0}
if [ "$unreachable_count" -gt 0 ]; then
    print_error "Found $unreachable_count host unreachable errors"
    echo "  This typically indicates:"
    echo "    - Routing issues"
    echo "    - DNS resolution returning invalid IPs"
    echo "    - Network configuration problems"
fi

print_header "5. TLS/SSL Analysis"

# Look for SSL/TLS related calls
if grep -q "SSL\|TLS" "$LOG_FILE"; then
    print_info "TLS/SSL activity detected"
    ssl_errors=$(grep -c "SSL.*error\|TLS.*error" "$LOG_FILE" 2>/dev/null | head -1)
    ssl_errors=${ssl_errors:-0}
    if [ "$ssl_errors" -gt 0 ]; then
        print_error "Found $ssl_errors SSL/TLS errors"
    fi
else
    print_warning "No explicit SSL/TLS activity found (may be in library calls)"
fi

print_header "6. File and Resource Access"

# Check for certificate file access
print_info "Certificate file access:"
grep -E "(openat|open).*\.(crt|pem|cert|ca-bundle)" "$LOG_FILE" | \
  while read -r line; do
    file_path=$(echo "$line" | grep -o '"/[^"]*\.\(crt\|pem\|cert\|ca-bundle\)[^"]*"' | tr -d '"')
    if echo "$line" | grep -q "= -1 ENOENT"; then
        print_error "Certificate file not found: $file_path"
    else
        print_success "Certificate file accessed: $file_path"
    fi
  done

print_header "7. Recommendations"

echo "Based on the analysis:"
echo ""

if [ "$connection_failed" -gt "$connection_success" ]; then
    echo "🔍 MAIN ISSUE: More connections failed than succeeded"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check network connectivity:"
    echo "   curl -v https://dist.pkgx.dev"
    echo "   ping dist.pkgx.dev"
    echo ""
    echo "2. Check DNS resolution:"
    echo "   nslookup dist.pkgx.dev"
    echo "   dig dist.pkgx.dev"
    echo ""
    echo "3. Check if proxy is required:"
    echo "   Try setting HTTP_PROXY and HTTPS_PROXY if behind corporate firewall"
    echo ""
    echo "4. Check firewall rules:"
    echo "   Ensure outbound HTTPS (port 443) is allowed"
fi

if [ "$refused_count" -gt 0 ]; then
    echo "🚫 CONNECTION REFUSED: The remote server is actively refusing connections"
    echo "   - This could indicate the service is down"
    echo "   - Check pkgx service status or try alternative mirrors"
fi

if [ "$timeout_count" -gt 0 ]; then
    echo "⏱ TIMEOUTS DETECTED: Network connectivity issues"
    echo "   - Check for packet loss: ping -c 10 dist.pkgx.dev"
    echo "   - Try with different DNS servers"
fi

echo ""
echo "=== End of Analysis ==="
