#!/bin/bash

# =============================================================================
# Script Name: setup-webui.sh
# Description: Configures the Web UI for Node-RED Automation, including
#              Node-RED Dashboard setup, Nginx reverse proxy with SSL,
#              security enhancements, custom styling, and configuration flows.
# Author: Your Name
# License: MIT
# =============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# =============================================================================
# Variables
# =============================================================================

PROJECT_DIR="$(pwd)/node-red-automation"
LOG_FILE="$PROJECT_DIR/setup-webui.log"
SETTINGS_FILE="$PROJECT_DIR/config/settings.js"
NGINX_CONF_DIR="$PROJECT_DIR/nginx/conf.d"
NGINX_CONF_FILE="$NGINX_CONF_DIR/default.conf"
CUSTOM_CSS_FILE="$PROJECT_DIR/config/custom.css"
CONFIG_FLOWS_FILE="$PROJECT_DIR/configuration_flows.json"
WEBUI_FLOW_FILE="$PROJECT_DIR/flows-webui.json"
DASHBOARD_TAB_NAME="Configuration"

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

# Function to check if a command exists
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error_exit "Command '$1' not found. Please install it and rerun the script."
    else
        log "Command '$1' is available."
    fi
}

# Function to ensure the script is run with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "Please run this script with sudo or as root."
    else
        log "Script is running with sudo privileges."
    fi
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

# Function to configure Node-RED Dashboard with authentication
configure_node_red_dashboard() {
    log "Configuring Node-RED Dashboard..."

    # Ensure node-red-dashboard is installed
    cd "$PROJECT_DIR"
    if ! npm list node-red-dashboard >/dev/null 2>&1; then
        log "node-red-dashboard not found. Installing..."
        npm install node-red-dashboard || error_exit "Failed to install node-red-dashboard."
        log "node-red-dashboard installed successfully."
    else
        log "node-red-dashboard is already installed."
    fi

    # Generate bcrypt hash for admin password if not already set
    if ! grep -q "password:" "$SETTINGS_FILE"; then
        read -sp "Enter admin password for Node-RED Dashboard: " ADMIN_PASSWORD
        echo
        ADMIN_HASH=$(node -e "const bcrypt = require('bcrypt'); bcrypt.hash('$ADMIN_PASSWORD', 10, function(err, hash) { if (err) { console.error(err); process.exit(1); } else { console.log(hash); } });")
        sed -i "s/\"password\": \"PLACEHOLDER_HASH\"/\"password\": \"$ADMIN_HASH\"/" "$SETTINGS_FILE" || error_exit "Failed to insert bcrypt hash into settings.js."
        log "Admin password hash updated in settings.js."
    else
        log "Admin password is already set in settings.js."
    fi
}

# Function to configure Nginx as a reverse proxy with SSL and security headers
configure_nginx() {
    log "Configuring Nginx as a reverse proxy for Node-RED Dashboard..."

    # Create Nginx configuration if it doesn't exist
    if [ ! -f "$NGINX_CONF_FILE" ]; then
        cat > "$NGINX_CONF_FILE" <<EOF
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    # Redirect HTTP to HTTPS
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';" always;

    # Rate Limiting
    limit_req_zone \$binary_remote_addr zone=mylimit:10m rate=10r/s;

    location /ui/ {
        proxy_pass http://localhost:1880/ui/;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 90;

        # Apply rate limiting
        limit_req zone=mylimit burst=20 nodelay;

        # WebSocket Support
        proxy_http_version 1.1;
    }

    location /admin/ {
        proxy_pass http://localhost:1880/admin/;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 90;

        # Apply rate limiting
        limit_req zone=mylimit burst=20 nodelay;

        # WebSocket Support
        proxy_http_version 1.1;
    }

    # Static Assets Caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
}
EOF
        log "Created Nginx configuration at $NGINX_CONF_FILE."
    else
        log "Nginx configuration already exists at $NGINX_CONF_FILE. Skipping creation."
    fi

    # Reload Nginx to apply changes
    systemctl reload nginx || error_exit "Failed to reload Nginx."
    log "Nginx reloaded successfully."
}

# Function to apply custom styling to Node-RED Dashboard
apply_custom_styling() {
    log "Applying custom styling to Node-RED Dashboard..."

    if [ ! -f "$CUSTOM_CSS_FILE" ]; then
        create_dir "$CONFIG_DIR"
        cat > "$CUSTOM_CSS_FILE" <<'EOF'
/* custom.css */

/* Change background color */
.dashboard-page {
    background-color: #f0f0f0;
}

/* Customize widget titles */
.dashboard-widget-header {
    font-family: 'Arial, sans-serif';
    color: #333333;
}

/* Add padding to widgets */
.dashboard-widget {
    padding: 10px;
}
EOF
        log "Created custom CSS at $CUSTOM_CSS_FILE."
    else
        log "Custom CSS already exists at $CUSTOM_CSS_FILE. Skipping creation."
    fi

    # Reference custom.css in settings.js
    if ! grep -q "custom.css" "$SETTINGS_FILE"; then
        sed -i '/css:/a\        css: "/data/custom.css",' "$SETTINGS_FILE" || error_exit "Failed to reference custom.css in settings.js."
        log "Referenced custom.css in settings.js."
    else
        log "custom.css is already referenced in settings.js."
    fi

    # Reload Node-RED to apply changes
    docker-compose restart node-red || error_exit "Failed to restart Node-RED container."
    log "Node-RED restarted to apply custom styling."
}

# Function to deploy configuration flows for Web UI
deploy_configuration_flows() {
    log "Deploying configuration flows for Web UI..."

    if [ ! -f "$CONFIG_FLOWS_FILE" ]; then
        cat > "$CONFIG_FLOWS_FILE" <<'EOF'
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
        log "Created configuration_flows.json for the Web UI."
    else
        log "configuration_flows.json already exists. Skipping creation."
    fi

    # Import the configuration flows into Node-RED
    docker cp "$CONFIG_FLOWS_FILE" node-red-automation_node-red_1:/data/configuration_flows.json || error_exit "Failed to copy configuration_flows.json to Node-RED container."

    # Restart Node-RED to apply the new flows
    docker-compose restart node-red || error_exit "Failed to restart Node-RED container."
    log "Configuration flows deployed and Node-RED restarted."
}

# Function to set up log rotation for Web UI logs
setup_logrotate() {
    log "Setting up log rotation for Web UI logs..."

    LOGROTATE_CONF="/etc/logrotate.d/node-red-webui"

    if [ ! -f "$LOGROTATE_CONF" ]; then
        cat > "$LOGROTATE_CONF" <<'EOF'
/path/to/node-red-automation/setup-webui.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        systemctl reload nginx >/dev/null 2>&1 || true
    endscript
}
EOF
        # Replace placeholder with actual path
        sed -i "s|/path/to/node-red-automation|$PROJECT_DIR|g" "$LOGROTATE_CONF" || error_exit "Failed to set paths in logrotate configuration."

        log "Created logrotate configuration at $LOGROTATE_CONF."
    else
        log "Logrotate configuration already exists at $LOGROTATE_CONF. Skipping creation."
    fi
}

# Function to finalize and ensure all services are up and running
finalize_webui_setup() {
    log "Finalizing Web UI setup..."

    # Reload systemd to recognize any new services if applicable
    systemctl daemon-reload || log "No systemd daemon reload needed."

    # Restart Docker to apply any new configurations
    systemctl restart docker || error_exit "Failed to restart Docker service."

    log "Web UI setup finalized successfully."
}

# Function to print completion message
print_completion() {
    echo "===================================================="
    echo "Web UI setup completed successfully."
    echo "Access the Node-RED Dashboard at https://yourdomain.com/ui"
    echo "===================================================="
}

# =============================================================================
# Execution Flow
# =============================================================================

# Initial checks
check_sudo
check_command docker
check_command docker-compose
check_command nginx
check_command curl

# Create necessary directories
create_dir "$NGINX_CONF_DIR"
create_dir "$PROJECT_DIR/config"

# Configure Node-RED Dashboard
configure_node_red_dashboard

# Configure Nginx as reverse proxy with SSL and security headers
configure_nginx

# Apply custom styling to the dashboard
apply_custom_styling

# Deploy configuration flows for Web UI
deploy_configuration_flows

# Set up log rotation for Web UI logs
setup_logrotate

# Finalize setup
finalize_webui_setup

# Final completion message
print_completion

# =============================================================================
# End of Script
# =============================================================================
