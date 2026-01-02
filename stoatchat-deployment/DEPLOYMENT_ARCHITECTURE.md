# Stoatchat Deployment Architecture

## Overview
Stoatchat is a comprehensive chat platform consisting of multiple interconnected services. This document outlines the architecture and deployment strategy for self-hosting all components.

## Repository Structure

### 1. Main Web Application (for-legacy-web)
- **Language**: TypeScript
- **Framework**: Preact + Vite
- **Purpose**: Legacy web client for Stoat chat
- **Port**: 3000 (default)
- **Dependencies**: Node.js 16+, Yarn

### 2. Backend Service (stoatchat)
- **Language**: Rust
- **Framework**: Custom Rust backend (Bonfire)
- **Purpose**: Core backend API and services
- **Port**: 8000 (API), 9000 (WebSocket)
- **Dependencies**: Rust 1.70+, MongoDB, Redis, RabbitMQ

### 3. Admin Panel (service-admin-panel)
- **Language**: TypeScript
- **Framework**: React/Next.js
- **Purpose**: Administrative interface for content management
- **Port**: 3001
- **Dependencies**: Node.js 16+, Yarn

### 4. Landing Page (stoat.chat)
- **Language**: Astro
- **Framework**: Astro.js
- **Purpose**: Marketing and informational website
- **Port**: 3002
- **Dependencies**: Node.js 16+, Yarn

### 5. Developer Wiki (developer-wiki)
- **Language**: CSS/HTML
- **Framework**: Static site
- **Purpose**: Developer documentation
- **Port**: 3003
- **Dependencies**: Simple HTTP server

### 6. Desktop Application (for-desktop)
- **Language**: TypeScript
- **Framework**: Electron
- **Purpose**: Desktop client for Windows/macOS/Linux
- **Port**: N/A (Desktop app)
- **Dependencies**: Node.js, Electron

### 7. Android Application (for-android)
- **Language**: Kotlin
- **Framework**: Native Android
- **Purpose**: Android mobile client
- **Port**: N/A (Mobile app)
- **Dependencies**: Android SDK, Kotlin

## System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Landing Page  │    │  Main Web App   │    │  Admin Panel    │
│   (stoat.chat)  │    │ (for-legacy-web)│    │(service-admin) │
│   Port: 3002    │    │   Port: 3000    │    │   Port: 3001    │
└────────┬────────┘    └────────┬────────┘    └────────┬────────┘
         │                      │                       │
         └──────────────────────┼───────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │     Load Balancer     │
                    │    (Nginx/Traefik)    │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │    Backend Service    │
                    │     (stoatchat)       │
                    │   Port: 8000/9000     │
                    └───────────┬───────────┘
                                │
            ┌───────────────────┼───────────────────┐
            │                   │                   │
    ┌───────▼───────┐   ┌───────▼───────┐   ┌───────▼───────┐
    │   MongoDB     │   │     Redis     │   │   RabbitMQ    │
    │   Database    │   │    Cache      │   │   Message     │
    │    Port:      │   │   Port:       │   │   Broker      │
    │   27017       │   │   6379        │   │   Port:       │
    └───────────────┘   └───────────────┘   │   5672        │
                                            └───────────────┘
```

## Deployment Components

### Required Services
1. **Reverse Proxy**: Nginx/Traefik for routing
2. **Database**: MongoDB for primary data storage
3. **Cache**: Redis for session management and caching
4. **Message Queue**: RabbitMQ for async processing
5. **Storage**: File storage service (Autumn)
6. **CDN**: Static asset delivery
7. **SSL/TLS**: Certificate management

### Optional Services
1. **Monitoring**: Prometheus + Grafana
2. **Logging**: ELK stack or similar
3. **Backup**: Automated database backups
4. **CI/CD**: GitHub Actions or similar

## Environment Variables

### Backend Service (stoatchat)
```env
# Database
MONGODB_URI=mongodb://localhost:27017/stoatchat
REDIS_URI=redis://localhost:6379

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
WS_HOST=0.0.0.0
WS_PORT=9000

# Security
JWT_SECRET=your-jwt-secret-key
VAPID_PRIVATE_KEY=your-vapid-private-key
VAPID_PUBLIC_KEY=your-vapid-public-key

# External Services
AUTUMN_URL=http://localhost:5000
JANUARY_URL=http://localhost:5001
GIFBOX_URL=http://localhost:5002

# Features
ENABLE_REGISTRATION=true
ENABLE_INVITES=false
```

### Web Applications
```env
# Common
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:9000
VITE_AUTUMN_URL=http://localhost:5000

# Main Web App
VITE_APP_NAME=Stoatchat
VITE_APP_DESCRIPTION=Self-hosted Stoatchat instance
```

## Deployment Strategy

### 1. Infrastructure Setup
- Set up VPS/cloud instance (minimum 4GB RAM, 2 vCPUs)
- Install Docker and Docker Compose
- Configure firewall and security groups
- Set up domain and DNS records

### 2. Database Setup
- Deploy MongoDB with persistent storage
- Configure Redis for caching
- Set up RabbitMQ for message queuing
- Initialize database with required collections

### 3. Backend Deployment
- Build Rust backend from source
- Configure environment variables
- Set up systemd service or Docker container
- Configure logging and monitoring

### 4. Frontend Deployment
- Build static assets for each web application
- Configure Nginx for serving and reverse proxy
- Set up SSL certificates with Let's Encrypt
- Configure CDN for static assets

### 5. Mobile/Desktop Apps
- Configure build pipelines for mobile apps
- Set up code signing for mobile releases
- Configure auto-updater for desktop app
- Set up distribution channels

## Security Considerations

### 1. Network Security
- Use HTTPS for all communications
- Implement rate limiting
- Configure CORS properly
- Use Web Application Firewall (WAF)

### 2. Authentication
- Implement JWT-based authentication
- Use secure session management
- Enable 2FA for admin accounts
- Regular security audits

### 3. Data Protection
- Encrypt data at rest and in transit
- Regular database backups
- Secure file storage
- GDPR compliance measures

## Monitoring and Maintenance

### 1. Health Checks
- API endpoint monitoring
- Database connection checks
- Resource usage monitoring
- Error rate tracking

### 2. Logging
- Centralized logging system
- Application log aggregation
- Error tracking and alerting
- Performance monitoring

### 3. Backup Strategy
- Daily database backups
- Configuration backups
- Disaster recovery plan
- Regular restore testing

## Scaling Considerations

### 1. Horizontal Scaling
- Load balancer configuration
- Multiple backend instances
- Database read replicas
- CDN for static content

### 2. Vertical Scaling
- Resource monitoring
- Performance optimization
- Database indexing
- Caching strategies

### 3. Auto-scaling
- Container orchestration
- Resource-based scaling
- Traffic-based scaling
- Cost optimization

## Cost Optimization

### 1. Resource Management
- Right-sizing instances
- Spot instances for non-critical services
- Resource scheduling
- Cost monitoring

### 2. Storage Optimization
- Database compression
- File deduplication
- CDN caching
- Archive old data

This architecture provides a comprehensive foundation for self-hosting Stoatchat with all its components.