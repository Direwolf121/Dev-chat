#!/bin/bash

# Stoatchat Deployment Logs Script
# This script shows logs from Stoatchat services

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

# Show logs for specific service
show_service_logs() {
    local service="$1"
    local follow="$2"
    
    log_info "Showing logs for service: $service"
    
    if [[ "$follow" == "true" ]]; then
        docker-compose logs -f "$service"
    else
        docker-compose logs --tail=100 "$service"
    fi
}

# Show all logs
show_all_logs() {
    local follow="$1"
    
    log_info "Showing logs for all services"
    
    if [[ "$follow" == "true" ]]; then
        docker-compose logs -f
    else
        docker-compose logs --tail=50
    fi
}

# List all services
list_services() {
    log_info "Available services:"
    docker-compose config --services | while read -r service; do
        echo "  - $service"
    done
}

# Show help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [SERVICE]

Show logs from Stoatchat services

Options:
  -f, --follow    Follow log output (like tail -f)
  -n, --tail NUM  Show last NUM lines (default: 100)
  -l, --list      List all available services
  --help          Show this help message

Examples:
  $0                    # Show logs from all services
  $0 -f                 # Follow logs from all services
  $0 stoatchat-backend  # Show logs from backend service
  $0 -f web-app         # Follow logs from web app
  $0 -n 50 mongodb      # Show last 50 lines from MongoDB
  $0 --list             # List all available services
EOF
}

# Main execution
main() {
    local service=""
    local follow=false
    local tail_lines=100
    local list=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--follow)
                follow=true
                shift
                ;;
            -n|--tail)
                tail_lines="$2"
                shift 2
                ;;
            -l|--list)
                list=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                service="$1"
                shift
                ;;
        esac
    done
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # List services if requested
    if [[ "$list" == "true" ]]; then
        list_services
        exit 0
    fi
    
    # Show logs
    if [[ -n "$service" ]]; then
        show_service_logs "$service" "$follow"
    else
        show_all_logs "$follow"
    fi
}

# Run main function
main "$@"