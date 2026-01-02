#!/bin/bash

# Stoatchat Deployment Stop Script
# This script stops all Stoatchat services

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

# Main execution
main() {
    log_info "Stopping Stoatchat services..."
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Stop all services
    log_info "Stopping Docker Compose services..."
    docker-compose down --remove-orphans
    
    # Optional: Remove volumes (careful with this!)
    if [[ "${1:-}" == "--clean" ]]; then
        log_warning "Removing all Docker volumes (this will delete all data!)..."
        docker-compose down -v --remove-orphans
        log_info "All volumes have been removed"
    fi
    
    log_info "Stoatchat services stopped successfully"
}

# Show help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Stop Stoatchat services

Options:
  --clean    Remove all Docker volumes (DELETES ALL DATA!)
  --help     Show this help message

Examples:
  $0                    # Stop services normally
  $0 --clean           # Stop services and remove all data
  $0 --help            # Show help
EOF
}

# Handle arguments
case "${1:-}" in
    --help)
        show_help
        exit 0
        ;;
    --clean)
        log_warning "This will remove ALL data including databases!"
        read -p "Are you sure you want to continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            main --clean
        else
            log_info "Operation cancelled"
            exit 0
        fi
        ;;
    *)
        main
        ;;
esac