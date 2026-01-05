#!/bin/bash
# Main script for analyzing ALB logs with DuckDB

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Default database location in /tmp directory
DB_DIR="/tmp/alb-log-analyzer-${USER}"
mkdir -p "$DB_DIR"
DB_FILE="${DB_FILE:-${DB_DIR}/alb_analysis.duckdb}"
TABLE_NAME="${TABLE_NAME:-alb_logs}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Usage: $0 <command> [options]

Commands:
    setup                   Setup DuckDB with required extensions (uses CREDENTIAL_CHAIN)
    setup-env               Setup DuckDB with AWS environment variables
    diagnose                Diagnose S3 access and AWS credentials
    load <s3_path>          Load ALB logs from S3
    errors                  Analyze error responses
    performance             Analyze response time performance
    query <sql_file>        Execute custom SQL query

Options:
    --db <file>            Database file path (default: alb_analysis.duckdb)
    --table <name>         Table name (default: alb_logs)

Examples:
    # Setup (try this first)
    $0 setup

    # If setup fails, diagnose the issue
    $0 diagnose

    # Setup with environment variables (if CREDENTIAL_CHAIN doesn't work)
    export AWS_ACCESS_KEY_ID=your_key_id
    export AWS_SECRET_ACCESS_KEY=your_secret_key
    export AWS_DEFAULT_REGION=ap-northeast-1
    $0 setup-env

    # Load and analyze
    $0 load 's3://my-bucket/logs/2024/11/**/*.log.gz'
    $0 errors
    $0 performance
    $0 query custom_query.sql

Environment variables:
    DB_FILE                     Database file path
    TABLE_NAME                  Table name
    AWS_ACCESS_KEY_ID           AWS access key (for setup-env)
    AWS_SECRET_ACCESS_KEY       AWS secret key (for setup-env)
    AWS_DEFAULT_REGION          AWS region (for setup-env)
EOF
    exit 1
}

run_sql() {
    local sql_file="$1"
    duckdb "$DB_FILE" < "$sql_file"
}

run_sql_with_replacement() {
    local sql_file="$1"
    local s3_path="$2"

    # Replace placeholders and execute
    sed -e "s|{{TABLE_NAME}}|$TABLE_NAME|g" \
        -e "s|{{S3_PATH}}|$s3_path|g" \
        "$sql_file" | duckdb "$DB_FILE"
}

cmd_setup() {
    echo -e "${GREEN}Setting up DuckDB with CREDENTIAL_CHAIN...${NC}"
    # Remove old database file for clean start
    if [ -f "$DB_FILE" ]; then
        echo "Removing old database file..."
        rm -f "$DB_FILE"
    fi
    run_sql "$SCRIPT_DIR/setup.sql"
}

cmd_setup_env() {
    echo -e "${GREEN}Setting up DuckDB with environment variables...${NC}"

    # Check if required environment variables are set
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo -e "${YELLOW}Warning: AWS credentials not found in environment${NC}"
        echo "Please set the following environment variables:"
        echo "  export AWS_ACCESS_KEY_ID=your_key_id"
        echo "  export AWS_SECRET_ACCESS_KEY=your_secret_key"
        echo "  export AWS_DEFAULT_REGION=ap-northeast-1  # (optional)"
        exit 1
    fi

    # Remove old database file for clean start
    if [ -f "$DB_FILE" ]; then
        echo "Removing old database file..."
        rm -f "$DB_FILE"
    fi

    run_sql "$SCRIPT_DIR/setup_s3_env.sql"
}

cmd_diagnose() {
    echo -e "${GREEN}Diagnosing S3 access and AWS credentials...${NC}"
    run_sql "$SCRIPT_DIR/diagnose_s3.sql"
}

cmd_load() {
    local s3_path="$1"
    if [ -z "$s3_path" ]; then
        echo -e "${RED}Error: S3 path is required${NC}"
        echo "Usage: $0 load <s3_path>"
        exit 1
    fi

    echo -e "${GREEN}Loading ALB logs from: $s3_path${NC}"

    # Remove old database file for clean start
    if [ -f "$DB_FILE" ]; then
        echo "Removing old database file..."
        rm -f "$DB_FILE"
    fi

    run_sql_with_replacement "$SCRIPT_DIR/load_template.sql" "$s3_path"
}

cmd_errors() {
    echo -e "${GREEN}Analyzing errors...${NC}"
    sed "s|{{TABLE_NAME}}|$TABLE_NAME|g" "$SCRIPT_DIR/analyze_errors.sql" | duckdb "$DB_FILE"
}

cmd_performance() {
    echo -e "${GREEN}Analyzing performance...${NC}"
    sed "s|{{TABLE_NAME}}|$TABLE_NAME|g" "$SCRIPT_DIR/analyze_performance.sql" | duckdb "$DB_FILE"
}

cmd_query() {
    local query_file="$1"
    if [ -z "$query_file" ]; then
        echo -e "${RED}Error: Query file is required${NC}"
        echo "Usage: $0 query <sql_file>"
        exit 1
    fi

    if [ ! -f "$query_file" ]; then
        echo -e "${RED}Error: Query file not found: $query_file${NC}"
        exit 1
    fi

    echo -e "${GREEN}Executing query from: $query_file${NC}"
    run_sql "$query_file"
}

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --db)
            DB_FILE="$2"
            shift 2
            ;;
        --table)
            TABLE_NAME="$2"
            shift 2
            ;;
        setup|setup-env|diagnose|load|errors|performance|query)
            COMMAND="$1"
            shift
            break
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Execute command
case $COMMAND in
    setup)
        cmd_setup
        ;;
    setup-env)
        cmd_setup_env
        ;;
    diagnose)
        cmd_diagnose
        ;;
    load)
        cmd_load "$@"
        ;;
    errors)
        cmd_errors
        ;;
    performance)
        cmd_performance
        ;;
    query)
        cmd_query "$@"
        ;;
    *)
        usage
        ;;
esac
