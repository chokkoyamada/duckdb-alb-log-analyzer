-- Template for loading ALB logs from S3
-- Replace {{S3_PATH}} and {{TABLE_NAME}} before executing

CREATE OR REPLACE TABLE {{TABLE_NAME}} AS
SELECT *
FROM read_csv(
    '{{S3_PATH}}',
    columns={
        'type': 'VARCHAR',
        'timestamp': 'TIMESTAMP',
        'elb': 'VARCHAR',
        'client_ip_port': 'VARCHAR',
        'target_ip_port': 'VARCHAR',
        'request_processing_time': 'DOUBLE',
        'target_processing_time': 'DOUBLE',
        'response_processing_time': 'DOUBLE',
        'elb_status_code': 'INTEGER',
        'target_status_code': 'VARCHAR',
        'received_bytes': 'BIGINT',
        'sent_bytes': 'BIGINT',
        'request': 'VARCHAR',
        'user_agent': 'VARCHAR',
        'ssl_cipher': 'VARCHAR',
        'ssl_protocol': 'VARCHAR',
        'target_group_arn': 'VARCHAR',
        'trace_id': 'VARCHAR',
        'domain_name': 'VARCHAR',
        'chosen_cert_arn': 'VARCHAR',
        'matched_rule_priority': 'VARCHAR',
        'request_creation_time': 'TIMESTAMP',
        'actions_executed': 'VARCHAR',
        'redirect_url': 'VARCHAR',
        'error_reason': 'VARCHAR',
        'target_port_list': 'VARCHAR',
        'target_status_code_list': 'VARCHAR',
        'classification': 'VARCHAR',
        'classification_reason': 'VARCHAR',
        'conn_trace_id': 'VARCHAR',
        'transformed_host': 'VARCHAR',
        'transformed_uri': 'VARCHAR',
        'request_transform_status': 'VARCHAR'
    },
    delim=' ',
    quote='"',
    escape='"',
    header=false,
    auto_detect=false
);

-- Display summary
SELECT
    'Loaded ' || COUNT(*)::VARCHAR || ' log entries' as summary
FROM {{TABLE_NAME}};
