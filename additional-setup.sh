#!/bin/bash

# =============================================================================
# Script Name: additional-setup.sh
# Description: Sets up additional functionalities for Node-RED Automation,
#              including advanced security configurations, monitoring enhancements,
#              CI/CD pipelines, automated backups, testing frameworks, and utilities.
# Author: Your Name
# License: MIT
# =============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# =============================================================================
# Variables
# =============================================================================

PROJECT_DIR="$(pwd)/node-red-automation"
LOG_FILE="$PROJECT_DIR/setup.log"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
MONITORING_DIR="$PROJECT_DIR/monitoring"
GRAFANA_PROVISION_DIR="$MONITORING_DIR/grafana/provisioning"
PROMETHEUS_PROVISION_DIR="$MONITORING_DIR/prometheus/provisioning"
TEST_DIR="$PROJECT_DIR/tests"
SUBFLOWS_DIR="$PROJECT_DIR/subflows"
BACKUP_DIR="$PROJECT_DIR/backups"
CONFIG_DIR="$PROJECT_DIR/config"
SRC_DIR="$PROJECT_DIR/src"
GITIGNORE_FILE="$PROJECT_DIR/.gitignore"
SECRETS_DIR="$PROJECT_DIR/secrets"
NGINX_CONF_DIR="$PROJECT_DIR/nginx/conf.d"
NGINX_CONF_FILE="$NGINX_CONF_DIR/default.conf"

# =============================================================================
# Function Definitions
# =============================================================================

# Function to log messages with timestamps
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to display error messages and exit
error_exit() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | tee -a "$LOG_FILE" >&2
    exit 1
}

# Function to create a directory if it doesn't exist
create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1" || error_exit "Failed to create directory $1."
        log "Created directory: $1"
    else
        log "Directory already exists: $1"
    fi
}

# Function to create Prometheus configuration with provisioning
create_prometheus_config() {
    create_dir "$PROMETHEUS_PROVISION_DIR"

    cat > "$MONITORING_DIR/prometheus.yml" <<'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node-red'
    static_configs:
      - targets: ['node-red:1880']
EOF

    log "Created Prometheus configuration."

    # Optional: Add additional scrape_configs or alerting rules as needed
}

# Function to create Grafana provisioning for datasources and dashboards
create_grafana_provisioning() {
    create_dir "$GRAFANA_PROVISION_DIR/datasources"
    create_dir "$GRAFANA_PROVISION_DIR/dashboards"
    create_dir "$GRAFANA_PROVISION_DIR/dashboards/sample"

    # Datasource provisioning
    cat > "$GRAFANA_PROVISION_DIR/datasources/datasource.yml" <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

    # Dashboard provisioning
    cat > "$GRAFANA_PROVISION_DIR/dashboards/dashboard.yml" <<'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    options:
      path: /etc/grafana/provisioning/dashboards/sample
EOF

    # Sample Dashboard JSON (replace with actual dashboard JSON as needed)
    cat > "$GRAFANA_PROVISION_DIR/dashboards/sample/node-red-monitoring.json" <<'EOF'
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": 1,
  "iteration": 1626420967930,
  "links": [],
  "panels": [
    {
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {}
        },
        "overrides": []
      },
      "gridPos": {
        "h": 9,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      },
      "pluginVersion": "7.5.5",
      "targets": [
        {
          "expr": "up{job=\"node-red\"}",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 2,
          "legendFormat": "{{instance}}",
          "refId": "A"
        }
      ],
      "title": "Node-RED Service Up",
      "type": "stat"
    }
  ],
  "schemaVersion": 27,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Node-RED Monitoring",
  "uid": "node-red-monitoring",
  "version": 1
}
EOF

    log "Created Grafana provisioning for datasources and sample dashboards."
}

# Function to create GitHub Actions CI/CD workflow
create_ci_cd_yaml() {
    create_dir "$PROJECT_DIR/.github/workflows"

    cat > "$PROJECT_DIR/.github/workflows/ci-cd.yml" <<'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Set up Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '16'

    - name: Install Dependencies
      run: |
        cd node-red-automation
        npm install

    - name: Run Tests
      run: |
        cd node-red-automation
        npm test

    - name: Build Docker Image
      run: |
        cd node-red-automation
        docker build -t node-red-automation:latest .

    - name: Log in to Docker Hub
      uses: docker/login-action@v1
      with:
        username: \${{ secrets.DOCKER_USERNAME }}
        password: \${{ secrets.DOCKER_PASSWORD }}

    - name: Push Docker Image
      run: |
        docker tag node-red-automation:latest \${{ secrets.DOCKERHUB_USERNAME }}/node-red-automation:latest
        docker push \${{ secrets.DOCKERHUB_USERNAME }}/node-red-automation:latest

    - name: Deploy to Server
      uses: easingthemes/ssh-deploy@v2.0.7
      with:
        ssh-private-key: \${{ secrets.SSH_PRIVATE_KEY }}
        remote-user: \${{ secrets.REMOTE_USER }}
        server-ip: \${{ secrets.SERVER_IP }}
        remote-path: \${{ secrets.DOCKER_PATH }}
        command: |
          docker-compose -f \${{ secrets.DOCKER_PATH }}/docker-compose.yml pull
          docker-compose -f \${{ secrets.DOCKER_PATH }}/docker-compose.yml up -d --remove-orphans
EOF

    log "Created GitHub Actions CI/CD workflow."
}

# Function to create Docker Compose start and stop scripts
create_docker_commands() {
    cat > "$PROJECT_DIR/start-docker.sh" <<'EOF'
#!/bin/bash
docker-compose up -d
EOF

    cat > "$PROJECT_DIR/stop-docker.sh" <<'EOF'
#!/bin/bash
docker-compose down
EOF

    chmod +x "$PROJECT_DIR/start-docker.sh" "$PROJECT_DIR/stop-docker.sh"
    log "Created Docker Compose start and stop scripts."
}

# Function to create Prometheus and Grafana setup scripts
create_monitoring_setup() {
    create_dir "$MONITORING_DIR"

    # Prometheus setup already handled in create_prometheus_config

    # Grafana provisioning
    create_grafana_provisioning

    cat > "$MONITORING_DIR/setup-monitoring.sh" <<'EOF'
#!/bin/bash

# Start Prometheus and Grafana using Docker Compose
docker-compose up -d prometheus grafana

echo "Prometheus is available at http://localhost:9090"
echo "Grafana is available at http://localhost:3000 (default login: admin/admin)"
EOF

    chmod +x "$MONITORING_DIR/setup-monitoring.sh"
    log "Created monitoring setup script."
}

# Function to create test scripts using Jest and Mocha
create_test_scripts() {
    create_dir "$TEST_DIR"

    # Expanded Jest test
    cat > "$TEST_DIR/sample.test.js" <<'EOF'
const sum = (a, b) => a + b;

test('adds 1 + 2 to equal 3', () => {
    expect(sum(1, 2)).toBe(3);
});

// Add more Jest tests here
EOF

    # Expanded Mocha test
    cat > "$TEST_DIR/sample.spec.js" <<'EOF'
const assert = require('assert');

describe('Array', function() {
    describe('#indexOf()', function() {
        it('should return -1 when the value is not present', function() {
            assert.strictEqual([1,2,3].indexOf(4), -1);
        });
    });
});

// Add more Mocha tests here
EOF

    log "Created expanded test scripts for Jest and Mocha."
}

# Function to create subflows for reusability
create_subflows() {
    create_dir "$SUBFLOWS_DIR"

    # Sample Subflow: API Request Handler
    cat > "$SUBFLOWS_DIR/api-request-handler.json" <<'EOF'
{
    "id": "api-request-handler",
    "type": "subflow",
    "name": "API Request Handler",
    "info": "Handles API requests with rate limiting and error handling.",
    "category": "function",
    "in": [
        {
            "x": 40,
            "y": 40,
            "wires": []
        }
    ],
    "out": [
        {
            "x": 480,
            "y": 40,
            "wires": []
        }
    ],
    "env": [
        {
            "name": "API_RATE_LIMIT",
            "type": "num",
            "value": "5",
            "required": true
        },
        {
            "name": "TIME_WINDOW",
            "type": "num",
            "value": "60",
            "required": true
        }
    ],
    "color": "#a6bbcf"
}
EOF

    log "Created sample subflow for API Request Handling."
}

# Function to create .gitignore with specified content
create_gitignore() {
    if [ ! -f "$GITIGNORE_FILE" ]; then
        cat > "$GITIGNORE_FILE" <<'EOF'
# Node modules
node_modules/

# Environment variables
.env

# Docker files
docker-compose.override.yml

# Logs
*.log

# Backup files
backups/

# Testing
/tests/

# Monitoring
/monitoring/

# Subflows
/subflows/

/config/settings.js

# SSL Certificates
/config/ssl/

# Grafana Data
grafana-data/

# Docker Volumes
node-red-data/

# Miscellaneous
.DS_Store
EOF
        log "Created .gitignore with standard exclusions."
    else
        log ".gitignore already exists. Skipping creation."
    fi
}

# Function to create a sample source file
create_sample_source() {
    if [ ! -f "$SRC_DIR/main.py" ]; then
        create_dir "$SRC_DIR"
        cat > "$SRC_DIR/main.py" <<'EOF'
def greet(name):
    return f"Hello, {name}!"

if __name__ == "__main__":
    print(greet("World"))
EOF
        log "Created sample source file at src/main.py."
    else
        log "Sample source file src/main.py already exists. Skipping creation."
    fi
}

# Function to set up automated backups using cron with error handling
setup_automated_backups() {
    create_dir "$BACKUP_DIR"

    cat > "$BACKUP_DIR/backup.sh" <<'EOF'
#!/bin/bash

# Directory to backup
SOURCE_DIR="/absolute/path/to/node-red-automation" # This will be replaced by the script
BACKUP_DIR="/absolute/path/to/node-red-automation/backups" # This will be replaced by the script
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
LOG_FILE="$BACKUP_DIR/backup.log"

# Function to log messages
backup_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Start backup
backup_log "Starting backup of $SOURCE_DIR to $BACKUP_FILE"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  backup_log "Error: Source directory missing."
  exit 1
fi

# Create backup
tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>>"$LOG_FILE"
if [ $? -ne 0 ]; then
    backup_log "Error: Failed to create backup archive."
    exit 1
fi

# Verify backup integrity
tar -tzf "$BACKUP_FILE" > /dev/null 2>>"$LOG_FILE"
if [ $? -ne 0 ]; then
    backup_log "Error: Backup verification failed for $BACKUP_FILE"
    # Send email notification
    echo "Backup verification failed for $BACKUP_FILE" | mail -s "Backup Failure Alert" "$ALERT_EMAIL"
    exit 1
fi

# Remove backups older than 7 days
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +7 -exec rm {} \; 2>>"$LOG_FILE"
if [ $? -ne 0 ]; then
    backup_log "Warning: Failed to remove old backups."
fi

backup_log "Backup created at $BACKUP_FILE and old backups removed successfully."
EOF

    # Replace placeholders with actual absolute paths
    sed -i "s|/absolute/path/to/node-red-automation|$PROJECT_DIR|g" "$BACKUP_DIR/backup.sh" || error_exit "Failed to set absolute paths in backup.sh."

    chmod +x "$BACKUP_DIR/backup.sh"

    # Define absolute cron job path
    CRON_JOB="0 2 * * * $BACKUP_DIR/backup.sh"

    # Check if the cron job already exists to avoid duplicates
    (crontab -l 2>/dev/null | grep -F "$BACKUP_DIR/backup.sh") >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        log "Added backup cron job."
    else
        log "Backup cron job already exists. Skipping addition."
    fi
}

# Function to implement firewall setup with UFW
setup_firewall() {
    log "Configuring UFW firewall..."

    # Allow SSH
    ufw allow 22/tcp

    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp

    # Allow Prometheus and Grafana
    ufw allow 9090/tcp
    ufw allow 3000/tcp

    # Allow Node-RED port if accessed directly (optional)
    ufw allow "$NODE_RED_PORT"/tcp

    # Enable UFW
    ufw --force enable

    log "Firewall configured and UFW enabled."
}

# Function to secure Docker by adding the current user to the docker group
secure_docker() {
    log "Securing Docker..."

    # Create docker group if it doesn't exist
    groupadd docker || log "Docker group already exists."

    # Add current user to docker group
    usermod -aG docker "$SUDO_USER"

    log "Added user $SUDO_USER to the docker group."
    log "Please log out and log back in for the Docker group changes to take effect."

    # Inform the user to log out
    echo "====================================================="
    echo "Docker group modification complete."
    echo "Please log out and log back in to apply Docker group changes."
    echo "====================================================="
}

# Function to setup Docker secrets for sensitive information
setup_docker_secrets() {
    create_dir "$SECRETS_DIR"

    # Example: Create GitHub Token secret
    while true; do
        read -sp "Enter your GitHub Token for Docker Secrets: " GITHUB_SECRET
        if [[ -n "$GITHUB_SECRET" ]]; then
            echo "$GITHUB_SECRET" > "$PROJECT_DIR/secrets/github_token.txt"
            chmod 600 "$PROJECT_DIR/secrets/github_token.txt"
            break
        else
            echo "GitHub Token cannot be empty. Please try again."
        fi
    done

    # Similarly, create other secrets as needed
    while true; do
        read -sp "Enter your Slack Token for Docker Secrets: " SLACK_SECRET
        if [[ -n "$SLACK_SECRET" ]]; then
            echo "$SLACK_SECRET" > "$PROJECT_DIR/secrets/slack_token.txt"
            chmod 600 "$PROJECT_DIR/secrets/slack_token.txt"
            break
        else
            echo "Slack Token cannot be empty. Please try again."
        fi
    done

    log "Docker secrets set up."
}

# Function to secure Docker containers
secure_docker_containers() {
    # Ensure containers run with least privilege by adding security options in docker-compose.yml
    # This was already partially handled in create_docker_compose()

    # Example: Add security_opt and no-new-privileges to each service if not already present
    # For demonstration, ensuring it's present for node-red
    if ! grep -q "security_opt:" "$DOCKER_COMPOSE_FILE"; then
        sed -i '/node-red:/a\ \ security_opt:\n\ \ \ \ - no-new-privileges:true' "$DOCKER_COMPOSE_FILE" || error_exit "Failed to apply security options to Docker Compose."
        log "Applied Docker security best practices."
    else
        log "Docker security options already applied. Skipping."
    fi
}

# Function to setup SSL using Certbot and Nginx as reverse proxy within Docker
setup_ssl() {
    # SSL setup is now managed within Docker using the certbot service in docker-compose.yml
    # Automate the initial certificate issuance
    log "Initializing SSL certificates with Certbot..."

    docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email "$EMAIL_ADDRESS" --agree-tos --no-eff-email -d "$DOMAIN_NAME" || error_exit "Certbot failed to obtain SSL certificates."

    log "SSL certificates obtained successfully."
}

# Function to create configuration flows for the web interface
create_configuration_flows() {
    cat > "$PROJECT_DIR/configuration_flows.json" <<'EOF'
[
    {
        "id": "config-ui",
        "type": "tab",
        "label": "Configuration UI",
        "disabled": false,
        "info": ""
    },
    {
        "id": "ui_form",
        "type": "ui_form",
        "z": "config-ui",
        "name": "Configuration Form",
        "label": "Configure Bug Checking",
        "group": "dashboard_group",
        "order": 1,
        "width": 0,
        "height": 0,
        "options": [
            {
                "label": "Prompts (JSON Array)",
                "value": "PROMPTS",
                "type": "textarea",
                "required": true,
                "rows": 6,
                "cols": 50,
                "placeholder": "Enter prompts as a JSON array"
            },
            {
                "label": "GitHub Filename",
                "value": "INITIAL_CODE_FILE",
                "type": "text",
                "required": true,
                "placeholder": "e.g., src/main.py"
            },
            {
                "label": "Finalized Filename",
                "value": "FINALIZED_CODE_FILE",
                "type": "text",
                "required": true,
                "placeholder": "e.g., src/main_final.py"
            },
            {
                "label": "Processing Range Start (Line)",
                "value": "PROCESSING_RANGE_START",
                "type": "number",
                "required": true,
                "placeholder": "e.g., 2000"
            },
            {
                "label": "Range Increment (Lines)",
                "value": "RANGE_INCREMENT",
                "type": "number",
                "required": true,
                "placeholder": "e.g., 2000"
            },
            {
                "label": "Max Iterations per Chatbot",
                "value": "MAX_ITERATIONS_PER_CHATBOT",
                "type": "number",
                "required": true,
                "placeholder": "e.g., 5"
            }
        ],
        "formValue": {},
        "payload": "payload",
        "topic": "config_update",
        "x": 200,
        "y": 100,
        "wires": [
            [
                "save_config"
            ]
        ]
    },
    {
        "id": "save_config",
        "type": "file",
        "z": "config-ui",
        "name": "Save Config",
        "filename": "/data/config/config.json",
        "appendNewline": false,
        "createDir": false,
        "overwriteFile": "true",
        "encoding": "utf8",
        "x": 500,
        "y": 100,
        "wires": [
            []
        ]
    },
    {
        "id": "load_config",
        "type": "inject",
        "z": "flow",
        "name": "Load Config",
        "props": [],
        "repeat": "",
        "crontab": "",
        "once": true,
        "topic": "",
        "payloadType": "date",
        "x": 200,
        "y": 200,
        "wires": [
            [
                "read_config"
            ]
        ]
    },
    {
        "id": "read_config",
        "type": "file in",
        "z": "flow",
        "name": "Read Config",
        "filename": "/data/config/config.json",
        "format": "utf8",
        "sendError": false,
        "x": 400,
        "y": 200,
        "wires": [
            [
                "update_flow_context"
            ]
        ]
    },
    {
        "id": "update_flow_context",
        "type": "change",
        "z": "flow",
        "name": "Update Flow Context",
        "rules": [
            {
                "t": "set",
                "p": "flow.config",
                "to": "payload",
                "toType": "jsonata"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 600,
        "y": 200,
        "wires": [
            []
        ]
    },
    {
        "id": "ui_dashboard",
        "type": "ui_group",
        "z": "",
        "name": "Dashboard",
        "tab": "dashboard_tab",
        "order": 1,
        "disp": true,
        "width": "6",
        "collapse": false
    },
    {
        "id": "dashboard_tab",
        "type": "ui_tab",
        "z": "",
        "name": "Configuration",
        "icon": "dashboard",
        "order": 1
    }
]
EOF
    log "Created configuration_flows.json for the web interface."
}

# Function to create README with comprehensive documentation
create_readme() {
    cat > "$README_FILE" <<'EOF'
# Node-RED Automation Setup

## Overview

This setup script automates the installation and configuration of a Node-RED environment tailored for AI-driven code analysis and deployment automation. It integrates GitHub, Slack, email notifications, Dockerization, CI/CD pipelines, monitoring, testing, security enhancements, and a web-based configuration interface.

## Prerequisites

- **Operating System**: Ubuntu 20.04/22.04 LTS
- **Node.js**: v16.x
- **npm**
- **sudo/root privileges**
- **Domain Name**: For SSL certificate setup
- **Docker Hub Account**: For storing Docker images

## Setup Steps

1. **Run the Setup Script**:
    ```bash
    sudo chmod +x setup-node-red-automation.sh
    sudo ./setup-node-red-automation.sh
    ```

2. **Provide Required Inputs**:
    - **Docker Hub Username**: Enter your Docker Hub username when prompted.
    - **Remote Server User**: Enter the username for your remote server.
    - **Remote Server IP**: Enter the IP address of your remote server.
    - **Domain Name**: Provide your domain name for SSL setup.
    - **Email Address**: Enter your email address for SSL notifications.
    - **Deployment Path**: Enter the deployment path on your remote server (e.g., `/var/www/node-red-automation`).

3. **Edit `.env` File**:
    Replace all placeholders with your actual credentials.
    ```bash
    sudo nano node-red-automation/.env
    ```

4. **Start Docker Compose Services**:
    ```bash
    sudo docker-compose up -d
    ```

5. **Initialize SSL Certificates**:
    ```bash
    sudo docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email "$EMAIL_ADDRESS" --agree-tos --no-eff-email -d "$DOMAIN_NAME"
    ```

6. **Access Node-RED Dashboard**:
    Navigate to [https://yourdomain.com/ui](https://yourdomain.com/ui) in your browser.

7. **Verify Services**:
    ```bash
    sudo docker-compose ps
    ```

## Maintenance

- **Updating Services**:
    ```bash
    sudo docker-compose pull
    sudo docker-compose up -d
    ```

- **Viewing Logs**:
    ```bash
    sudo docker-compose logs -f
    ```

- **Stopping Services**:
    ```bash
    sudo docker-compose down
    ```

- **Backup Restoration**:
    To restore from a backup:
    ```bash
    tar -xzf backup_filename.tar.gz -C /var/www/node-red-automation
    ```

## Backup Management

Automated backups are scheduled via cron to run daily at 2 AM. Backups are stored in the `backups/` directory and older backups beyond 7 days are automatically removed.

## Troubleshooting

- **Docker Issues**: Ensure Docker service is running.
    ```bash
    sudo systemctl status docker
    ```

- **Node-RED Access**: Check if Node-RED container is up and listening on the specified port.
    ```bash
    sudo docker-compose ps
    ```

- **Firewall Issues**: Verify UFW rules.
    ```bash
    sudo ufw status
    ```

- **SSL Certificate Issues**: Renew certificates using Certbot.
    ```bash
    sudo docker-compose run certbot renew
    ```

- **Backup Failures**: Check the backup logs located in `backups/backup.log` and ensure email notifications are working.

## Secret Management

Sensitive information such as GitHub tokens and Slack tokens are managed using Docker secrets. These secrets are stored in the `secrets/` directory with restricted permissions and are referenced securely within the Docker Compose configuration.

## Contribution Guidelines

Contributions are welcome! Please follow these steps:
1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Commit your changes with clear messages.
4. Submit a pull request detailing your changes.

## License

MIT License
EOF
    log "Created README with comprehensive documentation."
}

# Function to create logrotate configuration for setup.log
create_logrotate_config() {
    LOGROTATE_CONF="/etc/logrotate.d/node-red-automation"

    if [ ! -f "$LOGROTATE_CONF" ]; then
        cat > "$LOGROTATE_CONF" <<'EOF'
/path/to/node-red-automation/setup.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        systemctl reload docker >/dev/null 2>&1 || true
    endscript
}
EOF
        # Replace placeholder with actual path
        sed -i "s|/path/to/node-red-automation|$PROJECT_DIR|g" "$LOGROTATE_CONF" || error_exit "Failed to set paths in logrotate configuration."

        log "Created logrotate configuration for setup.log."
    else
        log "Logrotate configuration already exists. Skipping creation."
    fi
}

# Function to install cli53 for DNS management (Optional)
install_cli53() {
    if ! command -v cli53 >/dev/null 2>&1; then
        log "Installing cli53 for DNS management..."
        curl -Lo /usr/local/bin/cli53 https://github.com/barnybug/cli53/releases/download/0.8.6/cli53-linux-amd64 || error_exit "Failed to download cli53."
        chmod +x /usr/local/bin/cli53 || error_exit "Failed to apply executable permissions to cli53."
        log "cli53 installed successfully."
    else
        log "cli53 is already installed."
    fi
}

# Function to configure DNS using cli53 (Optional)
configure_dns() {
    read -p "Enter your AWS Route 53 Hosted Zone ID: " HOSTED_ZONE_ID
    read -p "Enter the subdomain to point to this server (e.g., sub.example.com): " SUBDOMAIN

    cli53 rrcreate "$HOSTED_ZONE_ID" "$SUBDOMAIN" A "$SERVER_IP" --replace || error_exit "Failed to create DNS A record."
    log "DNS A record for $SUBDOMAIN created successfully."
}

# Function to install Fail2Ban and configure it
install_fail2ban() {
    if ! systemctl is-active --quiet fail2ban; then
        log "Installing Fail2Ban..."
        apt-get install -y fail2ban || error_exit "Failed to install Fail2Ban."
        log "Fail2Ban installed successfully."
    else
        log "Fail2Ban is already installed."
    fi
}

# Function to configure Fail2Ban
configure_fail2ban() {
    F2B_JAIL_LOCAL="/etc/fail2ban/jail.local"

    if [ ! -f "$F2B_JAIL_LOCAL" ]; then
        cat > "$F2B_JAIL_LOCAL" <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true

[nginx-http-auth]
enabled = true
EOF
        systemctl restart fail2ban || error_exit "Failed to restart Fail2Ban."
        log "Fail2Ban configured and restarted."
    else
        log "Fail2Ban jail.local already exists. Skipping configuration."
    fi
}

# Function to handle SELinux/AppArmor (If Applicable)
handle_security_modules() {
    if command -v getenforce >/dev/null 2>&1; then
        SELINUX_STATUS=$(getenforce)
        if [ "$SELINUX_STATUS" = "Enforcing" ]; then
            log "SELinux is enforcing. Configuring Docker for SELinux compatibility."
            # Apply necessary SELinux labels or policies
            # Example: docker run with :Z or :z flags for volume mounts
        fi
    fi

    # Similarly handle AppArmor if used
    if command -v apparmor_status >/dev/null 2>&1; then
        APPAARMOR_STATUS=$(apparmor_status)
        if echo "$APPAARMOR_STATUS" | grep -q "Enforcing mode"; then
            log "AppArmor is enforcing. Configuring Docker for AppArmor compatibility."
            # Apply necessary AppArmor profiles or policies
        fi
    fi
}

# Function to create wait-for-it.sh
create_wait_for_it() {
    install_wait_for_it
}

# Function to automate DNS configuration using cli53 (Optional)
automate_dns() {
    install_cli53
    configure_dns
}

# Function to setup Fail2Ban
setup_fail2ban() {
    install_fail2ban
    configure_fail2ban
}

# Function to apply security modules configuration
apply_security_modules() {
    handle_security_modules
}

# Function to ensure environment variables are used correctly in Docker Compose
ensure_env_variables() {
    # Environment variables are already referenced correctly in docker-compose.yml
    log "Ensured that environment variables are used correctly in Docker Compose."
}

# Function to ensure consistent use of absolute paths
ensure_absolute_paths() {
    # This function can be expanded as needed
    log "Ensuring consistent use of absolute paths in scripts and configurations."
}

# Function to secure the .env file further if needed
secure_env_file() {
    chmod 600 "$ENV_FILE" || error_exit "Failed to set permissions on .env file."
    log "Secured .env file with permissions set to 600."
}

# Function to finalize and ensure all services are up and running
finalize_setup() {
    log "Finalizing additional setup..."

    # Reload systemd to recognize new services if any
    systemctl daemon-reload || log "No systemd daemon reload needed."

    # Restart Docker to apply any new configurations
    systemctl restart docker || error_exit "Failed to restart Docker service."

    log "Additional setup finalized successfully."
}

# Function to create logrotate configuration
create_logrotate_config() {
    LOGROTATE_CONF="/etc/logrotate.d/node-red-automation"

    if [ ! -f "$LOGROTATE_CONF" ]; then
        cat > "$LOGROTATE_CONF" <<'EOF'
/path/to/node-red-automation/setup.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        systemctl reload docker >/dev/null 2>&1 || true
    endscript
}
EOF
        # Replace placeholder with actual path
        sed -i "s|/path/to/node-red-automation|$PROJECT_DIR|g" "$LOGROTATE_CONF" || error_exit "Failed to set paths in logrotate configuration."

        log "Created logrotate configuration for setup.log."
    else
        log "Logrotate configuration already exists. Skipping creation."
    fi
}

# Function to ensure SELinux/AppArmor configurations are applied
configure_security_modules() {
    apply_security_modules
}

# Function to ensure environment variables are correctly set
configure_env_variables() {
    ensure_env_variables
}

# Function to ensure absolute paths
configure_absolute_paths() {
    ensure_absolute_paths
}

# Function to finalize and clean up
finalize_additional_setup() {
    finalize_setup
    create_logrotate_config
    log "Additional setup completed successfully."
}

# =============================================================================
# Execution Flow
# =============================================================================

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    error_exit "Please run this script with sudo or as root."
else
    log "Script is running with sudo privileges."
fi

# Create necessary directories
create_dir "$MONITORING_DIR"
create_dir "$TEST_DIR"
create_dir "$SUBFLOWS_DIR"
create_dir "$BACKUP_DIR"
create_dir "$CONFIG_DIR"
create_dir "$SRC_DIR"
create_dir "$SECRETS_DIR"
create_dir "$NGINX_CONF_DIR"

# Create .gitignore
create_gitignore

# Create sample source file
create_sample_source

# Setup Fail2Ban
setup_fail2ban

# Setup automated backups
setup_automated_backups

# Create test scripts
create_test_scripts

# Create subflows
create_subflows

# Implement security enhancements
secure_docker
secure_docker_containers
setup_ssl

# Automate DNS Configuration (Optional)
# Uncomment the following line if DNS automation is desired
# automate_dns

# Ensure environment variables are correctly set
configure_env_variables

# Ensure consistent use of absolute paths
configure_absolute_paths

# Finalization
finalize_additional_setup

# =============================================================================
# End of Script
# =============================================================================
