#!/bin/bash
# Secure setup for DuckDB with AWS profile
# Only profile name is exposed, credentials are read from ~/.aws/credentials

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Default database location in /tmp directory
DB_DIR="/tmp/alb-log-analyzer-${USER}"
mkdir -p "$DB_DIR"
DB_FILE="${DB_FILE:-${DB_DIR}/alb_analysis.duckdb}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
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
echo "(Credentials will be read securely from ~/.aws/credentials)"

# Check if profile exists
if ! aws configure get aws_access_key_id --profile "$PROFILE_NAME" >/dev/null 2>&1; then
    echo -e "${RED}Error: Profile '$PROFILE_NAME' not found${NC}"
    echo ""
    echo "Available profiles:"
    aws configure list-profiles
    exit 1
fi

# Set only AWS_PROFILE environment variable
# DuckDB will read credentials from ~/.aws/credentials
export AWS_PROFILE="$PROFILE_NAME"

# Try using credential_chain with profile
set +e
duckdb "$DB_FILE" <<EOF
INSTALL aws;
LOAD aws;
INSTALL httpfs;
LOAD httpfs;

-- Try credential_chain first (reads from ~/.aws/credentials if using default profile)
CREATE OR REPLACE SECRET (
    TYPE S3,
    PROVIDER CREDENTIAL_CHAIN
);

SELECT 'Setup completed with credential_chain' as status;
EOF

RESULT=$?
set -e

if [ $RESULT -ne 0 ]; then
    echo ""
    echo -e "${RED}credential_chain failed for profile '$PROFILE_NAME'${NC}"
    echo "Named profiles require explicit credentials."
    echo "Please use the following command instead:"
    echo ""
    echo -e "${GREEN}  source scripts/load_profile.sh $PROFILE_NAME${NC}"
    echo -e "${GREEN}  ./scripts/analyze.sh setup-env${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Setup completed for profile: $PROFILE_NAME${NC}"
