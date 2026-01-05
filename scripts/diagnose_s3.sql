-- Diagnose S3 access and AWS credentials setup

-- Check if extensions are installed
SELECT extension_name, installed, loaded
FROM duckdb_extensions()
WHERE extension_name IN ('aws', 'httpfs');

-- Check environment variables
SELECT 'Environment Variables Check' as check_type;
SELECT 'AWS_ACCESS_KEY_ID' as variable,
    CASE WHEN getenv('AWS_ACCESS_KEY_ID') IS NOT NULL THEN 'Set (length: ' || LENGTH(getenv('AWS_ACCESS_KEY_ID'))::VARCHAR || ')' ELSE 'Not set' END as status;
SELECT 'AWS_SECRET_ACCESS_KEY' as variable,
    CASE WHEN getenv('AWS_SECRET_ACCESS_KEY') IS NOT NULL THEN 'Set (length: ' || LENGTH(getenv('AWS_SECRET_ACCESS_KEY'))::VARCHAR || ')' ELSE 'Not set' END as status;
SELECT 'AWS_DEFAULT_REGION' as variable,
    CASE WHEN getenv('AWS_DEFAULT_REGION') IS NOT NULL THEN 'Set (' || getenv('AWS_DEFAULT_REGION') || ')' ELSE 'Not set' END as status;
SELECT 'AWS_SESSION_TOKEN' as variable,
    CASE WHEN getenv('AWS_SESSION_TOKEN') IS NOT NULL THEN 'Set (for temporary credentials)' ELSE 'Not set' END as status;

-- Show current secrets (without exposing sensitive data)
SELECT 'Configured Secrets' as check_type;
SELECT name, type, provider
FROM duckdb_secrets();
