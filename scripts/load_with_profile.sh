#!/bin/bash
# Load ALB logs with AWS profile (secure - credentials not exposed in commands)
# Usage: ./scripts/load_with_profile.sh <profile-name> <s3_path> [table_name]
#
# SECURITY: This script reads credentials from ~/.aws/credentials internally
# Only the profile name and S3 path are visible in command history and logs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Default database location in /tmp directory
DB_DIR="/tmp/alb-log-analyzer-${USER}"
mkdir -p "$DB_DIR"
DB_FILE="${DB_FILE:-${DB_DIR}/alb_analysis.duckdb}"
TABLE_NAME="${3:-alb_logs}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}Error: Profile name and S3 path are required${NC}"
    echo "Usage: $0 <profile-name> <s3_path> [table_name]"
    echo ""
    echo "Example:"
    echo "  $0 my-profile 's3://bucket/logs/**/*.log.gz'"
    echo "  $0 my-profile 's3://bucket/logs/**/*.log.gz' custom_table"
    exit 1
fi

PROFILE_NAME="$1"
S3_PATH="$2"

echo -e "${GREEN}Loading ALB logs with profile: $PROFILE_NAME${NC}"
echo -e "${GREEN}From: $S3_PATH${NC}"
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
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id --profile "$PROFILE_NAME")
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key --profile "$PROFILE_NAME")
AWS_DEFAULT_REGION=$(aws configure get region --profile "$PROFILE_NAME")

# Export for DuckDB subprocess
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

# Generate and run load SQL
sed -e "s|{{TABLE_NAME}}|$TABLE_NAME|g" \
    -e "s|{{S3_PATH}}|$S3_PATH|g" \
    "$SCRIPT_DIR/load_template.sql" | duckdb "$DB_FILE" 2>&1 | grep -v "AWS_ACCESS_KEY_ID" | grep -v "AWS_SECRET_ACCESS_KEY" || true

echo -e "${GREEN}✅ Logs loaded successfully${NC}"
echo ""
echo "Available commands:"
echo "  ./scripts/analyze.sh errors      # Analyze errors"
echo "  ./scripts/analyze.sh performance # Analyze performance"
echo "  ./scripts/analyze.sh diagnose    # Diagnostic info"
