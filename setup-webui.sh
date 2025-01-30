#!/bin/bash

# =============================================================================
# Script Name: setup-webui.sh
# Description: Configures the Web UI for Node-RED Automation, including
#              Node-RED Dashboard setup, chatbot API integration,
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
CUSTOM_CSS_FILE="$PROJECT_DIR/config/custom.css"
WEBUI_FLOW_FILE="$PROJECT_DIR/flows-webui.json"
DASHBOARD_TAB_NAME="Chatbot Configuration"
API_SUBFLOW_FILE="$PROJECT_DIR/subflows/api-handler.json"

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

# Function to configure chatbot API subflow
configure_chatbot_subflow() {
    log "Configuring Chatbot API Subflow..."
    
    cat > "$API_SUBFLOW_FILE" <<'EOF'
{
    "id": "chatbot-api-handler",
    "type": "subflow",
    "name": "Chatbot API Handler",
    "info": "Handles API communication with AI chatbots",
    "category": "API",
    "in": [
        {
            "x": 100,
            "y": 100,
            "wires": [{"id": "input-processor"}]
        }
    ],
    "out": [
        {
            "x": 600,
            "y": 100,
            "wires": [{"id": "output-processor"}]
        }
    ],
    "env": [
        {
            "name": "API_TIMEOUT",
            "type": "num",
            "value": "30000"
        }
    ],
    "nodes": [
        {
            "id": "input-processor",
            "type": "function",
            "z": "chatbot-api-handler",
            "name": "Process Input",
            "func": "msg.headers = {\n    'Content-Type': 'application/json',\n    'Authorization': `Bearer ${msg.api_key}`\n};\nmsg.payload = {\n    model: 'gpt-4',\n    messages: [\n        { role: 'system', content: 'You are a senior code reviewer' },\n        { role: 'user', content: msg.prompt }\n    ]\n};\nreturn msg;"
        },
        {
            "id": "api-call",
            "type": "http request",
            "z": "chatbot-api-handler",
            "name": "Chatbot API",
            "method": "POST",
            "ret": "obj",
            "url": "{{api_url}}"
        },
        {
            "id": "output-processor",
            "type": "function",
            "z": "chatbot-api-handler",
            "name": "Process Output",
            "func": "if (msg.payload.choices && msg.payload.choices.length > 0) {\n    msg.response = msg.payload.choices[0].message.content;\n} else {\n    msg.error = 'Invalid API response';\n}\nreturn msg;"
        }
    ]
}
EOF
    log "Created Chatbot API Subflow configuration"
}

# Function to configure Web UI flows
configure_webui_flows() {
    log "Configuring Web UI Flows..."
    
    cat > "$WEBUI_FLOW_FILE" <<'EOF'
[
    {
        "id": "chatbot-config-ui",
        "type": "tab",
        "label": "Chatbot Configuration",
        "disabled": false,
        "info": ""
    },
    {
        "id": "chatbot-config-form",
        "type": "ui_form",
        "z": "chatbot-config-ui",
        "name": "Chatbot Settings",
        "label": "Chatbot Configuration",
        "group": "chatbot-config-group",
        "order": 1,
        "options": [
            {
                "label": "API Endpoints",
                "value": "API_ENDPOINTS",
                "type": "json",
                "required": true,
                "rows": 6,
                "placeholder": "Enter chatbot endpoints as JSON array"
            },
            {
                "label": "Max Iterations",
                "value": "MAX_ITERATIONS",
                "type": "number",
                "required": true
            },
            {
                "label": "Validation Prompts",
                "value": "VALIDATION_PROMPTS",
                "type": "json",
                "rows": 8,
                "placeholder": "Enter validation prompts as JSON array"
            }
        ],
        "formValue": {},
        "payload": "payload",
        "topic": "config_update",
        "wires": [["save-chatbot-config"]]
    },
    {
        "id": "save-chatbot-config",
        "type": "file",
        "z": "chatbot-config-ui",
        "name": "Save Config",
        "filename": "/data/config/chatbot-config.json",
        "overwriteFile": "true",
        "wires": [[]]
    },
    {
        "id": "chatbot-api-monitor",
        "type": "ui_chart",
        "z": "chatbot-config-ui",
        "name": "API Performance",
        "group": "chatbot-config-group",
        "order": 2,
        "width": 0,
        "height": 0,
        "label": "API Response Times",
        "chartType": "line",
        "legend": "true",
        "xformat": "HH:mm:ss",
        "interpolate": "linear",
        "wires": [[]]
    }
]
EOF
    log "Created Web UI flow configuration"
}

# Function to deploy UI configurations
deploy_ui_configurations() {
    log "Deploying UI configurations..."
    
    # Copy configuration files to Docker container
    docker cp "$WEBUI_FLOW_FILE" node-red-automation_node-red_1:/data/flows_webui.json
    docker cp "$API_SUBFLOW_FILE" node-red-automation_node-red_1:/data/subflows/
    
    # Restart Node-RED to load new configurations
    docker-compose -f "$PROJECT_DIR/docker-compose.yml" restart node-red
    log "UI configurations deployed successfully"
}

# Function to configure dashboard security
configure_dashboard_security() {
    log "Configuring Dashboard Security..."
    
    # Update settings.js with authentication
    if ! grep -q "ui: { path: '/ui'" "$SETTINGS_FILE"; then
        cat >> "$SETTINGS_FILE" <<'EOF'
ui: {
    path: '/ui',
    middleware: function(req, res, next) {
        if (req.path.indexOf('/ui') === 0 && !req.session.auth) {
            res.redirect('/login');
        } else {
            next();
        }
    }
},
adminAuth: {
    type: "credentials",
    users: [{
        username: "admin",
        password: "$2b$10$YOUR_BCRYPT_HASH",
        permissions: "*"
    }]
}
EOF
    fi
    log "Dashboard security configuration updated"
}

# Function to apply custom styling
apply_custom_styling() {
    log "Applying Custom Styling..."
    
    cat > "$CUSTOM_CSS_FILE" <<'EOF'
/* Chatbot UI Styling */
.chatbot-config-panel {
    background: #f8f9fa;
    border-radius: 8px;
    padding: 20px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.api-status-indicator {
    color: #28a745;
    font-weight: bold;
}

.config-form-header {
    font-size: 1.5em;
    color: #2c3e50;
    margin-bottom: 1em;
}
EOF
    log "Custom CSS styles applied"
}

# Function to setup log rotation
setup_log_rotation() {
    log "Setting Up Log Rotation..."
    
    cat > /etc/logrotate.d/node-red-webui <<EOF
$PROJECT_DIR/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 root root
}
EOF
    log "Log rotation configured"
}

# =============================================================================
# Main Execution
# =============================================================================

# Initial checks
check_sudo
check_command docker
check_command docker-compose

# Create necessary directories
create_dir "$PROJECT_DIR/config"

# Configure components
configure_chatbot_subflow
configure_webui_flows
configure_dashboard_security
apply_custom_styling
deploy_ui_configurations
setup_log_rotation

log "Web UI Setup Completed Successfully"
echo "===================================================="
echo "Chatbot Configuration UI is now available at:"
echo "http://your-server-ip:1880/ui"
echo "===================================================="
