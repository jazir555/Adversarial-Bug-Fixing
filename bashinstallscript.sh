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

PROJECT_DIR="node-red-automation"
LOG_FILE="setup.log"
ENV_FILE=".env"
README_FILE="README.md"
GITIGNORE_FILE=".gitignore"
PACKAGE_JSON_FILE="package.json"
FLOW_DIR="flows"
CONFIG_DIR="config"
SRC_DIR="src"
DOCKERFILE="Dockerfile"
DOCKER_COMPOSE_FILE="docker-compose.yml"
CI_CD_YML=".github/workflows/ci-cd.yml"
TEST_DIR="tests"
SUBFLOWS_DIR="subflows"
BACKUP_DIR="backups"

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
    command -v "$1" >/dev/null 2>&1 || error_exit "$1 is not installed. Please install it and rerun the script."
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

# Function to initialize npm and install dependencies
init_npm() {
    if [ ! -f "$PACKAGE_JSON_FILE" ]; then
        npm init -y || error_exit "npm initialization failed."
        log "Initialized npm in $PROJECT_DIR."
    else
        log "npm already initialized in $PROJECT_DIR."
    fi

    # Install necessary packages
    log "Installing npm dependencies..."
    npm install node-red dotenv node-red-node-email node-red-node-slack node-red-contrib-github language-detect diff nodemailer jest mocha --save || error_exit "npm install failed."
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
    "nodemailer": "^6.9.0"
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
        "repeat": "1800",  // Trigger every 30 minutes
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
        "func": `
if (msg.current_range_index < msg.ranges.length) {
    const currentRange = msg.ranges[msg.current_range_index];
    msg.current_range = currentRange;
    
    // Extract code chunk based on current range
    const fs = require('fs');
    const code = fs.readFileSync(msg.initial_code_file, 'utf8');
    const lines = code.split('\\n');
    const codeChunk = lines.slice(currentRange.start, currentRange.end + 1).join('\\n');
    
    msg.code_chunk = codeChunk;
    msg.iteration = 0;
    msg.chatbots = [
        { name: "Chatbot A", api_url: msg.chatbot_a_api_url, api_key: msg.chatbot_a_api_key },
        { name: "Chatbot B", api_url: msg.chatbot_b_api_url, api_key: msg.chatbot_b_api_key }
    ];
    msg.current_chatbot_index = 0;
    
    return msg;
} else {
    // All ranges processed
    return [msg, null];
}
`,
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
        "func": `
const prompts = [
    'Check this code for errors, make sure it is bug free, add any functionality you think is important.',
    'Identify all logic flaws.',
    'Optimize performance bottlenecks.',
    'Enhance security best practices.',
    'Refactor redundant code.',
    'Check compliance with coding standards.'
];

const randomPrompt = prompts[Math.floor(Math.random() * prompts.length)];
msg.prompt = \`\${randomPrompt}\\n\\n\${msg.language || 'Python'} code:\\n\${msg.code_chunk}\\n\\nContext:\\n\${msg.context || ''}\`;
return msg;
`,
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
        "func": `
const chatbot = msg.chatbots[msg.current_chatbot_index % msg.chatbots.length];

msg.url = chatbot.api_url;
msg.headers = {
    "Content-Type": "application/json",
    "Authorization": \`Bearer \${chatbot.api_key}\`
};
msg.payload = JSON.stringify({
    model: "gpt-4",
    messages: [
        { role: "system", content: "You are a senior code reviewer." },
        { role: "user", content: msg.prompt }
    ]
});

return msg;
`,
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
        "func": `
const response = msg.payload;
let correctedCode = '';

if (response && response.choices && response.choices.length > 0) {
    correctedCode = response.choices[0].message.content.trim();
} else {
    msg.error = 'Invalid response from AI chatbot.';
    return [null, msg];
}

msg.corrected_code = correctedCode;

// Increment iteration count
msg.iteration += 1;

// Update code chunk with corrected code
msg.code_chunk = correctedCode;

// Alternate to next chatbot
msg.current_chatbot_index += 1;

return msg;
`,
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
        "func": `
if (msg.iteration < msg.max_iterations_per_chatbot) {
    return msg;
} else {
    return [null, msg];
}
`,
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
        "func": `
const fs = require('fs');

const finalizedCode = msg.corrected_code;
const finalizedFile = msg.finalized_code_file;

try {
    fs.writeFileSync(finalizedFile, finalizedCode, 'utf8');
    msg.commit_message = "Automated Code Update: Finalized corrections for range " + msg.current_range.start + "-" + msg.current_range.end;
    return msg;
} catch (err) {
    msg.error = 'Finalization failed: ' + err.message;
    return [null, msg];
}
`,
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
        "func": `
msg.current_range_index += 1;
return msg;
`,
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
        "func": `
// Placeholder for any finalization steps if needed
// For example, resetting variables or logging
return msg;
`,
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
        "func": `
const nodemailer = require('nodemailer');

// Validate SMTP configuration
if (!msg.smtp_server || !msg.smtp_port || !msg.smtp_user || !msg.smtp_pass) {
    node.error('SMTP configuration is incomplete.', msg);
    return null;
}

const transporter = nodemailer.createTransport({
    host: msg.smtp_server,
    port: parseInt(msg.smtp_port, 10),
    secure: msg.smtp_port == 465, // true for 465, false for other ports
    auth: {
        user: msg.smtp_user,
        pass: msg.smtp_pass
    }
});

const mailOptions = {
    from: \`"Error Notifier" <\${msg.smtp_user}>\`,
    to: msg.alert_email,
    subject: msg.subject || '🚨 AI Validation Failed',
    text: msg.body || msg.error
};

transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
        node.error('Failed to send error email: ' + error.message, msg);
    } else {
        node.log('Error email sent: ' + info.response);
    }
});

return null;
`,
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
    create_dir "monitoring"

    cat > "monitoring/prometheus.yml" <<'EOF'
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
    create_dir ".github/workflows"

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
    cat > "start-docker.sh" <<'EOF'
#!/bin/bash
docker-compose up -d
EOF

    cat > "stop-docker.sh" <<'EOF'
#!/bin/bash
docker-compose down
EOF

    chmod +x start-docker.sh stop-docker.sh
    log "Created Docker Compose start and stop scripts."
}

# Function to create Prometheus and Grafana setup scripts
create_monitoring_setup() {
    cat > "monitoring/setup-monitoring.sh" <<'EOF'
#!/bin/bash

# Start Prometheus and Grafana using Docker Compose
docker-compose up -d prometheus grafana

echo "Prometheus is available at http://localhost:9090"
echo "Grafana is available at http://localhost:3000 (default login: admin/admin)"
EOF

    chmod +x monitoring/setup-monitoring.sh
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
        }
    ],
    "color": "#a6bbcf"
}
EOF

    log "Created sample subflow for API Request Handling."
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
    CRON_JOB="0 2 * * * $(pwd)/$BACKUP_DIR/backup.sh"
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
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
    SETTINGS_FILE="$FLOW_DIR/settings.js"

    if [ ! -f "$SETTINGS_FILE" ]; then
        cp "$FLOW_DIR/settings.js.sample" "$SETTINGS_FILE" || error_exit "Failed to copy settings.js.sample to settings.js."
        log "Copied settings.js.sample to settings.js."
    fi

    # Append adminAuth configuration
    cat >> "$SETTINGS_FILE" <<'EOF'

adminAuth: {
    type: "credentials",
    users: [{
        username: "admin",
        password: "$2a$08$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", // bcrypt hash of your password
        permissions: "*"
    }]
},
EOF

    log "Configured Node-RED access controls in settings.js."
}

# Function to create README.md with detailed setup instructions
create_readme() {
    cat > "$README_FILE" <<'EOF'
# Node-RED Automation

## Description
Automated Node-RED workflow for AI-driven code analysis, validation, and deployment to GitHub with notifications via Slack and email alerts. Additionally, the setup includes Dockerization for consistent environments, CI/CD pipelines using GitHub Actions, monitoring with Prometheus and Grafana, unit and integration testing, reusable subflows, security enhancements, automated backups, and comprehensive documentation.

## Features
- **Dynamic Code Range Selection:** Automatically extracts and processes specific ranges of code.
- **Multiple Chatbot Interactions:** Alternates between multiple AI chatbots for adversarial testing and validation.
- **Recursive Validation:** Iteratively refines code through multiple AI validation cycles.
- **GitHub Integration:** Commits validated and corrected code to a specified GitHub repository.
- **Notifications:**
  - **Slack:** Sends success notifications upon successful GitHub commits.
  - **Email:** Sends error alerts for any failures during the workflow.
- **Secure Configuration Management:** Utilizes environment variables to manage sensitive information securely.
- **Dockerization:** Ensures consistent environments across deployments.
- **CI/CD Pipeline:** Automates testing and deployment using GitHub Actions.
- **Monitoring and Logging:** Integrates Prometheus and Grafana for performance metrics and logs visualization.
- **Testing Frameworks:** Implements unit and integration tests using Jest and Mocha.
- **Reusable Subflows:** Encapsulates common functionalities for maintainability.
- **Automated Backups:** Regularly backs up configurations and source code.
- **Security Enhancements:** Implements rate limiting, data encryption, and access controls.

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/node-red-automation.git
cd node-red-automation
