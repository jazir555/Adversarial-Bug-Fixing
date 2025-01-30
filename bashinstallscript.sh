#!/bin/bash

# =============================================================================
# Script Name: setup-node-red-automation.sh
# Description: Automates the setup of a Node-RED environment for AI-driven
#              code analysis, validation, and deployment with GitHub integration,
#              Slack notifications, email alerts, Dockerization, CI/CD pipelines,
#              monitoring, testing, and security enhancements.
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
FLOW_DIR="$PROJECT_DIR/flows"
CONFIG_DIR="$PROJECT_DIR/config"
SRC_DIR="$PROJECT_DIR/src"
DOCKERFILE="$PROJECT_DIR/Dockerfile"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
CI_CD_YML="$PROJECT_DIR/.github/workflows/ci-cd.yml"
TEST_DIR="$PROJECT_DIR/tests"
SUBFLOWS_DIR="$PROJECT_DIR/subflows"
BACKUP_DIR="$PROJECT_DIR/backups"
MONITORING_DIR="$PROJECT_DIR/monitoring"

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

# Function to create a directory if it doesn't exist
create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1" || error_exit "Failed to create directory $1."
        log "Created directory: $1"
    else
        log "Directory already exists: $1"
    fi
}

# Function to install Docker if not installed
install_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log "Docker not found. Installing Docker..."

        # Update the apt package index
        sudo apt-get update -y || error_exit "Failed to update package index."

        # Install packages to allow apt to use a repository over HTTPS
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release || error_exit "Failed to install prerequisites for Docker."

        # Add Docker’s official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || error_exit "Failed to add Docker's GPG key."

        # Set up the stable repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || error_exit "Failed to add Docker repository."

        # Update the apt package index again
        sudo apt-get update -y || error_exit "Failed to update package index after adding Docker repository."

        # Install the latest version of Docker Engine, Docker CLI, and containerd
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io || error_exit "Failed to install Docker."

        # Enable and start Docker service
        sudo systemctl enable docker || error_exit "Failed to enable Docker service."
        sudo systemctl start docker || error_exit "Failed to start Docker service."

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

        # Download Docker Compose binary
        sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || error_exit "Failed to download Docker Compose."

        # Apply executable permissions to the binary
        sudo chmod +x /usr/local/bin/docker-compose || error_exit "Failed to apply executable permissions to Docker Compose."

        # Create a symbolic link to /usr/bin if necessary
        if [ ! -L /usr/bin/docker-compose ]; then
            sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || error_exit "Failed to create symbolic link for Docker Compose."
        fi

        log "Docker Compose installed successfully."
    else
        log "Docker Compose is already installed."
    fi
}

# Function to initialize npm and install dependencies
init_npm() {
    if [ ! -f "$PACKAGE_JSON_FILE" ]; then
        log "Initializing npm in $PROJECT_DIR..."
        cd "$PROJECT_DIR"
        npm init -y || error_exit "npm initialization failed."
        log "Initialized npm in $PROJECT_DIR."
    else
        log "npm already initialized in $PROJECT_DIR."
    fi

    # Install necessary packages
    log "Installing npm dependencies..."
    cd "$PROJECT_DIR"
    npm install node-red dotenv node-red-node-email node-red-node-slack node-red-contrib-github language-detect diff nodemailer jest mocha bcrypt --save || error_exit "npm install failed."
    log "npm dependencies installed successfully."
}

# Function to create .env file with specified content
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
PROCESSING_RANGE_START=3000
PROCESSING_RANGE_END=5000
RANGE_INCREMENT=2000
MAX_ITERATIONS_PER_CHATBOT=10
EOF
        log "Created .env file with placeholders."
    else
        log ".env file already exists. Skipping creation."
    fi
}

# Function to create package.json with specified content
create_package_json() {
    if [ ! -f "$PACKAGE_JSON_FILE" ]; then
        cat > "$PACKAGE_JSON_FILE" <<'EOF'
{
  "name": "node-red-automation",
  "version": "1.0.0",
  "description": "Automated Node-RED workflow for AI-driven code analysis, validation, and deployment.",
  "main": "index.js",
  "scripts": {
    "start": "node-red --userDir ./flows --flows flow.json",
    "test": "jest"
  },
  "dependencies": {
    "node-red": "^3.1.0",
    "node-red-node-email": "^1.0.1",
    "node-red-node-slack": "^1.1.0",
    "node-red-contrib-github": "^1.0.2",
    "language-detect": "^1.1.0",
    "diff": "^5.1.0",
    "dotenv": "^16.0.0",
    "nodemailer": "^6.9.0",
    "bcrypt": "^5.1.0"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "mocha": "^10.0.0"
  },
  "author": "Your Name",
  "license": "MIT"
}
EOF
        log "Created package.json with required dependencies."
    else
        log "package.json already exists. Skipping creation."
    fi
}

# Function to create flow.json with enhanced configuration
create_flow_json() {
    create_dir "$FLOW_DIR"

    cat > "$FLOW_DIR/flow.json" <<'EOF'
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
                "p": "github_repo",
                "to": "env.GITHUB_REPO",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "github_token",
                "to": "env.GITHUB_TOKEN",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "initial_code_file",
                "to": "env.INITIAL_CODE_FILE",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "finalized_code_file",
                "to": "env.FINALIZED_CODE_FILE",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "processing_range_start",
                "to": "env.PROCESSING_RANGE_START",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "processing_range_end",
                "to": "env.PROCESSING_RANGE_END",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "range_increment",
                "to": "env.RANGE_INCREMENT",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "max_iterations_per_chatbot",
                "to": "env.MAX_ITERATIONS_PER_CHATBOT",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "openai_api_key",
                "to": "env.OPENAI_API_KEY",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "slack_channel",
                "to": "env.SLACK_CHANNEL",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "slack_token",
                "to": "env.SLACK_TOKEN",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "alert_email",
                "to": "env.ALERT_EMAIL",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "smtp_server",
                "to": "env.SMTP_SERVER",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "smtp_port",
                "to": "env.SMTP_PORT",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "smtp_user",
                "to": "env.SMTP_USER",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "smtp_pass",
                "to": "env.SMTP_PASS",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "chatbot_a_api_url",
                "to": "env.CHATBOT_A_API_URL",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "chatbot_a_api_key",
                "to": "env.CHATBOT_A_API_KEY",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "chatbot_b_api_url",
                "to": "env.CHATBOT_B_API_URL",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "chatbot_b_api_key",
                "to": "env.CHATBOT_B_API_KEY",
                "toType": "env"
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
        "func": "const fs = require('fs');\n\nconst start = parseInt(msg.processing_range_start, 10);\nconst end = parseInt(msg.processing_range_end, 10);\nconst increment = parseInt(msg.range_increment, 10);\nconst codeFile = msg.initial_code_file;\n\ntry {\n    const code = fs.readFileSync(codeFile, 'utf8');\n    const lines = code.split('\\n');\n    \n    // Initialize ranges array\n    msg.ranges = [];\n    let currentStart = start;\n    let currentEnd = end;\n\n    while (currentStart < lines.length) {\n        let adjustedStart = currentStart;\n        let adjustedEnd = currentEnd;\n\n        // Adjust start to include full function\n        while (adjustedStart > 0 && !/\\b(def |class |async def )/.test(lines[adjustedStart - 1])) {\n            adjustedStart--;\n        }\n\n        // Adjust end to include full function\n        while (adjustedEnd < lines.length && !/\\b(return|raise |except |finally:)/.test(lines[adjustedEnd])) {\n            adjustedEnd++;\n        }\n\n        // Push the adjusted range\n        msg.ranges.push({ start: adjustedStart, end: adjustedEnd });\n\n        // Increment for next range\n        currentStart += increment;\n        currentEnd += increment;\n    }\n\n    // Initialize range processing index\n    msg.current_range_index = 0;\n\n    return msg;\n} catch (err) {\n    msg.error = 'Code extraction failed: ' + err.message;\n    return [null, msg];\n}",
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
        "func": "if (msg.current_range_index < msg.ranges.length) {\n    const currentRange = msg.ranges[msg.current_range_index];\n    msg.current_range = currentRange;\n    \n    // Extract code chunk based on current range\n    const fs = require('fs');\n    const code = fs.readFileSync(msg.initial_code_file, 'utf8');\n    const lines = code.split('\\n');\n    const codeChunk = lines.slice(currentRange.start, currentRange.end + 1).join('\\n');\n    \n    msg.code_chunk = codeChunk;\n    msg.iteration = 0;\n    msg.chatbots = [\n        { name: \"Chatbot A\", api_url: msg.chatbot_a_api_url, api_key: msg.chatbot_a_api_key },\n        { name: \"Chatbot B\", api_url: msg.chatbot_b_api_url, api_key: msg.chatbot_b_api_key }\n    ];\n    msg.current_chatbot_index = 0;\n    \n    return msg;\n} else {\n    // All ranges processed\n    return [msg, null];\n}\n",
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
        "func": "const prompts = [\n    'Check this code for errors, make sure it is bug free, add any functionality you think is important.',\n    'Identify all logic flaws.',\n    'Optimize performance bottlenecks.',\n    'Enhance security best practices.',\n    'Refactor redundant code.',\n    'Check compliance with coding standards.'\n];\n\nconst randomPrompt = prompts[Math.floor(Math.random() * prompts.length)];\nmsg.prompt = `${randomPrompt}\\n\\n${msg.language || 'Python'} code:\\n${msg.code_chunk}\\n\\nContext:\\n${msg.context || ''}`;\nreturn msg;\n",
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
        "func": "if (msg.iteration < msg.max_iterations_per_chatbot) {\n    return msg;\n} else {\n    return [null, msg];\n}\n",
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
        "func": "const fs = require('fs');\n\nconst finalizedCode = msg.corrected_code;\nconst finalizedFile = msg.finalized_code_file;\n\ntry {\n    fs.writeFileSync(finalizedFile, finalizedCode, 'utf8');\n    msg.commit_message = \"Automated Code Update: Finalized corrections for range \" + msg.current_range.start + \"-\" + msg.current_range.end;\n    return msg;\n} catch (err) {\n    msg.error = 'Finalization failed: ' + err.message;\n    return [null, msg];\n}\n",
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
        "repo": "{{github_repo}}",
        "token": "{{github_token}}",
        "operation": "commit",
        "commitMessage": "{{commit_message}}",
        "filePath": "{{finalized_code_file}}",
        "fileContent": "{{corrected_code}}",
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
        "token": "{{slack_token}}",
        "channel": "{{slack_channel}}",
        "message": "✅ *Code Update Successful*\nChanges have been committed to GitHub.\nFile: {{finalized_code_file}}",
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
        "func": "const nodemailer = require('nodemailer');\n\n// Validate SMTP configuration\nif (!msg.smtp_server || !msg.smtp_port || !msg.smtp_user || !msg.smtp_pass) {\n    node.error('SMTP configuration is incomplete.', msg);\n    return null;\n}\n\nconst transporter = nodemailer.createTransport({\n    host: msg.smtp_server,\n    port: parseInt(msg.smtp_port, 10),\n    secure: msg.smtp_port == 465, // true for 465, false for other ports\n    auth: {\n        user: msg.smtp_user,\n        pass: msg.smtp_pass\n    }\n});\n\nconst mailOptions = {\n    from: `\"Error Notifier\" <${msg.smtp_user}>`,\n    to: msg.alert_email,\n    subject: msg.subject || '🚨 AI Validation Failed',\n    text: msg.body || msg.error\n};\n\ntransporter.sendMail(mailOptions, (error, info) => {\n    if (error) {\n        node.error('Failed to send error email: ' + error.message, msg);\n    } else {\n        node.log('Error email sent: ' + info.response);\n    }\n});\n\nreturn null;\n",
        "outputs": 0,
        "noerr": 0,
        "x": 1750,
        "y": 300,
        "wires": []
    }
]
EOF
    log "Created flow.json with enhanced configuration."
}

# Function to create Dockerfile
create_dockerfile() {
    cat > "$DOCKERFILE" <<'EOF'
# Use the official Node-RED image as the base
FROM nodered/node-red:latest

# Set working directory
WORKDIR /data

# Copy package.json and install dependencies
COPY package.json .
RUN npm install

# Copy flow configurations and source code
COPY flows/ flows/
COPY config/ config/
COPY src/ src/
COPY subflows/ subflows/
COPY tests/ tests/

# Expose Node-RED port
EXPOSE 1880

# Start Node-RED
CMD ["npm", "start"]
EOF
    log "Created Dockerfile for Dockerization."
}

# Function to create Docker Compose file
create_docker_compose() {
    cat > "$DOCKER_COMPOSE_FILE" <<'EOF'
version: '3.8'

services:
  node-red:
    build: .
    ports:
      - "${NODE_RED_PORT}:1880"
    volumes:
      - ./flows:/data/flows
      - ./config:/data/config
      - ./src:/data/src
      - ./subflows:/data/subflows
      - ./tests:/data/tests
      - node-red-data:/data
    environment:
      - NODE_RED_PORT=${NODE_RED_PORT}
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
    restart: unless-stopped

volumes:
  node-red-data:
  grafana-data:
EOF
    log "Created docker-compose.yml for container orchestration."
}

# Function to create Prometheus configuration
create_prometheus_config() {
    create_dir "$MONITORING_DIR"

    cat > "$MONITORING_DIR/prometheus.yml" <<'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node-red'
    static_configs:
      - targets: ['node-red:1880']
EOF
    log "Created Prometheus configuration."
}

# Function to create GitHub Actions CI/CD workflow
create_ci_cd_yaml() {
    create_dir "$PROJECT_DIR/.github/workflows"

    cat > "$CI_CD_YML" <<'EOF'
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
        node-version: '14'

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
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    - name: Push Docker Image
      run: |
        docker tag node-red-automation:latest your-dockerhub-username/node-red-automation:latest
        docker push your-dockerhub-username/node-red-automation:latest

    - name: Deploy to Server
      uses: easingthemes/ssh-deploy@v2.0.7
      with:
        ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
        remote-user: your-remote-user
        server-ip: your-server-ip
        remote-path: /path/to/deploy
        command: |
          docker pull your-dockerhub-username/node-red-automation:latest
          docker stop node-red-automation || true
          docker rm node-red-automation || true
          docker run -d -p 1880:1880 --name node-red-automation your-dockerhub-username/node-red-automation:latest
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

    # Sample Jest test
    cat > "$TEST_DIR/sample.test.js" <<'EOF'
const sum = (a, b) => a + b;

test('adds 1 + 2 to equal 3', () => {
    expect(sum(1, 2)).toBe(3);
});
EOF

    # Sample Mocha test
    cat > "$TEST_DIR/sample.spec.js" <<'EOF'
const assert = require('assert');

describe('Array', function() {
    describe('#indexOf()', function() {
        it('should return -1 when the value is not present', function() {
            assert.strictEqual([1,2,3].indexOf(4), -1);
        });
    });
});
EOF

    log "Created sample test scripts for Jest and Mocha."
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

/monitoring/

/subflows/

/config/settings.js

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

# Function to set up automated backups using cron
setup_automated_backups() {
    create_dir "$BACKUP_DIR"

    cat > "$BACKUP_DIR/backup.sh" <<'EOF'
#!/bin/bash

# Directory to backup
SOURCE_DIR="$(pwd)"
BACKUP_DIR="$(pwd)/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

# Create backup
tar -czf "$BACKUP_FILE" "$SOURCE_DIR"

# Optional: Remove backups older than 7 days
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +7 -exec rm {} \;

echo "Backup created at $BACKUP_FILE and old backups removed."
EOF

    chmod +x "$BACKUP_DIR/backup.sh"

    # Add cron job (runs daily at 2 AM)
    CRON_JOB="0 2 * * * $(pwd)/backups/backup.sh"
    (crontab -l 2>/dev/null | grep -v "$(pwd)/backups/backup.sh"; echo "$CRON_JOB") | crontab -
    log "Set up automated backups with cron."
}

# Function to implement security enhancements
implement_security() {
    # 1. API Rate Limiting
    cat > "$FLOW_DIR/rate-limiter.json" <<'EOF'
{
    "id": "rate-limiter",
    "type": "subflow",
    "name": "Rate Limiter",
    "info": "Limits the rate of API requests to prevent abuse.",
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
            "name": "RATE_LIMIT",
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

    # 2. Data Encryption
    # Note: Ensure all external communications use HTTPS/TLS.
    # For Node-RED editor access, consider setting up HTTPS.

    # 3. Access Controls
    # Locate the Node-RED settings.js file. By default, it's in ~/.node-red/
    SETTINGS_DIR="$CONFIG_DIR"
    SETTINGS_FILE="$SETTINGS_DIR/settings.js"

    create_dir "$SETTINGS_DIR"

    if [ ! -f "$SETTINGS_FILE" ]; then
        cp "$(npm root -g)/node-red/settings.js" "$SETTINGS_FILE" || error_exit "Failed to copy default settings.js."
        log "Copied default settings.js to $SETTINGS_FILE."
    else
        log "settings.js already exists at $SETTINGS_FILE. Skipping copy."
    fi

    # Append adminAuth configuration if not already present
    if ! grep -q "adminAuth" "$SETTINGS_FILE"; then
        cat >> "$SETTINGS_FILE" <<'EOF'

adminAuth: {
    type: "credentials",
    users: [{
        username: "admin",
        password: "$2a$08$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", // Replace with your bcrypt hash
        permissions: "*"
    }]
},
EOF
        log "Configured Node-RED access controls in settings.js."
    else
        log "adminAuth already configured in settings.js. Skipping."
    fi
}

# Function to create README.md with detailed setup instructions
create_readme() {
    cat > "$README_FILE" <<'EOF'
# Node-RED Automation

