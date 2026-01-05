# ALB Log Schema Reference

Application Load Balancer (ALB) logs contain the following fields in space-delimited format:

## Core Fields

### type
- **Type**: VARCHAR
- **Description**: Type of request (http, https, h2, ws, wss)

### timestamp
- **Type**: TIMESTAMP
- **Description**: Time when the load balancer received the request
- **Format**: ISO 8601 format

### elb
- **Type**: VARCHAR
- **Description**: Resource ID of the load balancer

## Client & Target Information

### client_ip_port
- **Type**: VARCHAR
- **Description**: IP address and port of the requesting client
- **Format**: `ip:port`

### target_ip_port
- **Type**: VARCHAR
- **Description**: IP address and port of the target that processed the request
- **Format**: `ip:port` or `-` if not applicable

## Performance Metrics

### request_processing_time
- **Type**: DOUBLE
- **Description**: Time (in seconds) from when the load balancer received the request to when it sent the request to a target
- **Unit**: Seconds
- **Note**: `-1` if the load balancer can't dispatch the request

### target_processing_time
- **Type**: DOUBLE
- **Description**: Time (in seconds) from when the load balancer sent the request to a target until the target started to send the response headers
- **Unit**: Seconds
- **Note**: `-1` if the connection is closed before receiving a response

### response_processing_time
- **Type**: DOUBLE
- **Description**: Time (in seconds) from when the load balancer received the response header from the target until it started to send the response to the client
- **Unit**: Seconds
- **Note**: `-1` if the connection is closed before receiving a response

## Status Codes

### elb_status_code
- **Type**: INTEGER
- **Description**: HTTP status code of the response from the load balancer
- **Common Values**:
  - `200`: Success
  - `301`, `302`: Redirects
  - `400`: Bad request
  - `403`: Forbidden
  - `404`: Not found
  - `500`: Internal server error
  - `502`: Bad gateway
  - `503`: Service unavailable
  - `504`: Gateway timeout

### target_status_code
- **Type**: VARCHAR
- **Description**: HTTP status code of the response from the target
- **Note**: `-` if no response from target

## Data Transfer

### received_bytes
- **Type**: BIGINT
- **Description**: Size of the request (in bytes) received from the client

### sent_bytes
- **Type**: BIGINT
- **Description**: Size of the response (in bytes) sent to the client

## Request Details

### request
- **Type**: VARCHAR
- **Description**: Request line from the client
- **Format**: `"METHOD URL HTTP/VERSION"`
- **Example**: `"GET https://example.com:443/path?query=value HTTP/1.1"`

### user_agent
- **Type**: VARCHAR
- **Description**: User-Agent header value from the request
- **Note**: Enclosed in double quotes

## SSL/TLS Information

### ssl_cipher
- **Type**: VARCHAR
- **Description**: SSL cipher suite negotiated
- **Example**: `ECDHE-RSA-AES128-GCM-SHA256`
- **Note**: `-` for non-HTTPS requests

### ssl_protocol
- **Type**: VARCHAR
- **Description**: SSL/TLS protocol version
- **Example**: `TLSv1.2`, `TLSv1.3`
- **Note**: `-` for non-HTTPS requests

## Routing Information

### target_group_arn
- **Type**: VARCHAR
- **Description**: ARN of the target group that handled the request

### trace_id
- **Type**: VARCHAR
- **Description**: X-Amzn-Trace-Id header value
- **Format**: `Root=...`

### domain_name
- **Type**: VARCHAR
- **Description**: SNI domain provided by the client during TLS handshake
- **Note**: `-` if not applicable

### chosen_cert_arn
- **Type**: VARCHAR
- **Description**: ARN of the certificate presented to the client
- **Note**: `-` if not applicable

### matched_rule_priority
- **Type**: VARCHAR
- **Description**: Priority value of the rule that matched the request
- **Note**: `0` for default action, `-` if no rule matched

## Advanced Fields

### request_creation_time
- **Type**: TIMESTAMP
- **Description**: Time when the load balancer received the request
- **Format**: ISO 8601 format

### actions_executed
- **Type**: VARCHAR
- **Description**: Actions taken in processing the request
- **Examples**: `forward`, `redirect`, `fixed-response`

### redirect_url
- **Type**: VARCHAR
- **Description**: URL of the redirect target
- **Note**: `-` if not a redirect

### error_reason
- **Type**: VARCHAR
- **Description**: Error reason code
- **Note**: `-` if no error
- **Common Values**:
  - `TargetFailedHealthChecks`
  - `TargetTimeout`
  - `TargetResponseCodeMismatch`

### target_port_list
- **Type**: VARCHAR
- **Description**: List of IP addresses and ports for targets that processed the request

### target_status_code_list
- **Type**: VARCHAR
- **Description**: List of status codes from targets

### classification
- **Type**: VARCHAR
- **Description**: Classification of desync mitigation
- **Note**: `-` if not applicable

### classification_reason
- **Type**: VARCHAR
- **Description**: Reason for classification
- **Note**: `-` if not applicable

### conn_trace_id
- **Type**: VARCHAR
- **Description**: Connection trace ID for tracking requests across connections
- **Note**: `-` if not applicable

## Request Transformation Fields

### transformed_host
- **Type**: VARCHAR
- **Description**: The host header after ALB transformations have been applied
- **Note**: `-` if no transformation occurred

### transformed_uri
- **Type**: VARCHAR
- **Description**: The URI path after ALB transformations have been applied
- **Note**: `-` if no transformation occurred

### request_transform_status
- **Type**: VARCHAR
- **Description**: Status of the request transformation process
- **Note**: `-` if no transformation occurred

## Common Query Patterns

### Extract HTTP method from request
```sql
SELECT SPLIT_PART(request, ' ', 1) as method
FROM alb_logs
```

### Extract URL path from request
```sql
SELECT SPLIT_PART(SPLIT_PART(request, ' ', 2), '?', 1) as path
FROM alb_logs
```

### Calculate total processing time
```sql
SELECT
    request_processing_time + target_processing_time + response_processing_time as total_time
FROM alb_logs
```
