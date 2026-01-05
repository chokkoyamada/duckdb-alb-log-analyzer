# DuckDB ALB Log Analyzer - Claude Code Skill

A Claude Code skill for analyzing AWS Application Load Balancer (ALB) logs using DuckDB. Query ALB access logs stored in S3 directly for error analysis, performance analysis, traffic analysis, and more.

## Features

- **Fast Analysis**: High-performance S3 data processing with DuckDB
- **Flexible Queries**: Analyze logs freely using SQL
- **Secure**: Safe handling of AWS credentials
- **Easy Setup**: Get started with simple commands
- **Claude Code Integration**: Request analysis using natural language in Claude Code

## Prerequisites

- [DuckDB](https://duckdb.org/docs/installation/) installed
- AWS CLI configured or AWS credentials available
- ALB logs stored in S3

### Installing DuckDB

```bash
# macOS
brew install duckdb

# Other platforms
# See https://duckdb.org/docs/installation/
```

## Installation

### Method 1: Plugin Marketplace (Recommended)

Install directly from the Claude Code plugin marketplace:

```bash
# In Claude Code, run:
/plugin marketplace add chokkoyamada/duckdb-alb-log-analyzer

# Then install the plugin:
/plugin install duckdb-alb-log-analyzer
```

### Method 2: Manual Installation

Install this skill manually into Claude Code:

```bash
# Navigate to skills directory
cd ~/.claude/skills/

# Clone this repository
git clone https://github.com/chokkoyamada/duckdb-alb-log-analyzer.git duckdb-alb-log-analyzer

# Grant execute permissions to scripts
chmod +x duckdb-alb-log-analyzer/scripts/*.sh
```

## Quick Start

### Secure Method (Recommended)

For AWS named profiles, this method keeps credentials private:

```bash
cd ~/.claude/skills/duckdb-alb-log-analyzer

# One-time setup (credentials read from ~/.aws/credentials)
./scripts/setup_with_profile.sh your-profile-name

# Load logs (profile name only, credentials stay secure)
./scripts/load_with_profile.sh your-profile-name 's3://bucket/path/**/*.log.gz'

# Run analysis
./scripts/analyze.sh errors       # Error analysis
./scripts/analyze.sh performance  # Performance analysis
```

**Security**: Only profile names appear in commands and logs. Credentials are read internally from `~/.aws/credentials`.

### Standard Method

```bash
# Setup (uses CREDENTIAL_CHAIN)
./scripts/analyze.sh setup

# Load logs
./scripts/analyze.sh load 's3://my-bucket/AWSLogs/123456789012/elasticloadbalancing/us-east-1/2024/**/*.log.gz'

# Error analysis
./scripts/analyze.sh errors

# Performance analysis
./scripts/analyze.sh performance
```

## Using with Claude Code

After installing the skill, you can request analysis using natural language in Claude Code:

```
# In Claude Code
"Analyze ALB logs from S3 and investigate errors from the past week"
"Find requests with slow response times"
"Analyze requests from a specific IP address"
```

## Database File Location

By default, the DuckDB database file is stored at:

```
/tmp/alb-log-analyzer-${USER}/alb_analysis.duckdb
```

**Important**: The database file is automatically deleted when you run `setup` or `load` commands. This ensures:
- Clean start with each analysis
- No accumulation of old data in /tmp
- Reduced disk space usage

To use a custom location, set the `DB_FILE` environment variable:

```bash
export DB_FILE=/path/to/custom/database.duckdb
```

## Key Features

### Error Analysis

Analyze HTTP errors, status code distributions, and error patterns:

```bash
./scripts/analyze.sh errors
```

Provides:
- Status code distribution
- Error details (non-200 responses)
- 5xx errors by hour
- Common error reasons

### Performance Analysis

Analyze response times and latency:

```bash
./scripts/analyze.sh performance
```

Provides:
- Response time statistics (avg, p50, p95, p99)
- Slowest requests
- Response time trends by hour
- Slow request percentage

### Custom Queries

Execute custom SQL queries:

```bash
# Using a custom SQL file
./scripts/analyze.sh query my_query.sql

# Or directly with DuckDB
duckdb /tmp/alb-log-analyzer-${USER}/alb_analysis.duckdb
```

## AWS Credentials Setup

DuckDB needs AWS credentials to access S3. Choose one of these methods:

### Option 1: AWS CLI Configuration (Recommended)

If you have AWS CLI configured, DuckDB can use those credentials:

```bash
# Check if AWS CLI is configured
aws s3 ls

# If not configured
aws configure
```

### Option 2: Environment Variables

Export credentials in your shell:

```bash
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_DEFAULT_REGION=ap-northeast-1
```

### Option 3: AWS Credentials File

Create or edit `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

For detailed configuration options, see [SKILL.md](SKILL.md).

## Troubleshooting

### S3 Access Issues

If you get "Access Denied" or credential errors when loading from S3:

```bash
# Diagnose the issue
./scripts/analyze.sh diagnose

# Verify AWS credentials work
aws s3 ls s3://your-bucket/path/to/logs/
```

For detailed troubleshooting guide, see [SKILL.md](SKILL.md).

## Directory Structure

```
.
├── SKILL.md                    # Claude Code skill definition and documentation
├── README.md                   # This file
├── references/                 # Reference documentation
│   ├── alb_schema.md          # ALB log schema definitions
│   └── query_examples.md      # Query examples
└── scripts/                   # Analysis scripts
    ├── analyze.sh             # Main analysis script
    ├── setup_with_profile.sh  # Secure setup with AWS profile
    ├── load_with_profile.sh   # Secure log loading with AWS profile
    ├── load_profile.sh        # Profile credentials helper
    ├── setup.sql              # DuckDB initialization (CREDENTIAL_CHAIN)
    ├── setup_s3_env.sql       # DuckDB initialization (environment variables)
    ├── diagnose_s3.sql        # S3 access diagnostics
    ├── load_template.sql      # Log loading template
    ├── analyze_errors.sql     # Error analysis queries
    └── analyze_performance.sql # Performance analysis queries
```

## Reference

### ALB Log Schema

See [references/alb_schema.md](references/alb_schema.md) for complete field definitions and data types.

Key fields:
- `timestamp`: Request timestamp
- `elb_status_code`: HTTP status from ALB
- `target_status_code`: HTTP status from target
- `request`: Full HTTP request line
- `target_processing_time`: Response time from target
- `client_ip_port`: Client address and port
- `error_reason`: Error details if applicable

### Query Examples

See [references/query_examples.md](references/query_examples.md) for comprehensive query examples including:
- Error analysis queries
- Performance metrics
- Traffic analysis
- SSL/TLS analysis
- Data export patterns

## License

MIT License

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Links

- [DuckDB](https://duckdb.org/)
- [AWS ALB Access Logs](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html)
- [Claude Code](https://claude.com/claude-code)
