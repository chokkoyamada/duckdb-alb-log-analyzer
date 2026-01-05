-- Analyze error responses from ALB logs
-- Replace {{TABLE_NAME}} before executing

-- Summary of status codes
SELECT
    elb_status_code,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM {{TABLE_NAME}}
GROUP BY elb_status_code
ORDER BY count DESC;

-- Error details (non-200 responses)
SELECT
    timestamp,
    elb_status_code,
    target_status_code,
    request,
    error_reason,
    client_ip_port,
    target_ip_port
FROM {{TABLE_NAME}}
WHERE elb_status_code != 200
ORDER BY timestamp DESC
LIMIT 100;

-- 5xx errors by hour
SELECT
    DATE_TRUNC('hour', timestamp) as hour,
    COUNT(*) as error_count
FROM {{TABLE_NAME}}
WHERE elb_status_code >= 500
GROUP BY hour
ORDER BY hour DESC;

-- Most common error reasons
SELECT
    error_reason,
    COUNT(*) as count
FROM {{TABLE_NAME}}
WHERE error_reason != '-'
GROUP BY error_reason
ORDER BY count DESC;
