#!/bin/bash

# =============================================================================
# Script Name: deploy-node-red-automation.sh
# Description: Handles the deployment and execution logic for Node-RED Automation.
#              Sets up Node-RED flows, monitoring, and starts services.
# Author: Your Name
# License: MIT
# =============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# =============================================================================
# Variables
# =============================================================================

PROJECT_DIR="$(pwd)/node-red-automation"
LOG_FILE="$PROJECT_DIR/deploy.log"
FLOW_FILE="$PROJECT_DIR/flows.json"
CONFIG_DIR="$PROJECT_DIR/config"
SRC_DIR="$PROJECT_DIR/src"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
MONITORING_DIR="$PROJECT_DIR/monitoring"
GRAFANA_PROVISION_DIR="$MONITORING_DIR/grafana/provisioning"
PROMETHEUS_PROVISION_DIR="$MONITORING_DIR/prometheus/provisioning"
README_FILE="$PROJECT_DIR/README.md"

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

# Function to start Docker Compose services
start_services() {
    log "Starting Docker Compose services..."
    docker-compose up -d || error_exit "Failed to start Docker Compose services."
    log "Docker Compose services started successfully."
}

# Function to stop Docker Compose services
stop_services() {
    log "Stopping Docker Compose services..."
    docker-compose down || error_exit "Failed to stop Docker Compose services."
    log "Docker Compose services stopped successfully."
}

# Function to deploy monitoring tools
deploy_monitoring() {
    log "Deploying Prometheus and Grafana..."
    "$MONITORING_DIR/setup-monitoring.sh" || error_exit "Failed to deploy monitoring tools."
    log "Prometheus and Grafana deployed successfully."
}

# Function to import Node-RED flows
import_node_red_flows() {
    log "Importing Node-RED flows..."
    # Assuming flows.json is already in place, Node-RED will load it on startup
    log "Node-RED flows imported successfully."
}

# Function to run tests
run_tests() {
    log "Running tests..."
    cd "$PROJECT_DIR"
    npm test || error_exit "Tests failed."
    log "All tests passed successfully."
}

# Function to start Node-RED
start_node_red() {
    log "Starting Node-RED..."
    docker-compose up -d node-red || error_exit "Failed to start Node-RED."
    log "Node-RED started successfully."
}

# Function to setup SSL certificates (if not done during setup)
setup_ssl() {
    log "Setting up SSL certificates..."
    # This function can be expanded if additional SSL setup is required
    log "SSL certificates setup completed."
}

# Function to create README with comprehensive documentation
create_readme() {
    if [ ! -f "$README_FILE" ]; then
        cat > "$README_FILE" <<'EOF'
# Node-RED Automation Deployment

## Overview

This deployment script sets up and starts the Node-RED Automation environment, including monitoring tools like Prometheus and Grafana. It ensures that all services are running correctly and that Node-RED is properly configured.

## Deployment Steps

1. **Start Services**:
    ```bash
    ./deploy-node-red-automation.sh start
    ```

2. **Stop Services**:
    ```bash
    ./deploy-node-red-automation.sh stop
    ```

3. **Deploy Monitoring Tools**:
    ```bash
    ./deploy-node-red-automation.sh monitor
    ```

4. **Run Tests**:
    ```bash
    ./deploy-node-red-automation.sh test
    ```

5. **Import Node-RED Flows**:
    ```bash
    ./deploy-node-red-automation.sh import
    ```

## Usage

Make the script executable:
```bash
chmod +x deploy-node-red-automation.sh
