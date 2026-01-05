#!/bin/bash
# Setup DuckDB with AWS profile (secure - credentials not exposed in commands)
# Usage: ./scripts/setup_with_profile.sh <profile-name>
#
# SECURITY: This script reads credentials from ~/.aws/credentials internally
# Only the profile name is visible in command history and logs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Default database location in /tmp directory
DB_DIR="/tmp/alb-log-analyzer-${USER}"
mkdir -p "$DB_DIR"
DB_FILE="${DB_FILE:-${DB_DIR}/alb_analysis.duckdb}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Error: Profile name is required${NC}"
    echo "Usage: $0 <profile-name>"
    echo ""
    echo "Available profiles:"
    aws configure list-profiles 2>/dev/null || echo "  (aws CLI not configured)"
    exit 1
fi

PROFILE_NAME="$1"

echo -e "${GREEN}Setting up DuckDB with AWS profile: $PROFILE_NAME${NC}"
echo "(Credentials are read securely from ~/.aws/credentials)"

# Remove old database file for clean start
if [ -f "$DB_FILE" ]; then
    echo "Removing old database file..."
    rm -f "$DB_FILE"
fi

# Check if profile exists
if ! aws configure get aws_access_key_id --profile "$PROFILE_NAME" >/dev/null 2>&1; then
    echo -e "${RED}Error: Profile '$PROFILE_NAME' not found${NC}"
    echo ""
    echo "Available profiles:"
    aws configure list-profiles
    exit 1
fi

# Read credentials from AWS config (secure - not exposed in output)
# These variables stay in the script's environment only
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile "$PROFILE_NAME")
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile "$PROFILE_NAME")
AWS_DEFAULT_REGION=$(aws configure get region --profile "$PROFILE_NAME")

# Export for DuckDB subprocess
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

# Run setup SQL (credentials passed via environment, not command line)
duckdb "$DB_FILE" < "$SCRIPT_DIR/setup_s3_env.sql" 2>&1 | grep -v "AWS_ACCESS_KEY_ID" | grep -v "AWS_SECRET_ACCESS_KEY" || true

echo -e "${GREEN}✅ Setup completed for profile: $PROFILE_NAME${NC}"
echo -e "${GREEN}   Region: $AWS_DEFAULT_REGION${NC}"
echo ""
echo "Environment ready. To load logs, run:"
echo -e "${GREEN}  ./scripts/load_with_profile.sh $PROFILE_NAME 's3://bucket/path/**/*.log.gz'${NC}"
