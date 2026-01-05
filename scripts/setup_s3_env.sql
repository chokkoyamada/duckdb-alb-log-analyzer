-- DuckDB setup for ALB log analysis with environment variables
-- This method uses AWS credentials from environment variables
-- Make sure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set

INSTALL aws;
LOAD aws;

INSTALL httpfs;
LOAD httpfs;

-- Create S3 secret using environment variables
CREATE SECRET (
    TYPE S3,
    PROVIDER CONFIG,
    KEY_ID getenv('AWS_ACCESS_KEY_ID'),
    SECRET getenv('AWS_SECRET_ACCESS_KEY'),
    REGION getenv('AWS_DEFAULT_REGION')
);

-- Verify setup
SELECT 'Setup completed with environment variables' as status;
SELECT 'AWS_ACCESS_KEY_ID: ' ||
    CASE WHEN getenv('AWS_ACCESS_KEY_ID') IS NOT NULL THEN 'Set' ELSE 'Not set' END as aws_key;
SELECT 'AWS_SECRET_ACCESS_KEY: ' ||
    CASE WHEN getenv('AWS_SECRET_ACCESS_KEY') IS NOT NULL THEN 'Set' ELSE 'Not set' END as aws_secret;
SELECT 'AWS_DEFAULT_REGION: ' ||
    CASE WHEN getenv('AWS_DEFAULT_REGION') IS NOT NULL THEN getenv('AWS_DEFAULT_REGION') ELSE 'Not set (will use default)' END as aws_region;
