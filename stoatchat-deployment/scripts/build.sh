#!/bin/bash

# Stoatchat Deployment Build Script
# This script builds all necessary components for deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Build Docker images
build_docker_images() {
    log_info "Building Docker images..."
    
    cd "$PROJECT_ROOT"
    
    # Pull base images
    log_info "Pulling base Docker images..."
    docker-compose pull
    
    # Build custom images
    log_info "Building custom Docker images..."
    docker-compose build --parallel
    
    log_info "Docker images built successfully"
}

# Setup configuration files
setup_config() {
    log_info "Setting up configuration files..."
    
    # Create directories if they don't exist
    mkdir -p "$PROJECT_ROOT/data"/{mongodb,redis,rabbitmq,uploads,ssl}
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/config"/{nginx,prometheus,grafana}
    
    # Copy default configuration files if they don't exist
    if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
        if [[ -f "$PROJECT_ROOT/.env.example" ]]; then
            cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
            log_warning ".env file created from .env.example. Please review and update it."
        else
            log_error ".env.example file not found!"
            exit 1
        fi
    fi
    
    log_info "Configuration setup completed"
}

# Pre-flight checks
preflight_checks() {
    log_info "Running pre-flight checks..."
    
    # Check disk space
    local available_space=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | sed 's/G//')
    if (( $(echo "$available_space < 5" | bc -l) )); then
        log_warning "Low disk space available: ${available_space}GB. At least 5GB is recommended."
    fi
    
    # Check memory
    local available_memory=$(free -g | awk 'NR==2{print $7}')
    if [[ $available_memory -lt 4 ]]; then
        log_warning "Low memory available: ${available_memory}GB. At least 4GB is recommended."
    fi
    
    # Check if required ports are available
    local required_ports=(3000 3001 3002 3003 8000 9000 5000 5001 5002)
    for port in "${required_ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            log_warning "Port $port is already in use. This may cause conflicts."
        fi
    done
    
    log_info "Pre-flight checks completed"
}

# Build frontend applications
build_frontends() {
    log_info "Building frontend applications..."
    
    # This would typically involve building the individual repositories
    # For now, we'll use the Docker build process
    
    log_info "Frontend applications will be built as part of Docker build process"
}

# Setup SSL certificates (if enabled)
setup_ssl() {
    local enable_ssl=${ENABLE_SSL:-false}
    
    if [[ "$enable_ssl" == "true" ]]; then
        log_info "Setting up SSL certificates..."
        
        # In production, you would use Let's Encrypt here
        # For development, we'll use self-signed certificates
        
        if [[ ! -f "$PROJECT_ROOT/data/ssl/fullchain.pem" ]]; then
            log_info "Generating self-signed SSL certificates for development..."
            
            mkdir -p "$PROJECT_ROOT/data/ssl"
            
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout "$PROJECT_ROOT/data/ssl/privkey.pem" \
                -out "$PROJECT_ROOT/data/ssl/fullchain.pem" \
                -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
            
            log_info "Self-signed certificates generated"
        fi
    else
        log_info "SSL disabled - using HTTP only"
    fi
}

# Main build process
main() {
    log_info "Starting Stoatchat build process..."
    
    cd "$PROJECT_ROOT"
    
    # Execute build steps
    preflight_checks
    setup_config
    build_docker_images
    build_frontends
    setup_ssl
    
    log_info "Build process completed successfully!"
    log_info "You can now start the services with: ./scripts/start.sh"
}

# Handle script interruption
trap 'log_warning "Build process interrupted"; exit 1' INT TERM

# Run main function
main "$@"