[
    {
        "name": "app",
        "image": "${app_image}",
        "essential": true,
        "portMappings": [
            {
                "containerPort": 3000,
                "hostPort": 3000
            }
        ],
        "memoryReservation": 256,
        "environment": [
            {"name": "APP_HOST", "value": "127.0.0.1"},
            {"name": "APP_PORT", "value": "3000"},
            {"name": "LISTEN_PORT", "value": "3000"},
            {"name": "DB_HOST", "value": "${db_host}"},
            {"name": "DB_NAME", "value": "${db_name}"},
            {"name": "DB_USER", "value": "${db_user}"},
            {"name": "DB_PASS", "value": "${db_pass}"},
            {"name": "ALLOWED_HOSTS", "value": "${allowed_hosts}"},
            {"name": "NODE_ENV", "value": "${node_env}"}
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${log_group_name}",
                "awslogs-region": "${log_group_region}",
                "awslogs-stream-prefix": "app"
            }
        }
    }
]
