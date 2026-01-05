# ALB Log Query Examples

Common SQL queries for analyzing ALB logs with DuckDB.

## Basic Queries

### Count total requests
```sql
SELECT COUNT(*) as total_requests
FROM alb_logs;
```

### Show recent logs
```sql
SELECT *
FROM alb_logs
ORDER BY timestamp DESC
LIMIT 10;
```

### Get date range
```sql
SELECT
    MIN(timestamp) as first_log,
    MAX(timestamp) as last_log
FROM alb_logs;
```

## Error Analysis

### Status code distribution
```sql
SELECT
    elb_status_code,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM alb_logs
GROUP BY elb_status_code
ORDER BY count DESC;
```

### 4xx errors
```sql
SELECT
    timestamp,
    elb_status_code,
    request,
    client_ip_port
FROM alb_logs
WHERE elb_status_code BETWEEN 400 AND 499
ORDER BY timestamp DESC
LIMIT 100;
```

### 5xx errors with details
```sql
SELECT
    timestamp,
    elb_status_code,
    target_status_code,
    request,
    error_reason,
    target_ip_port
FROM alb_logs
WHERE elb_status_code >= 500
ORDER BY timestamp DESC;
```

### Error timeline (hourly)
```sql
SELECT
    DATE_TRUNC('hour', timestamp) as hour,
    elb_status_code,
    COUNT(*) as count
FROM alb_logs
WHERE elb_status_code >= 400
GROUP BY hour, elb_status_code
ORDER BY hour DESC, count DESC;
```

## Performance Analysis

### Response time percentiles
```sql
SELECT
    ROUND(AVG(target_processing_time), 3) as avg_time,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY target_processing_time), 3) as p50,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY target_processing_time), 3) as p95,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY target_processing_time), 3) as p99,
    ROUND(MAX(target_processing_time), 3) as max_time
FROM alb_logs
WHERE target_processing_time >= 0;
```

### Slow requests (>1 second)
```sql
SELECT
    timestamp,
    request,
    target_processing_time,
    elb_status_code
FROM alb_logs
WHERE target_processing_time > 1.0
ORDER BY target_processing_time DESC
LIMIT 100;
```

### Average response time by hour
```sql
SELECT
    DATE_TRUNC('hour', timestamp) as hour,
    COUNT(*) as request_count,
    ROUND(AVG(target_processing_time), 3) as avg_time,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY target_processing_time), 3) as p95_time
FROM alb_logs
WHERE target_processing_time >= 0
GROUP BY hour
ORDER BY hour DESC;
```

## Request Analysis

### Top request paths
```sql
SELECT
    SPLIT_PART(SPLIT_PART(request, ' ', 2), '?', 1) as path,
    COUNT(*) as count
FROM alb_logs
WHERE request != '-'
GROUP BY path
ORDER BY count DESC
LIMIT 50;
```

### HTTP methods distribution
```sql
SELECT
    SPLIT_PART(request, ' ', 1) as method,
    COUNT(*) as count
FROM alb_logs
WHERE request != '-'
GROUP BY method
ORDER BY count DESC;
```

### Top user agents
```sql
SELECT
    user_agent,
    COUNT(*) as count
FROM alb_logs
WHERE user_agent != '-'
GROUP BY user_agent
ORDER BY count DESC
LIMIT 20;
```

### Requests by client IP
```sql
SELECT
    SPLIT_PART(client_ip_port, ':', 1) as ip,
    COUNT(*) as request_count
FROM alb_logs
GROUP BY ip
ORDER BY request_count DESC
LIMIT 50;
```

## Traffic Analysis

### Requests per hour
```sql
SELECT
    DATE_TRUNC('hour', timestamp) as hour,
    COUNT(*) as request_count
FROM alb_logs
GROUP BY hour
ORDER BY hour DESC;
```

### Requests per day
```sql
SELECT
    DATE_TRUNC('day', timestamp) as day,
    COUNT(*) as request_count
FROM alb_logs
GROUP BY day
ORDER BY day DESC;
```

### Peak hours
```sql
SELECT
    EXTRACT(HOUR FROM timestamp) as hour_of_day,
    COUNT(*) as request_count,
    ROUND(AVG(target_processing_time), 3) as avg_response_time
FROM alb_logs
GROUP BY hour_of_day
ORDER BY request_count DESC;
```

### Data transfer analysis
```sql
SELECT
    COUNT(*) as request_count,
    ROUND(SUM(received_bytes) / 1024 / 1024 / 1024, 2) as total_received_gb,
    ROUND(SUM(sent_bytes) / 1024 / 1024 / 1024, 2) as total_sent_gb,
    ROUND(AVG(received_bytes), 0) as avg_received_bytes,
    ROUND(AVG(sent_bytes), 0) as avg_sent_bytes
FROM alb_logs;
```

## Target Analysis

### Requests per target
```sql
SELECT
    target_ip_port,
    COUNT(*) as request_count,
    ROUND(AVG(target_processing_time), 3) as avg_response_time
FROM alb_logs
WHERE target_ip_port != '-'
GROUP BY target_ip_port
ORDER BY request_count DESC;
```

### Target errors
```sql
SELECT
    target_ip_port,
    COUNT(*) as error_count
FROM alb_logs
WHERE target_status_code >= '500'
GROUP BY target_ip_port
ORDER BY error_count DESC;
```

## SSL/TLS Analysis

### SSL protocol distribution
```sql
SELECT
    ssl_protocol,
    COUNT(*) as count
FROM alb_logs
WHERE ssl_protocol != '-'
GROUP BY ssl_protocol
ORDER BY count DESC;
```

### SSL cipher distribution
```sql
SELECT
    ssl_cipher,
    COUNT(*) as count
FROM alb_logs
WHERE ssl_cipher != '-'
GROUP BY ssl_cipher
ORDER BY count DESC
LIMIT 20;
```

## Advanced Queries

### Response time by status code
```sql
SELECT
    elb_status_code,
    COUNT(*) as count,
    ROUND(AVG(target_processing_time), 3) as avg_time,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY target_processing_time), 3) as p95_time
FROM alb_logs
WHERE target_processing_time >= 0
GROUP BY elb_status_code
ORDER BY count DESC;
```

### Correlation between request size and response time
```sql
SELECT
    CASE
        WHEN received_bytes < 1000 THEN '< 1KB'
        WHEN received_bytes < 10000 THEN '1KB - 10KB'
        WHEN received_bytes < 100000 THEN '10KB - 100KB'
        WHEN received_bytes < 1000000 THEN '100KB - 1MB'
        ELSE '> 1MB'
    END as size_range,
    COUNT(*) as count,
    ROUND(AVG(target_processing_time), 3) as avg_response_time
FROM alb_logs
WHERE target_processing_time >= 0
GROUP BY size_range
ORDER BY MIN(received_bytes);
```

### Session analysis (by trace ID)
```sql
SELECT
    trace_id,
    COUNT(*) as request_count,
    MIN(timestamp) as first_request,
    MAX(timestamp) as last_request
FROM alb_logs
WHERE trace_id != '-'
GROUP BY trace_id
HAVING COUNT(*) > 10
ORDER BY request_count DESC
LIMIT 50;
```

## Export Results

### Export to CSV
```sql
COPY (
    SELECT *
    FROM alb_logs
    WHERE elb_status_code >= 500
) TO 'errors.csv' (HEADER, DELIMITER ',');
```

### Export to Parquet
```sql
COPY (
    SELECT *
    FROM alb_logs
) TO 'alb_logs.parquet' (FORMAT PARQUET);
```

### Create summary table
```sql
CREATE TABLE daily_summary AS
SELECT
    DATE_TRUNC('day', timestamp) as day,
    COUNT(*) as total_requests,
    SUM(CASE WHEN elb_status_code >= 500 THEN 1 ELSE 0 END) as error_5xx_count,
    SUM(CASE WHEN elb_status_code >= 400 AND elb_status_code < 500 THEN 1 ELSE 0 END) as error_4xx_count,
    ROUND(AVG(target_processing_time), 3) as avg_response_time,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY target_processing_time), 3) as p95_response_time
FROM alb_logs
WHERE target_processing_time >= 0
GROUP BY day
ORDER BY day DESC;
```
