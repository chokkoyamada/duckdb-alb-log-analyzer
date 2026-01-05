-- DuckDB setup for ALB log analysis with AWS profile
-- This uses credential_chain to read from ~/.aws/credentials automatically
-- No credentials are exposed in commands or environment variables

INSTALL aws;
LOAD aws;

INSTALL httpfs;
LOAD httpfs;

-- Create S3 secret using credential chain
-- This will read from ~/.aws/credentials and environment variables
CREATE SECRET (
    TYPE S3,
    PROVIDER CREDENTIAL_CHAIN,
    CHAIN 'env;config'
);

-- Verify setup
SELECT 'Setup completed with credential chain (env;config)' as status;
