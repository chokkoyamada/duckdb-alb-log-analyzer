-- Analyze response time performance from ALB logs
-- Replace {{TABLE_NAME}} before executing

-- Overall performance statistics
SELECT
    COUNT(*) as total_requests,
    ROUND(AVG(target_processing_time), 3) as avg_target_time,
    ROUND(AVG(response_processing_time), 3) as avg_response_time,
    ROUND(AVG(request_processing_time + target_processing_time + response_processing_time), 3) as avg_total_time,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY target_processing_time), 3) as p50_target_time,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY target_processing_time), 3) as p95_target_time,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY target_processing_time), 3) as p99_target_time
FROM {{TABLE_NAME}};

-- Slowest requests
SELECT
    timestamp,
    request,
    request_processing_time,
    target_processing_time,
    response_processing_time,
    (request_processing_time + target_processing_time + response_processing_time) as total_time,
    elb_status_code
FROM {{TABLE_NAME}}
ORDER BY total_time DESC
LIMIT 50;

-- Average response time by hour
SELECT
    DATE_TRUNC('hour', timestamp) as hour,
    COUNT(*) as request_count,
    ROUND(AVG(target_processing_time), 3) as avg_target_time,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY target_processing_time), 3) as p95_target_time
FROM {{TABLE_NAME}}
GROUP BY hour
ORDER BY hour DESC;

-- Requests with high processing time (>1 second)
SELECT
    COUNT(*) as slow_requests,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM {{TABLE_NAME}}), 2) as percentage
FROM {{TABLE_NAME}}
WHERE target_processing_time > 1.0;
