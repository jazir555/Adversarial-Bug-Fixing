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
# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
declare -r PROJECT_DIR="${NODE_RED_DIR:-$(pwd)/node-red-automation}"
declare -r LOG_FILE="$PROJECT_DIR/setup-webui.log"
declare -r TIMESTAMP=$(date +%Y%m%d-%H%M%S)
declare -r BACKUP_DIR="$PROJECT_DIR/backups/$TIMESTAMP"

# Dependency checks
declare -a REQUIRED_CMDS=("docker" "docker-compose" "jq" "bcrypt")
declare -a REQUIRED_FILES=("docker-compose.yml" "config/settings.js")

# Security Settings
declare -r DEFAULT_ADMIN_USER="admin"
declare -A SECURE_DEFAULTS=(
    [SESSION_TIMEOUT]="3600"
    [API_RATE_LIMIT]="100/1h"
    [PASSWORD_COMPLEXITY]="12"
)

# -----------------------------------------------------------------------------
# Logging & Error Handling
# -----------------------------------------------------------------------------
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    exec 3>&1 4>&2
    exec > >(tee -a "$LOG_FILE") 2>&1
}

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} - [${level^^}] ${message}" | tee -a "$LOG_FILE"
}

error_exit() {
    log "error" "$1"
    exit 1
}

# -----------------------------------------------------------------------------
# Validation Functions
# -----------------------------------------------------------------------------
validate_environment() {
    # Check required commands
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            error_exit "Missing required command: $cmd"
        fi
    done
    
    # Check project files
    for file in "${REQUIRED_FILES[@]}"; do
        [[ -f "$PROJECT_DIR/$file" ]] || error_exit "Missing required file: $file"
    done

    # Validate Docker daemon
    docker info &>/dev/null || error_exit "Docker daemon unavailable"
}

# -----------------------------------------------------------------------------
# Security Functions
# -----------------------------------------------------------------------------
generate_password_hash() {
    local password=$1
    local salt=$(openssl rand -base64 16)
    docker run --rm node:alpine node -e "console.log(require('bcryptjs').hashSync(process.argv[1], 8));" "$password" | tr -d '\r\n'
}

configure_auth() {
    log "info" "Configuring Enterprise Authentication System"
    
    # Generate random password if not set
    if [[ -z "$ADMIN_PASSWORD" ]]; then
        ADMIN_PASSWORD=$(openssl rand -base64 "${SECURE_DEFAULTS[PASSWORD_COMPLEXITY]}")
        log "warning" "Generated admin password: $ADMIN_PASSWORD (store securely!)"
    fi

    local hash=$(generate_password_hash "$ADMIN_PASSWORD")
    
    # Update settings.js with auth configuration
    jq --arg user "$DEFAULT_ADMIN_USER" --arg hash "$hash" \
        '.adminAuth.users = [{
            username: $user,
            password: $hash,
            permissions: "*"
        }]' "$PROJECT_DIR/config/settings.js" > "$PROJECT_DIR/config/settings.tmp" \
        && mv "$PROJECT_DIR/config/settings.tmp" "$PROJECT_DIR/config/settings.js"
}
# -----------------------------------------------------------------------------
# Backup & Recovery
# -----------------------------------------------------------------------------
create_backup() {
    local files=("$SETTINGS_FILE" "$CUSTOM_CSS_FILE")
    mkdir -p "$BACKUP_DIR"
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
        fi
    done
    log "info" "Created configuration backup in $BACKUP_DIR"
}
# -----------------------------------------------------------------------------
# UI Configuration
# -----------------------------------------------------------------------------
deploy_ui_components() {
    log "info" "Deploying AI Chatbot Interface Components"
    
    # Dashboard template configuration
    local dashboard_config=$(cat <<EOF
{
    "theme": "material",
    "site": {
        "name": "AI Chatbot Controller",
        "favicon": "assets/chatbot-icon.png"
    },
    "auth": {
        "type": "strategy",
        "strategy": {
            "name": "azuread",
            "options": {
                "clientID": "$AZURE_CLIENT_ID",
                "tenantID": "$AZURE_TENANT_ID",
                "redirectUrl": "$CALLBACK_URL"
            }
        }
    }
}
EOF
    )
    echo "$dashboard_config" > "$PROJECT_DIR/config/ui-config.json"

    # Apply cluster-safe storage
    docker exec node-red-automation_node-red_1 mkdir -p /data/context
    docker cp "$PROJECT_DIR/config/ui-config.json" node-red-automation_node-red_1:/data/context/
}

# -----------------------------------------------------------------------------
# Main Execution Flow
# -----------------------------------------------------------------------------
main() {
    init_logging
    log "info" "Starting Enterprise WebUI Deployment"
    
    validate_environment
    create_backup
    configure_auth
    deploy_ui_components
    
    if [[ "$HA_ENABLED" == "true" ]]; then
        configure_ha
    fi

    log "info" "Restarting Node-RED Cluster"
    docker-compose -f "$PROJECT_DIR/docker-compose.yml" up -d --scale node-red=3
    
    log "info" "Performing Post-Deployment Validation"
    curl -sSf http://localhost:1880/health &>/dev/null || error_exit "Deployment validation failed"
    
    log "success" "Enterprise WebUI Deployment Completed"
    log "warning" "Admin Password: ${ADMIN_PASSWORD:-[not-generated]}"
}
# -----------------------------------------------------------------------------
# Runtime Execution
# -----------------------------------------------------------------------------
if [[ "$EUID" -ne 0 ]]; then
    error_exit "This script requires root privileges. Run with sudo."
fi

main "$@"
