-- DuckDB setup for ALB log analysis
-- Install and load required extensions

INSTALL aws;
LOAD aws;

INSTALL httpfs;
LOAD httpfs;

-- Create S3 secret using credential chain
CREATE SECRET (
    TYPE S3,
    PROVIDER CREDENTIAL_CHAIN
);

-- Verify setup
SELECT 'Setup completed successfully' as status;
