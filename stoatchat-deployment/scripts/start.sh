#!/bin/bash

# Stoatchat Deployment Start Script
# This script initializes and starts all Stoatchat services

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
ENV_FILE="$PROJECT_ROOT/.env"

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

# Check if running in Replit
check_replit() {
    if [[ -n "${REPL_ID:-}" ]]; then
        log_info "Running in Replit environment"
        return 0
    else
        log_info "Running in standard environment"
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if .env file exists
    if [[ ! -f "$ENV_FILE" ]]; then
        log_warning ".env file not found. Creating from .env.example..."
        if [[ -f "$PROJECT_ROOT/.env.example" ]]; then
            cp "$PROJECT_ROOT/.env.example" "$ENV_FILE"
            log_warning "Please update $ENV_FILE with your configuration before continuing."
            read -p "Press Enter when you've updated the .env file..."
        else
            log_error ".env.example file not found. Cannot create .env file."
            exit 1
        fi
    fi
    
    log_info "Prerequisites check completed successfully"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    
    local dirs=(
        "$PROJECT_ROOT/data/mongodb"
        "$PROJECT_ROOT/data/redis"
        "$PROJECT_ROOT/data/rabbitmq"
        "$PROJECT_ROOT/data/uploads"
        "$PROJECT_ROOT/data/ssl"
        "$PROJECT_ROOT/logs"
        "$PROJECT_ROOT/config/nginx"
        "$PROJECT_ROOT/config/prometheus"
        "$PROJECT_ROOT/config/grafana"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        fi
    done
}

# Setup SSL certificates (if enabled)
setup_ssl() {
    local enable_ssl=${ENABLE_SSL:-false}
    
    if [[ "$enable_ssl" == "true" ]]; then
        log_info "Setting up SSL certificates..."
        
        if [[ ! -f "$PROJECT_ROOT/data/ssl/fullchain.pem" ]]; then
            log_warning "SSL certificates not found. Please configure SSL manually or use Let's Encrypt."
            log_info "You can use Let's Encrypt by running: certbot --nginx -d yourdomain.com"
        fi
    else
        log_info "SSL disabled. Using HTTP only."
    fi
}

# Initialize databases
initialize_databases() {
    log_info "Initializing databases..."
    
    # Wait for MongoDB to be ready
    log_info "Waiting for MongoDB to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" &> /dev/null; then
            log_info "MongoDB is ready"
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            log_error "MongoDB failed to start after $max_attempts attempts"
            exit 1
        fi
        
        log_info "Waiting for MongoDB... (Attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    # Initialize database collections and indexes
    log_info "Initializing database collections..."
    docker-compose exec -T mongodb mongosh stoatchat --eval "
        db.createCollection('users');
        db.createCollection('servers');
        db.createCollection('channels');
        db.createCollection('messages');
        db.createCollection('sessions');
        db.users.createIndex({ 'username': 1 }, { unique: true });
        db.users.createIndex({ 'email': 1 }, { unique: true });
        db.servers.createIndex({ 'owner': 1 });
        db.channels.createIndex({ 'server': 1 });
        db.messages.createIndex({ 'channel': 1, 'created_at': -1 });
    " || log_warning "Database initialization may have failed or collections already exist"
}

# Build and start services
start_services() {
    log_info "Building and starting Stoatchat services..."
    
    # Pull latest images
    log_info "Pulling Docker images..."
    docker-compose pull
    
    # Build custom images
    log_info "Building custom Docker images..."
    docker-compose build --parallel
    
    # Start services in dependency order
    log_info "Starting core services (databases)..."
    docker-compose up -d mongodb redis rabbitmq
    
    # Wait for core services to be ready
    log_info "Waiting for core services to initialize..."
    sleep 30
    
    # Initialize databases
    initialize_databases
    
    # Start backend services
    log_info "Starting backend services..."
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
}

# Show service status
show_status() {
    log_info "Showing service status..."
    docker-compose ps
    
    log_info "\nService URLs:"
    log_info "- Main Web App: http://localhost:3000"
    log_info "- Admin Panel: http://localhost:3001"
    log_info "- Landing Page: http://localhost:3002"
    log_info "- Developer Wiki: http://localhost:3003"
    log_info "- Backend API: http://localhost:8000"
    log_info "- WebSocket: ws://localhost:9000"
    log_info "- File Storage: http://localhost:5000"
    
    if [[ "${ENABLE_MONITORING:-false}" == "true" ]]; then
        log_info "- Grafana Dashboard: http://localhost:3004"
        log_info "- Prometheus: http://localhost:9090"
    fi
    
    log_info "- RabbitMQ Management: http://localhost:15672"
}

# Setup monitoring
setup_monitoring() {
    if [[ "${ENABLE_MONITORING:-false}" == "true" ]]; then
        log_info "Setting up monitoring..."
        
        # Create Prometheus configuration
        cat > "$PROJECT_ROOT/config/prometheus.yml" << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'stoatchat-backend'
    static_configs:
      - targets: ['stoatchat-backend:8000']
  - job_name: 'mongodb'
    static_configs:
      - targets: ['mongodb:27017']
  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
  - job_name: 'rabbitmq'
    static_configs:
      - targets: ['rabbitmq:15692']
EOF
        
        log_info "Monitoring configuration created"
    fi
}

# Main execution
main() {
    log_info "Starting Stoatchat deployment..."
    log_info "Project root: $PROJECT_ROOT"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Check if we're in Replit
    check_replit
    
    # Execute deployment steps
    check_prerequisites
    create_directories
    setup_ssl
    setup_monitoring
    start_services
    show_status
    
    log_info "Stoatchat deployment completed successfully!"
    log_info "You can now access your Stoatchat instance at the URLs shown above."
    
    # Keep container running in Replit
    if check_replit; then
        log_info "Running in Replit - keeping container active..."
        tail -f /dev/null
    fi
}

# Handle script interruption
trap 'log_warning "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"