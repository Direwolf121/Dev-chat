#!/bin/bash

# Stoatchat Complete Setup Script
# This script automates the entire deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"

# Logging functions
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

log_step() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] STEP:${NC} $1"
}

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "  _____ _        _         _____ _           _   _             "
    echo " / ____| |      | |       / ____| |         | | (_)            "
    echo "| (___ | |_ __ _| |_ ___ | |    | |__   ___ | |_ _  ___  _ __  "
    echo " \___ \| __/ _\` | __/ _ \| |    | '_ \ / _ \| __| |/ _ \| '_ \ "
    echo " ____) | || (_| | ||  __/| |____| | | | (_) | |_| | (_) | | | |"
    echo "|_____/ \__\__,_|\__\___| \_____|_| |_|\___/ \__|_|\___/|_| |_||"
    echo -e "${NC}"
    echo "        Self-Hosted Deployment Setup Script"
    echo "        ====================================="
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if running in Replit
    if [[ -n "${REPL_ID:-}" ]]; then
        log_info "Running in Replit environment"
        IN_REPLIT=true
    else
        log_info "Running in standard environment"
        IN_REPLIT=false
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        if [[ "$IN_REPLIT" == "false" ]]; then
            echo "Install Docker: https://docs.docker.com/get-docker/"
        else
            echo "Docker should be available in Replit. Please check your Repl configuration."
        fi
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        if [[ "$IN_REPLIT" == "false" ]]; then
            echo "Install Docker Compose: https://docs.docker.com/compose/install/"
        fi
        exit 1
    fi
    
    # Check available disk space (need at least 2GB)
    local available_space=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | sed 's/G//;s/M//')
    local unit=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | sed 's/[0-9.]*//')
    
    if [[ "$unit" == "M" ]] || (( $(echo "$available_space < 2" | bc -l) )); then
        log_warning "Low disk space available. At least 2GB is recommended."
    fi
    
    log_info "Prerequisites check completed successfully"
}

# Interactive configuration
interactive_config() {
    log_step "Interactive Configuration"
    echo ""
    
    # Check if .env file exists
    if [[ -f "$PROJECT_ROOT/.env" ]]; then
        log_warning ".env file already exists"
        read -p "Do you want to recreate it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Using existing .env file"
            return 0
        fi
    fi
    
    # Create .env file
    log_info "Creating .env file..."
    
    # Generate random secrets
    JWT_SECRET=$(openssl rand -base64 64 2>/dev/null || head -c 64 /dev/urandom | base64)
    MONGO_PASSWORD=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
    REDIS_PASSWORD=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
    RABBITMQ_PASSWORD=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
    ADMIN_API_KEY=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
    
    # Interactive prompts
    echo ""
    log_info "Please answer the following questions:"
    echo ""
    
    # Domain name
    if [[ "$IN_REPLIT" == "true" ]]; then
        DOMAIN_NAME="${REPL_SLUG}.repl.co"
        log_info "Using Replit domain: $DOMAIN_NAME"
    else
        read -p "Enter your domain name (or press Enter for localhost): " DOMAIN_NAME
        if [[ -z "$DOMAIN_NAME" ]]; then
            DOMAIN_NAME="localhost"
        fi
    fi
    
    # Enable SSL
    if [[ "$DOMAIN_NAME" != "localhost" ]] && [[ "$DOMAIN_NAME" != *".repl.co" ]]; then
        read -p "Enable SSL/HTTPS? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ENABLE_SSL="true"
            read -p "Enter email for Let's Encrypt: " LETSENCRYPT_EMAIL
        else
            ENABLE_SSL="false"
        fi
    else
        ENABLE_SSL="false"
    fi
    
    # Enable registration
    read -p "Enable user registration? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        ENABLE_REGISTRATION="true"
    else
        ENABLE_REGISTRATION="false"
    fi
    
    # Create .env file
    cat > "$PROJECT_ROOT/.env" << EOF
# Stoatchat Environment Configuration
# Generated on $(date)

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

# JWT Secret for authentication
JWT_SECRET=$JWT_SECRET

# VAPID keys for push notifications (generate if needed)
VAPID_PRIVATE_KEY=
VAPID_PUBLIC_KEY=

# Admin API key for admin panel
ADMIN_API_KEY=$ADMIN_API_KEY

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

# MongoDB Configuration
MONGO_ROOT_USERNAME=stoatchat
MONGO_ROOT_PASSWORD=$MONGO_PASSWORD
MONGO_DATABASE=stoatchat

# Redis Configuration
REDIS_PASSWORD=$REDIS_PASSWORD

# RabbitMQ Configuration
RABBITMQ_USER=stoatchat
RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD

# =============================================================================
# DOMAIN CONFIGURATION
# =============================================================================

# Your domain name
DOMAIN_NAME=$DOMAIN_NAME

# SSL Configuration
ENABLE_SSL=$ENABLE_SSL
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL:-}

# =============================================================================
# FEATURE FLAGS
# =============================================================================

# Enable user registration
ENABLE_REGISTRATION=$ENABLE_REGISTRATION

# Enable invite-only registration
ENABLE_INVITES=false

# =============================================================================
# EXTERNAL SERVICES
# =============================================================================

# S3 Configuration for file storage (optional)
AUTUMN_S3_REGION=us-east-1
AUTUMN_S3_ENDPOINT=
AUTUMN_S3_BUCKET=stoatchat-uploads
AUTUMN_S3_ACCESS_KEY=
AUTUMN_S3_SECRET_KEY=

# =============================================================================
# MONITORING
# =============================================================================

# Grafana admin password
GRAFANA_PASSWORD=admin

# =============================================================================
# DEVELOPMENT CONFIGURATION
# =============================================================================

# Development mode
DEVELOPMENT_MODE=true

# Debug mode
DEBUG=false

# Log level
LOG_LEVEL=info
EOF
    
    log_info ".env file created successfully!"
    echo ""
}

# Setup directory structure
setup_directories() {
    log_step "Setting up directory structure..."
    
    local dirs=(
        "$PROJECT_ROOT/data/mongodb"
        "$PROJECT_ROOT/data/redis"
        "$PROJECT_ROOT/data/rabbitmq"
        "$PROJECT_ROOT/data/uploads"
        "$PROJECT_ROOT/data/ssl"
        "$PROJECT_ROOT/logs"
        "$PROJECT_ROOT/config/nginx/sites"
        "$PROJECT_ROOT/config/prometheus"
        "$PROJECT_ROOT/config/grafana/dashboards"
        "$PROJECT_ROOT/config/grafana/datasources"
        "$PROJECT_ROOT/backups"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        fi
    done
}

# Setup SSL certificates
setup_ssl() {
    local enable_ssl=${ENABLE_SSL:-false}
    
    if [[ "$enable_ssl" == "true" ]]; then
        log_step "Setting up SSL certificates..."
        
        if [[ ! -f "$PROJECT_ROOT/data/ssl/fullchain.pem" ]]; then
            if [[ "$IN_REPLIT" == "true" ]]; then
                log_info "Replit provides automatic SSL for custom domains"
                log_info "No manual certificate setup needed"
            else
                log_info "Generating self-signed SSL certificates for development..."
                
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout "$PROJECT_ROOT/data/ssl/privkey.pem" \
                    -out "$PROJECT_ROOT/data/ssl/fullchain.pem" \
                    -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME:-localhost}"
                
                log_info "Self-signed certificates generated"
                log_warning "Replace with Let's Encrypt certificates for production"
            fi
        fi
    else
        log_info "SSL disabled - using HTTP only"
    fi
}

# Create monitoring configuration
setup_monitoring() {
    log_step "Setting up monitoring configuration..."
    
    # Prometheus configuration
    cat > "$PROJECT_ROOT/config/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'stoatchat-backend'
    static_configs:
      - targets: ['stoatchat-backend:8000']
    metrics_path: /metrics
    scrape_interval: 15s
    
  - job_name: 'mongodb'
    static_configs:
      - targets: ['mongodb:27017']
    
  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
    
  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx:80']
EOF
    
    # Grafana datasource configuration
    cat > "$PROJECT_ROOT/config/grafana/datasources/prometheus.yml" << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF
    
    log_info "Monitoring configuration created"
}

# Pull Docker images
pull_images() {
    log_step "Pulling Docker images..."
    
    cd "$PROJECT_ROOT"
    
    # Pull base images first
    log_info "Pulling base images..."
    docker-compose pull
    
    log_info "Docker images pulled successfully"
}

# Build custom images
build_images() {
    log_step "Building custom Docker images..."
    
    cd "$PROJECT_ROOT"
    
    # Build all custom images
    docker-compose build --parallel
    
    log_info "Custom Docker images built successfully"
}

# Start services
start_services() {
    log_step "Starting Stoatchat services..."
    
    cd "$PROJECT_ROOT"
    
    # Start core infrastructure
    log_info "Starting core infrastructure (MongoDB, Redis, RabbitMQ)..."
    docker-compose up -d mongodb redis rabbitmq
    
    # Wait for services to be ready
    log_info "Waiting for core services to initialize..."
    sleep 30
    
    # Start backend services
    log_info "Starting backend services (Autumn, January, Gifbox)..."
    docker-compose up -d autumn january gifbox
    
    # Wait for backend services
    log_info "Waiting for backend services to initialize..."
    sleep 20
    
    # Start main backend
    log_info "Starting main backend service..."
    docker-compose up -d stoatchat-backend
    
    # Wait for backend to be ready
    log_info "Waiting for backend service to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f http://localhost:8000/ &> /dev/null; then
            log_info "Backend service is ready"
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            log_warning "Backend service may not be fully ready, but continuing..."
            break
        fi
        
        log_info "Waiting for backend service... (Attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    # Start frontend services
    log_info "Starting frontend services..."
    docker-compose up -d web-app admin-panel landing-page developer-wiki
    
    # Start reverse proxy
    log_info "Starting reverse proxy..."
    docker-compose up -d nginx
    
    # Start monitoring (optional)
    if [[ "${ENABLE_MONITORING:-false}" == "true" ]]; then
        log_info "Starting monitoring services..."
        docker-compose up -d prometheus grafana
    fi
    
    log_info "All services started successfully!"
}

# Show service status
show_status() {
    log_step "Service Status"
    echo ""
    
    # Show running containers
    docker-compose ps
    
    echo ""
    log_info "Access your Stoatchat instance at:"
    echo ""
    
    if [[ "$IN_REPLIT" == "true" ]]; then
        log_info "🌐 Main Web App: https://${REPL_SLUG}.repl.co"
        log_info "🛠️  Admin Panel: https://${REPL_SLUG}.repl.co/admin"
        log_info "📄 Landing Page: https://${REPL_SLUG}.repl.co"
        log_info "📚 Developer Wiki: https://${REPL_SLUG}.repl.co/docs"
        log_info "🔗 API Endpoint: https://${REPL_SLUG}.repl.co/api"
        log_info "⚡ WebSocket: wss://${REPL_SLUG}.repl.co/ws"
    else
        log_info "🌐 Main Web App: http://localhost:3000"
        log_info "🛠️  Admin Panel: http://localhost:3001"
        log_info "📄 Landing Page: http://localhost:3002"
        log_info "📚 Developer Wiki: http://localhost:3003"
        log_info "🔗 API Endpoint: http://localhost:8000"
        log_info "⚡ WebSocket: ws://localhost:9000"
        log_info "💾 File Storage: http://localhost:5000"
        log_info "🖼️  Image Processing: http://localhost:5001"
        log_info "🎬 GIF Processing: http://localhost:5002"
    fi
    
    echo ""
    log_info "🔐 Default Credentials:"
    log_info "   Admin API Key: Check your .env file"
    log_info "   Grafana: admin/admin (change immediately)"
    log_info "   RabbitMQ: stoatchat/$RABBITMQ_PASSWORD"
}

# Setup complete message
setup_complete() {
    echo ""
    log_info "🎉 Setup completed successfully!"
    echo ""
    log_info "Next steps:"
    echo ""
    log_info "1. Review your .env file and update any settings"
    log_info "2. Start services with: ./scripts/start.sh"
    log_info "3. Stop services with: ./scripts/stop.sh"
    log_info "4. View logs with: ./scripts/logs.sh"
    echo ""
    log_info "For more information, see:"
    log_info "- README.md - General deployment guide"
    log_info "- REPLIT_DEPLOYMENT_GUIDE.md - Replit-specific guide"
    log_info "- DEPLOYMENT_ARCHITECTURE.md - Technical architecture"
    echo ""
    
    if [[ "$IN_REPLIT" == "true" ]]; then
        log_info "Running in Replit - keeping container active..."
        tail -f /dev/null
    fi
}

# Main execution
main() {
    print_banner
    
    # Execute setup steps
    check_prerequisites
    interactive_config
    setup_directories
    setup_ssl
    setup_monitoring
    pull_images
    
    # Ask if user wants to start services immediately
    echo ""
    read -p "Do you want to start all services now? (Y/n) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        build_images
        start_services
        show_status
    else
        log_info "You can start services later with: ./scripts/start.sh"
    fi
    
    setup_complete
}

# Handle script interruption
trap 'log_warning "Setup interrupted"; exit 1' INT TERM

# Show help
show_help() {
    cat << EOF
Stoatchat Complete Setup Script

Usage: $0 [OPTIONS]

Options:
  --help     Show this help message
  --version  Show version information
  --non-interactive  Run in non-interactive mode (uses defaults)

Examples:
  $0                    # Run interactive setup
  $0 --help            # Show help
  $0 --non-interactive # Run automated setup

EOF
}

# Handle arguments
case "${1:-}" in
    --help)
        show_help
        exit 0
        ;;
    --version)
        echo "Stoatchat Setup Script v1.0.0"
        exit 0
        ;;
    --non-interactive)
        log_info "Running in non-interactive mode"
        # Set default values for non-interactive mode
        export JWT_SECRET="$(openssl rand -base64 64 2>/dev/null || head -c 64 /dev/urandom | base64)"
        export MONGO_PASSWORD="$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)"
        export REDIS_PASSWORD="$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)"
        export RABBITMQ_PASSWORD="$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)"
        export ADMIN_API_KEY="$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)"
        export DOMAIN_NAME="${DOMAIN_NAME:-localhost}"
        export ENABLE_SSL="false"
        export ENABLE_REGISTRATION="true"
        
        # Skip interactive config
        print_banner
        check_prerequisites
        setup_directories
        setup_ssl
        setup_monitoring
        pull_images
        build_images
        start_services
        show_status
        setup_complete
        ;;
    *)
        main
        ;;
esac