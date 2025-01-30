#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display error messages
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    error_exit "Node.js is not installed. Please install it from https://nodejs.org/"
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    error_exit "npm is not installed. Please install it along with Node.js."
fi

# Optional: Check for specific Node.js version
REQUIRED_NODE_VERSION="14.0.0"
INSTALLED_NODE_VERSION=$(node -v | sed 's/v//')
if [ "$(printf '%s\n' "$REQUIRED_NODE_VERSION" "$INSTALLED_NODE_VERSION" | sort -V | head -n1)" != "$REQUIRED_NODE_VERSION" ]; then 
    error_exit "Node.js version $REQUIRED_NODE_VERSION or higher is required. You have $INSTALLED_NODE_VERSION."
fi

# Set project directory
PROJECT_DIR="node-red-automation"

# Create project directory structure
mkdir -p "$PROJECT_DIR/flows" "$PROJECT_DIR/config" "$PROJECT_DIR/src"

# Navigate to project directory
cd "$PROJECT_DIR"

# Create a .env file for environment variables
cat > .env <<'EOF'
# Node-RED Environment Variables
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

# Install dotenv and other necessary packages
npm init -y
npm install node-red dotenv node-red-node-email node-red-node-slack node-red-contrib-github language-detect diff nodemailer

# Create package.json with required dependencies
cat > package.json <<'EOF'
{
  "name": "node-red-automation",
  "version": "1.0.0",
  "description": "Automated Node-RED workflow for AI-driven code analysis and deployment.",
  "main": "index.js",
  "scripts": {
    "start": "node-red --userDir ./flows --flows flow.json"
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
  "author": "Your Name",
  "license": "MIT"
}
EOF

# Create flow configuration with enhanced structure and comments
cat > flows/flow.json <<'EOF'
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
                "to": "$.env.GITHUB_REPO",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "github_token",
                "to": "$.env.GITHUB_TOKEN",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "initial_code_file",
                "to": "$.env.INITIAL_CODE_FILE",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "finalized_code_file",
                "to": "$.env.FINALIZED_CODE_FILE",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "processing_range_start",
                "to": "$.env.PROCESSING_RANGE_START",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "processing_range_end",
                "to": "$.env.PROCESSING_RANGE_END",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "range_increment",
                "to": "$.env.RANGE_INCREMENT",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "max_iterations_per_chatbot",
                "to": "$.env.MAX_ITERATIONS_PER_CHATBOT",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "openai_api_key",
                "to": "$.env.OPENAI_API_KEY",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "slack_channel",
                "to": "$.env.SLACK_CHANNEL",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "slack_token",
                "to": "$.env.SLACK_TOKEN",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "alert_email",
                "to": "$.env.ALERT_EMAIL",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "smtp_server",
                "to": "$.env.SMTP_SERVER",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "smtp_port",
                "to": "$.env.SMTP_PORT",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "smtp_user",
                "to": "$.env.SMTP_USER",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "smtp_pass",
                "to": "$.env.SMTP_PASS",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "chatbot_a_api_url",
                "to": "$.env.CHATBOT_A_API_URL",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "chatbot_a_api_key",
                "to": "$.env.CHATBOT_A_API_KEY",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "chatbot_b_api_url",
                "to": "$.env.CHATBOT_B_API_URL",
                "toType": "env"
            },
            {
                "t": "set",
                "p": "chatbot_b_api_key",
                "to": "$.env.CHATBOT_B_API_KEY",
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
        "func": "const fs = require('fs');\n\nconst start = parseInt(msg.processing_range_start, 10);\nconst end = parseInt(msg.processing_range_end, 10);\nconst increment = parseInt(msg.range_increment, 10);\nconst codeFile = msg.initial_code_file;\n\ntry {\n    const code = fs.readFileSync(codeFile, 'utf8');\n    const lines = code.split('\\n');\n    \n    // Initialize ranges array\n    msg.ranges = [];\n    let currentStart = start;\n    let currentEnd = end;\n\n    while (currentStart < lines.length) {\n        let adjustedStart = currentStart;\n        let adjustedEnd = currentEnd;\n        \n        // Adjust start to include full function\n        while (adjustedStart > 0 && !/\\b(def |class |async def )/.test(lines[adjustedStart - 1])) {\n            adjustedStart--;\n        }\n        \n        // Adjust end to include full function\n        while (adjustedEnd < lines.length && !/\\b(return|raise |except |finally:)/.test(lines[adjustedEnd])) {\n            adjustedEnd++;\n        }\n        \n        // Push the adjusted range\n        msg.ranges.push({ start: adjustedStart, end: adjustedEnd });\n\n        // Increment for next range\n        currentStart += increment;\n        currentEnd += increment;\n    }\n\n    // Initialize range processing index\n    msg.current_range_index = 0;\n\n    return msg;\n} catch (err) {\n    msg.error = 'Code extraction failed: ' + err.message;\n    return [null, msg];\n}",
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
        msg.max_iterations = parseInt(msg.max_iterations_per_chatbot, 10) * 2; // Assuming 2 chatbots
        msg.chatbots = [\n
            { name: "Chatbot A", api_url: msg.chatbot_a_api_url, api_key: msg.chatbot_a_api_key },\n
            { name: "Chatbot B", api_url: msg.chatbot_b_api_url, api_key: msg.chatbot_b_api_key }\n
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
    const prompts = [\n
        'Check this code for errors, make sure it is bug free, add any functionality you think is important.',\n
        'Identify all logic flaws.',\n
        'Optimize performance bottlenecks.',\n
        'Enhance security best practices.',\n
        'Refactor redundant code.',\n
        'Check compliance with coding standards.'\n
    ];\n
    \n
    const randomPrompt = prompts[Math.floor(Math.random() * prompts.length)];\n
    msg.prompt = \`\${randomPrompt}\\n\\n\${msg.language || 'Python'} code:\\n\${msg.code_chunk}\\n\\nContext:\\n\${msg.context || ''}\`;\n
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
    const chatbot = msg.chatbots[msg.current_chatbot_index % msg.chatbots.length];\n
    msg.url = chatbot.api_url;\n
    msg.headers.Authorization = \`Bearer \${chatbot.api_key}\`;\n
    msg.body = JSON.stringify({\n
        model: "gpt-4",\n
        messages: [\n
            { role: "system", content: "You are a senior code reviewer." },\n
            { role: "user", content: msg.prompt }\n
        ]\n
    });\n
    \n
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
    if (msg.iteration < msg.max_iterations) {
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
    const fs = require('fs');
    
    // Reset processing_range_start and processing_range_end for next batch
    msg.processing_range_start += parseInt(msg.range_increment, 10);
    msg.processing_range_end += parseInt(msg.range_increment, 10);
    
    // Save updated range to .env or a config file if needed
    // Alternatively, manage ranges within the flow itself
    
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
    
    const transporter = nodemailer.createTransport({
        host: msg.smtp_server,
        port: parseInt(msg.smtp_port, 10),
        secure: false, // true for 465, false for other ports
        auth: {
            user: msg.smtp_user,
            pass: msg.smtp_pass
        }
    });
    
    const mailOptions = {
        from: msg.smtp_user,
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

# Create a README file with setup instructions
cat > README.md <<'EOF'
# Node-RED Automation

## Description
Automated Node-RED workflow for AI-driven code analysis, validation, and deployment to GitHub with notifications via Slack and email alerts.

## Setup Instructions

1. **Configure Environment Variables:**
   - Open the `.env` file located in the `node-red-automation` directory.
   - Fill in the required values for GitHub, OpenAI, Email, Slack, and Chatbot configurations.
   - Ensure that the `.env` file is kept secure and **not** committed to version control.

2. **Install Dependencies:**
   ```bash
   npm install
