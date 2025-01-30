#!/bin/bash

# =============================================================================
# Script Name: setup-node-red-automation.sh
# Description: Automates the initial environment setup for Node-RED Automation.
#              Installs dependencies, Docker, Docker Compose, configures
#              security measures, sets up configurations, and prepares the environment.
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
ENV_FILE="$PROJECT_DIR/.env"
README_FILE="$PROJECT_DIR/README.md"
GITIGNORE_FILE="$PROJECT_DIR/.gitignore"
PACKAGE_JSON_FILE="$PROJECT_DIR/package.json"
FLOW_FILE="$PROJECT_DIR/flows.json"
CONFIG_DIR="$PROJECT_DIR/config"
SRC_DIR="$PROJECT_DIR/src"
DOCKERFILE="$PROJECT_DIR/Dockerfile"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
CI_CD_YML="$PROJECT_DIR/.github/workflows/ci-cd.yml"
TEST_DIR="$PROJECT_DIR/tests"
SUBFLOWS_DIR="$PROJECT_DIR/subflows"
BACKUP_DIR="$PROJECT_DIR/backups"
MONITORING_DIR="$PROJECT_DIR/monitoring"
GRAFANA_PROVISION_DIR="$MONITORING_DIR/grafana/provisioning"
PROMETHEUS_PROVISION_DIR="$MONITORING_DIR/prometheus/provisioning"
SETTINGS_FILE="$CONFIG_DIR/settings.js"
TMP_DIR="$PROJECT_DIR/tmp"  # Temporary directory for cleanup
CONFIG_JSON="$CONFIG_DIR/config.json"
NGINX_CONF_DIR="$PROJECT_DIR/nginx/conf.d"
NGINX_CONF_FILE="$NGINX_CONF_DIR/default.conf"
SSL_DIR="$PROJECT_DIR/config/ssl"
CERTBOT_CONF_DIR="$PROJECT_DIR/certbot/conf"
CERTBOT_WWW_DIR="$PROJECT_DIR/certbot/www"

# Variables for dynamic inputs
DOCKERHUB_USERNAME=""
REMOTE_USER=""
SERVER_IP=""
DOMAIN_NAME=""
EMAIL_ADDRESS=""
DOCKER_PATH="/var/www/node-red-automation"  # Updated to a more typical deployment path
ALERT_EMAIL="alerts@company.com"            # Default value; can be updated via .env

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
        error_exit "$1 is not installed. Please install it and rerun the script."
    else
        log "Command '$1' is already installed."
    fi
}

# Function to check if the script is run with sudo
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

# Function to prompt for dynamic inputs with validation
prompt_inputs() {
    # Docker Hub Username
    while true; do
        read -p "Enter your Docker Hub Username: " DOCKERHUB_USERNAME
        if [[ -n "$DOCKERHUB_USERNAME" ]]; then
            break
        else
            echo "Docker Hub Username cannot be empty. Please try again."
        fi
    done

    # Remote Server User
    while true; do
        read -p "Enter your Remote Server User: " REMOTE_USER
        if [[ -n "$REMOTE_USER" ]]; then
            break
        else
            echo "Remote Server User cannot be empty. Please try again."
        fi
    done

    # Remote Server IP
    while true; do
        read -p "Enter your Remote Server IP: " SERVER_IP
        if [[ "$SERVER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            break
        else
            echo "Invalid IP address format. Please enter a valid IP."
        fi
    done

    # Domain Name
    while true; do
        read -p "Enter your Domain Name for SSL (e.g., example.com): " DOMAIN_NAME
        if [[ "$DOMAIN_NAME" =~ ^(([a-zA-Z]{1})|([a-zA-Z]{1}[a-zA-Z]{1})|([a-zA-Z]{1}[0-9]{1})|([0-9]{1}[a-zA-Z]{1}))+([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.[a-zA-Z]{2,6}$ ]]; then
            break
        else
            echo "Invalid domain name format. Please try again."
        fi
    done

    # Email Address
    while true; do
        read -p "Enter your Email Address for SSL notifications: " EMAIL_ADDRESS
        if [[ "$EMAIL_ADDRESS" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            echo "Invalid email address format. Please try again."
        fi
    done

    # Deployment Path
    while true; do
        read -p "Enter your Deployment Path on Remote Server (e.g., /var/www/node-red-automation): " DOCKER_PATH
        if [[ "$DOCKER_PATH" =~ ^/.* ]]; then
            break
        else
            echo "Deployment Path must be an absolute path starting with '/'. Please try again."
        fi
    done
}

# Function to check for Node.js and npm before proceeding
check_node_npm() {
    check_command node
    check_command npm
}

# Function to check Node.js version is 16.x
check_node_version() {
    node_version=$(node --version)
    if ! echo "$node_version" | grep -q '^v16\.'; then
        error_exit "Node.js 16.x required. Current version: $node_version"
    else
        log "Node.js version $node_version is sufficient."
    fi
}

# Function to create custom package.json with all required dependencies and version pinning
create_custom_package_json() {
    if [ ! -f "$PACKAGE_JSON_FILE" ]; then
        log "Creating custom package.json..."
        cat > "$PACKAGE_JSON_FILE" <<'EOF'
{
  "name": "node-red-automation",
  "version": "1.0.0",
  "description": "AI-Driven Code Analysis and Deployment Automation",
  "scripts": {
    "start": "node-red flows.json",
    "test": "jest"
  },
  "dependencies": {
    "node-red": "3.0.2",
    "dotenv": "^16.0.0",
    "node-red-node-email": "^1.0.0",
    "node-red-node-slack": "^1.0.0",
    "node-red-contrib-github": "^1.0.0",
    "node-red-dashboard": "^3.0.0",
    "language-detect": "^2.0.0",
    "diff": "^5.0.0",
    "nodemailer": "^6.7.0",
    "jest": "^29.0.0",
    "mocha": "^10.0.0",
    "bcrypt": "^5.0.0",
    "axios": "^1.3.0",
    "fs-extra": "^11.1.0"
  }
}
EOF
        log "Created custom package.json with predefined dependencies and pinned Node-RED version."
    else
        log "Custom package.json already exists."
    fi
}

# Function to initialize npm and install dependencies
init_npm() {
    log "Installing npm dependencies from package.json..."
    cd "$PROJECT_DIR"
    npm install || error_exit "npm install failed."
    log "npm dependencies installed successfully."
}

# Function to create config.json with default configuration values
create_config_json() {
    if [ ! -f "$CONFIG_JSON" ]; then
        log "Creating config.json with default configuration values..."
        create_dir "$CONFIG_DIR"
        cat > "$CONFIG_JSON" <<'EOF'
{
    "PROCESSING_RANGE_START": 2000,
    "RANGE_INCREMENT": 2000,
    "MAX_ITERATIONS_PER_CHATBOT": 5,
    "INITIAL_CODE_FILE": "src/main.py",
    "FINALIZED_CODE_FILE": "src/main_final.py",
    "PROMPTS": [
        "Please review the following code snippet.",
        "Suggest optimizations for the given code."
    ]
}
EOF
        log "Created config.json with default configuration values."
    else
        log "config.json already exists. Skipping creation."
    fi
}

# Function to install Docker if not installed, optimized for Ubuntu
install_docker() {
    # OS Check for Ubuntu
    if ! grep -q 'Ubuntu' /etc/os-release; then
        log "Warning: Docker installation is optimized for Ubuntu. Proceeding anyway."
    fi

    if ! command -v docker >/dev/null 2>&1; then
        log "Docker not found. Installing Docker..."

        # Update the apt package index
        apt-get update -y || error_exit "Failed to update package index."

        # Install packages to allow apt to use a repository over HTTPS
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release ufw fail2ban mailutils || error_exit "Failed to install prerequisites for Docker."

        # Add Docker’s official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || error_exit "Failed to add Docker's GPG key."

        # Set up the stable repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null || error_exit "Failed to add Docker repository."

        # Update the apt package index again
        apt-get update -y || error_exit "Failed to update package index after adding Docker repository."

        # Install the latest version of Docker Engine, Docker CLI, and containerd
        apt-get install -y docker-ce docker-ce-cli containerd.io || error_exit "Failed to install Docker."

        # Enable and start Docker service
        systemctl enable docker || error_exit "Failed to enable Docker service."
        systemctl start docker || error_exit "Failed to start Docker service."

        log "Docker installed successfully."
    else
        log "Docker is already installed."
    fi
}

# Function to install Docker Compose if not installed
install_docker_compose() {
    if ! command -v docker-compose >/dev/null 2>&1; then
        log "Docker Compose not found. Installing Docker Compose..."

        # Get the latest version of Docker Compose from GitHub
        DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)

        if [[ -z "$DOCKER_COMPOSE_VERSION" ]]; then
            error_exit "Failed to fetch Docker Compose version from GitHub."
        fi

        # Download Docker Compose binary
        curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || error_exit "Failed to download Docker Compose."

        # Apply executable permissions to the binary
        chmod +x /usr/local/bin/docker-compose || error_exit "Failed to apply executable permissions to Docker Compose."

        # Create a symbolic link to /usr/bin if necessary
        if [ ! -L /usr/bin/docker-compose ]; then
            ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || error_exit "Failed to create symbolic link for Docker Compose."
        fi

        # Verify installation
        if ! docker-compose --version >/dev/null 2>&1; then
            error_exit "Docker Compose installation verification failed."
        fi

        log "Docker Compose installed successfully."
    else
        log "Docker Compose is already installed."
    fi
}

# Function to install Node-RED Dashboard
install_node_red_dashboard() {
    log "Installing Node-RED Dashboard..."
    cd "$PROJECT_DIR"
    npm install node-red-dashboard || error_exit "Failed to install node-red-dashboard."
    log "Node-RED Dashboard installed successfully."
}

# Function to create .env file with specified content and secure it
create_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        cat > "$ENV_FILE" <<'EOF'
# ================================
# Node-RED Environment Variables
# ================================

# Server Configuration
NODE_RED_PORT=1880

# GitHub Configuration
GITHUB_REPO=your-org/your-repo
GITHUB_TOKEN=your_github_token_here

# OpenAI API Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Slack Configuration
SLACK_CHANNEL=C123456
SLACK_TOKEN=xoxb-your-slack-token

# Email Configuration
ALERT_EMAIL=alerts@company.com
SMTP_SERVER=smtp.your-email.com
SMTP_PORT=587
SMTP_USER=your_smtp_user
SMTP_PASS=your_smtp_password

# Chatbot Configuration
CHATBOT_A_API_URL=https://api.chatbot-a.com/v1/messages
CHATBOT_A_API_KEY=your_chatbot_a_api_key
CHATBOT_B_API_URL=https://api.chatbot-b.com/v1/messages
CHATBOT_B_API_KEY=your_chatbot_b_api_key

# Processing Configuration
INITIAL_CODE_FILE=src/main.py
FINALIZED_CODE_FILE=src/main_final.py
PROCESSING_RANGE_START=2000
RANGE_INCREMENT=2000
MAX_ITERATIONS_PER_CHATBOT=5
EOF
        chmod 600 "$ENV_FILE"
        log "Created .env file with placeholders and set permissions to 600."
    else
        log ".env file already exists. Skipping creation."
    fi
}

# Function to generate bcrypt hash for admin password using Node.js
generate_bcrypt_hash() {
    read -sp "Enter admin password for Node-RED: " ADMIN_PASSWORD
    echo
    # Generate bcrypt hash using Node.js
    ADMIN_HASH=$(node -e "const bcrypt = require('bcrypt'); bcrypt.hash('$ADMIN_PASSWORD', 10, function(err, hash) { if (err) { console.error(err); process.exit(1); } else { console.log(hash); } });")
    echo "$ADMIN_HASH"
}

# Function to create settings.js with security enhancements
create_settings_js() {
    if [ ! -f "$SETTINGS_FILE" ]; then
        log "Generating settings.js..."

        create_dir "$CONFIG_DIR/ssl"

        cat > "$SETTINGS_FILE" <<'EOF'
require('dotenv').config();
const fs = require('fs');

module.exports = {
    // HTTP Admin Root
    httpAdminRoot: "/admin",
    // HTTP Node Root
    httpNodeRoot: "/api",
    // User directory
    userDir: "/data",
    // Enable global context
    functionGlobalContext: {},

    // Admin Authentication
    adminAuth: {
        type: "credentials",
        users: [{
            username: "admin",
            password: "PLACEHOLDER_HASH", // This will be replaced by the script
            permissions: "*"
        }]
    },

    // Security Settings
    editorTheme: {
        page: {
            title: "Node-RED Automation",
            favicon: "",
            css: ""
        },
        header: {
            title: "Node-RED Automation",
            image: "", // Path to image
            url: "http://localhost:1880/"
        },
        login: {
            image: "", // Path to image
            title: "Node-RED Automation",
            subtitle: "Please enter your credentials"
        }
    },

    // Logging
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    }

    // Other settings...
};
EOF

        # Replace PLACEHOLDER_HASH with the actual bcrypt hash
        BCRYPT_HASH=$(generate_bcrypt_hash)
        sed -i "s/PLACEHOLDER_HASH/$BCRYPT_HASH/" "$SETTINGS_FILE" || error_exit "Failed to insert bcrypt hash into settings.js."

        log "Generated settings.js with admin authentication."
    else
        log "settings.js already exists. Skipping generation."
    fi
}

# Function to create flow.json with enhanced configuration
create_flow_json() {
    create_dir "$CONFIG_DIR"

    cat > "$FLOW_FILE" <<'EOF'
[
    {
        "id": "schedule-trigger",
        "type": "inject",
        "z": "flow",
        "name": "Schedule Trigger",
        "props": [],
        "repeat": "1800",
        "crontab": "",
        "once": true,
        "topic": "",
        "x": 150,
        "y": 100,
        "wires": [
            [
                "config-loader"
            ]
        ]
    },
    {
        "id": "config-loader",
        "type": "change",
        "z": "flow",
        "name": "Load Configuration",
        "rules": [
            {
                "t": "set",
                "p": "flow.config",
                "to": "$.flow.context.config",
                "toType": "global"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 350,
        "y": 100,
        "wires": [
            [
                "code-extractor"
            ]
        ]
    },
    {
        "id": "code-extractor",
        "type": "function",
        "z": "flow",
        "name": "Code Extractor",
        "func": "const fs = require('fs');\n\nconst config = JSON.parse(fs.readFileSync('/data/config/config.json', 'utf8'));\nconst start = parseInt(config.PROCESSING_RANGE_START, 10);\nconst increment = parseInt(config.RANGE_INCREMENT, 10);\nconst codeFile = config.INITIAL_CODE_FILE;\n\ntry {\n    const code = fs.readFileSync(codeFile, 'utf8');\n    const lines = code.split('\\n');\n    \n    // Initialize ranges array\n    msg.ranges = [];\n    let currentStart = start;\n    let currentEnd = currentStart + increment;\n\n    while (currentStart < lines.length) {\n        let adjustedStart = currentStart;\n        let adjustedEnd = currentEnd;\n\n        // Adjust start to include full function\n        while (adjustedStart > 0 && !/\\b(def |class |async def )/.test(lines[adjustedStart - 1])) {\n            adjustedStart--;\n        }\n\n        // Adjust end to include full function\n        while (adjustedEnd < lines.length && !/\\b(return|raise |except |finally:)/.test(lines[adjustedEnd])) {\n            adjustedEnd++;\n        }\n\n        // Push the adjusted range\n        msg.ranges.push({ start: adjustedStart, end: adjustedEnd });\n\n        // Increment for next range\n        currentStart += increment;\n        currentEnd += increment;\n    }\n\n    // Initialize range processing index\n    msg.current_range_index = 0;\n\n    return msg;\n} catch (err) {\n    msg.error = 'Code extraction failed: ' + err.message;\n    return [null, msg];\n}",
        "outputs": 2,
        "noerr": 0,
        "x": 550,
        "y": 100,
        "wires": [
            [
                "range-iterator"
            ],
            [
                "error-handler"
            ]
        ]
    },
    {
        "id": "range-iterator",
        "type": "function",
        "z": "flow",
        "name": "Range Iterator",
        "func": "if (msg.current_range_index < msg.ranges.length) {\n    const currentRange = msg.ranges[msg.current_range_index];\n    msg.current_range = currentRange;\n    \n    // Extract code chunk based on current range\n    const fs = require('fs');\n    const code = fs.readFileSync(msg.config.INITIAL_CODE_FILE, 'utf8');\n    const lines = code.split('\\n');\n    const codeChunk = lines.slice(currentRange.start, currentRange.end + 1).join('\\n');\n    \n    msg.code_chunk = codeChunk;\n    msg.iteration = 0;\n    msg.chatbots = [\n        { name: \"Chatbot A\", api_url: msg.config.CHATBOT_A_API_URL, api_key: msg.config.CHATBOT_A_API_KEY },\n        { name: \"Chatbot B\", api_url: msg.config.CHATBOT_B_API_URL, api_key: msg.config.CHATBOT_B_API_KEY }\n    ];\n    msg.current_chatbot_index = 0;\n    \n    return msg;\n} else {\n    // All ranges processed\n    return [msg, null];\n}\n",
        "outputs": 2,
        "noerr": 0,
        "x": 750,
        "y": 100,
        "wires": [
            [
                "prompt-engine"
            ],
            [
                "finalization"
            ]
        ]
    },
    {
        "id": "prompt-engine",
        "type": "function",
        "z": "flow",
        "name": "Prompt Engine",
        "func": "const prompts = msg.config.PROMPTS;\n\nconst randomPrompt = prompts[Math.floor(Math.random() * prompts.length)];\nmsg.prompt = `${randomPrompt}\\n\\nPython code:\\n${msg.code_chunk}\\n\\nContext:\\n${msg.context || ''}`;\nreturn msg;\n",
        "outputs": 1,
        "noerr": 0,
        "x": 950,
        "y": 100,
        "wires": [
            [
                "ai-gateway-configurator"
            ]
        ]
    },
    {
        "id": "ai-gateway-configurator",
        "type": "function",
        "z": "flow",
        "name": "AI Gateway Configurator",
        "func": "const chatbot = msg.chatbots[msg.current_chatbot_index % msg.chatbots.length];\n\nmsg.url = chatbot.api_url;\nmsg.headers = {\n    \"Content-Type\": \"application/json\",\n    \"Authorization\": `Bearer ${chatbot.api_key}`\n};\nmsg.payload = JSON.stringify({\n    model: \"gpt-4\",\n    messages: [\n        { role: \"system\", content: \"You are a senior code reviewer.\" },\n        { role: \"user\", content: msg.prompt }\n    ]\n});\n\nreturn msg;\n",
        "outputs": 1,
        "noerr": 0,
        "x": 1150,
        "y": 100,
        "wires": [
            [
                "ai-gateway"
            ]
        ]
    },
    {
        "id": "ai-gateway",
        "type": "http request",
        "z": "flow",
        "name": "AI Chatbot Request",
        "method": "POST",
        "ret": "obj",
        "url": "",
        "tls": "",
        "x": 1350,
        "y": 100,
        "wires": [
            [
                "ai-response-processor"
            ],
            [
                "error-handler"
            ]
        ],
        "headers": {
            "Content-Type": "application/json",
            "Authorization": ""
        },
        "property": "",
        "body": ""
    },
    {
        "id": "ai-response-processor",
        "type": "function",
        "z": "flow",
        "name": "AI Response Processor",
        "func": "const response = msg.payload;\nlet correctedCode = '';\n\nif (response && response.choices && response.choices.length > 0) {\n    correctedCode = response.choices[0].message.content.trim();\n} else {\n    msg.error = 'Invalid response from AI chatbot.';\n    return [null, msg];\n}\n\nmsg.corrected_code = correctedCode;\n\n// Increment iteration count\nmsg.iteration += 1;\n\n// Update code chunk with corrected code\nmsg.code_chunk = correctedCode;\n\n// Alternate to next chatbot\nmsg.current_chatbot_index += 1;\n\nreturn msg;\n",
        "outputs": 2,
        "noerr": 0,
        "x": 1550,
        "y": 100,
        "wires": [
            [
                "check-iterations"
            ],
            [
                "error-handler"
            ]
        ]
    },
    {
        "id": "check-iterations",
        "type": "function",
        "z": "flow",
        "name": "Check Iterations",
        "func": "const config = JSON.parse(fs.readFileSync('/data/config/config.json', 'utf8'));\nif (msg.iteration < config.MAX_ITERATIONS_PER_CHATBOT) {\n    return msg;\n} else {\n    return [null, msg];\n}\n",
        "outputs": 2,
        "noerr": 0,
        "x": 1750,
        "y": 100,
        "wires": [
            [
                "finalize-corrected-code"
            ],
            [
                "range-iterator-increment"
            ]
        ]
    },
    {
        "id": "finalize-corrected-code",
        "type": "function",
        "z": "flow",
        "name": "Finalize Corrected Code",
        "func": "const fs = require('fs');\n\nconst finalizedCode = msg.corrected_code;\nconst finalizedFile = msg.config.FINALIZED_CODE_FILE;\n\ntry {\n    fs.writeFileSync(finalizedFile, finalizedCode, 'utf8');\n    msg.commit_message = \"Automated Code Update: Finalized corrections for range \" + msg.current_range.start + \"-\" + msg.current_range.end;\n    return msg;\n} catch (err) {\n    msg.error = 'Finalization failed: ' + err.message;\n    return [null, msg];\n}\n",
        "outputs": 2,
        "noerr": 0,
        "x": 1950,
        "y": 100,
        "wires": [
            [
                "github-versioner"
            ],
            [
                "error-handler"
            ]
        ]
    },
    {
        "id": "github-versioner",
        "type": "github",
        "z": "flow",
        "name": "Push to GitHub",
        "repo": "${GITHUB_REPO}",
        "token": "${GITHUB_TOKEN}",
        "operation": "commit",
        "commitMessage": "${commit_message}",
        "filePath": "${FINALIZED_CODE_FILE}",
        "fileContent": "${corrected_code}",
        "branch": "main",
        "x": 2150,
        "y": 100,
        "wires": [
            [
                "slack-notifier"
            ],
            [
                "error-handler"
            ]
        ]
    },
    {
        "id": "slack-notifier",
        "type": "slack",
        "z": "flow",
        "name": "Slack Notification",
        "token": "${SLACK_TOKEN}",
        "channel": "${SLACK_CHANNEL}",
        "message": "✅ *Code Update Successful*\nChanges have been committed to GitHub.\nFile: ${FINALIZED_CODE_FILE}",
        "x": 2350,
        "y": 100,
        "wires": []
    },
    {
        "id": "range-iterator-increment",
        "type": "function",
        "z": "flow",
        "name": "Range Iterator Increment",
        "func": "msg.current_range_index += 1;\nreturn msg;\n",
        "outputs": 1,
        "noerr": 0,
        "x": 1750,
        "y": 200,
        "wires": [
            [
                "range-iterator"
            ]
        ]
    },
    {
        "id": "finalization",
        "type": "function",
        "z": "flow",
        "name": "Finalization",
        "func": "// Placeholder for any finalization steps if needed\n// For example, resetting variables or logging\nreturn msg;\n",
        "outputs": 1,
        "noerr": 0,
        "x": 1550,
        "y": 200,
        "wires": [
            [
                "range-iterator-increment"
            ]
        ]
    },
    {
        "id": "error-handler",
        "type": "function",
        "z": "flow",
        "name": "Error Handler",
        "func": "const nodemailer = require('nodemailer');\n\n// Validate SMTP configuration\nif (!msg.config.SMTP_SERVER || !msg.config.SMTP_PORT || !msg.config.SMTP_USER || !msg.config.SMTP_PASS) {\n    node.error('SMTP configuration is incomplete.', msg);\n    return null;\n}\n\nconst transporter = nodemailer.createTransport({\n    host: msg.config.SMTP_SERVER,\n    port: parseInt(msg.config.SMTP_PORT, 10),\n    secure: msg.config.SMTP_PORT == 465, // true for 465, false for other ports\n    auth: {\n        user: msg.config.SMTP_USER,\n        pass: msg.config.SMTP_PASS\n    }\n});\n\nconst mailOptions = {\n    from: \"Error Notifier\" <${msg.config.SMTP_USER}>,\n    to: msg.config.ALERT_EMAIL,\n    subject: msg.subject || '🚨 AI Validation Failed',\n    text: msg.body || msg.error\n};\n\ntransporter.sendMail(mailOptions, (error, info) => {\n    if (error) {\n        node.error('Failed to send error email: ' + error.message, msg);\n    } else {\n        node.log('Error email sent: ' + info.response);\n    }\n});\n\nreturn null;\n",
        "outputs": 0,
        "noerr": 0,
        "x": 1750,
        "y": 300,
        "wires": []
    }
]
EOF
    log "Created flow.json with main flows."
}

# Function to create Dockerfile with multi-stage builds and optimizations
create_dockerfile() {
    cat > "$DOCKERFILE" <<'EOF'
# Stage 1: Build
FROM node:16 as builder

WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy source files
COPY flows.json config/ src/ subflows/ ./

# Stage 2: Production
FROM nodered/node-red:latest

# Set working directory
WORKDIR /data

# Copy only necessary files from builder
COPY --from=builder /app/flows.json /data/flows.json
COPY --from=builder /app/config /data/config
COPY --from=builder /app/src /data/src
COPY --from=builder /app/subflows /data/subflows

# Copy wait-for-it.sh for service dependency handling
COPY wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod +x /usr/local/bin/wait-for-it.sh

# Expose Node-RED port
EXPOSE 1880

# Start Node-RED with dependency wait
CMD ["wait-for-it.sh", "nginx:80", "--", "npm", "start"]
EOF
    log "Created Dockerfile with multi-stage builds and optimizations."
}

# Function to create Docker Compose file with enhancements
create_docker_compose() {
    cat > "$DOCKER_COMPOSE_FILE" <<'EOF'
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./config/ssl:/etc/nginx/ssl
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    depends_on:
      - node-red
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 1m30s
      timeout: 10s
      retries: 3

  node-red:
    build: .
    environment:
      - NODE_RED_PORT=${NODE_RED_PORT}
      - GITHUB_REPO=${GITHUB_REPO}
      - GITHUB_TOKEN_FILE=/run/secrets/github_token
      - SLACK_TOKEN_FILE=/run/secrets/slack_token
      # Add other environment variables as needed
    env_file:
      - .env
    volumes:
      - ./flows.json:/data/flows.json
      - ./config:/data/config
      - ./src:/data/src
      - ./subflows:/data/subflows
      - node-red-data:/data
    restart: unless-stopped
    secrets:
      - github_token
      - slack_token
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:1880/health"]
      interval: 1m30s
      timeout: 10s
      retries: 3
    depends_on:
      nginx:
        condition: service_healthy

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./monitoring/prometheus/provisioning:/etc/prometheus/provisioning
    ports:
      - "9090:9090"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9090/-/healthy"]
      interval: 1m30s
      timeout: 10s
      retries: 3

  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 1m30s
      timeout: 10s
      retries: 3

  certbot:
    image: certbot/certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do sleep 12h & wait $${!}; certbot renew; done;'"
    restart: unless-stopped

  certbot_init:
    image: certbot/certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do sleep 12h & wait $${!}; certbot renew; done;'"
    command: certonly --webroot --webroot-path=/var/www/certbot --email ${EMAIL_ADDRESS} --agree-tos --no-eff-email -d ${DOMAIN_NAME}
    depends_on:
      - nginx
    restart: unless-stopped

secrets:
  github_token:
    file: ./secrets/github_token.txt
  slack_token:
    file: ./secrets/slack_token.txt

volumes:
  node-red-data:
  grafana-data:
EOF
    log "Created docker-compose.yml with container orchestration, secrets, and health checks."
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

# Function to create GitHub Actions CI/CD workflow with enhanced steps
create_ci_cd_yaml() {
    create_dir "$PROJECT_DIR/.github/workflows"

    cat > "$CI_CD_YML" <<EOF
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

# Function to set up automated backups using cron with enhanced reliability
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

# Function to install wait-for-it.sh for service dependency handling
install_wait_for_it() {
    WAIT_FOR_IT="$PROJECT_DIR/wait-for-it.sh"
    if [ ! -f "$WAIT_FOR_IT" ]; then
        curl -o "$WAIT_FOR_IT" https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh || error_exit "Failed to download wait-for-it.sh."
        chmod +x "$WAIT_FOR_IT" || error_exit "Failed to apply executable permissions to wait-for-it.sh."
        log "Downloaded and set permissions for wait-for-it.sh."
    else
        log "wait-for-it.sh already exists. Skipping download."
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

# Function to set up logrotate configuration
setup_logrotate_config() {
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

# Function to secure the .env file further if needed
secure_env_file() {
    chmod 600 "$ENV_FILE" || error_exit "Failed to set permissions on .env file."
    log "Secured .env file with permissions set to 600."
}

# Function to finalize and ensure all services are up and running
finalize_setup() {
    log "Finalizing setup..."

    # Reload systemd to recognize new services if any
    systemctl daemon-reload || log "No systemd daemon reload needed."

    # Restart Docker to apply any new configurations
    systemctl restart docker || error_exit "Failed to restart Docker service."

    log "Setup finalized successfully."
}

# Function to prompt the user to log out if necessary
prompt_logout() {
    echo "====================================================="
    echo "Docker group modification complete."
    echo "Please log out and log back in to apply Docker group changes."
    echo "====================================================="
}

# Function to print completion message
print_completion() {
    echo "===================================================="
    echo "Node-RED Automation setup completed successfully."
    echo "Navigate to the project directory: $PROJECT_DIR"
    echo "Run './start-docker.sh' to start all services."
    echo "Run './stop-docker.sh' to stop all services."
    echo "Access Node-RED Dashboard at https://yourdomain.com/ui"
    echo "===================================================="
}

# =============================================================================
# Execution Flow
# =============================================================================

# Initial checks
check_sudo
prompt_inputs  # Prompt for dynamic inputs
check_node_npm
check_node_version
create_dir "$PROJECT_DIR"
create_dir "$TMP_DIR"  # Temporary directory for cleanup
trap "rm -rf ${TMP_DIR}" EXIT  # Cleanup on exit
cd "$PROJECT_DIR"

# Configuration setup
create_custom_package_json  # Must come before npm init
init_npm
create_env_file
create_settings_js          # Generates settings.js with dotenv
create_config_json          # Creates config.json with default values

# Infrastructure setup
install_docker              # Now includes sudo and OS check
install_docker_compose
create_dockerfile
create_docker_compose

# Install Node-RED Dashboard
install_node_red_dashboard

# Security setup
install_fail2ban
configure_fail2ban

# Automated Backups
setup_automated_backups     # Now invoked

# Additional Setup
create_gitignore
create_sample_source
create_flow_json            # Creates main flows.json
create_prometheus_config
create_grafana_provisioning
create_ci_cd_yaml
create_docker_commands
create_monitoring_setup
create_test_scripts
create_subflows

# Dashboard and Configuration Flows
# Assuming create_configuration_flows is part of the additional script

# Log rotation setup
setup_logrotate_config

# Secure .env file
secure_env_file

# Finalization
finalize_setup

# Inform the user to log out if Docker group was modified
prompt_logout

# Create logrotate configuration
setup_logrotate_config

# Final completion message
print_completion

# =============================================================================
# End of Script
# =============================================================================
