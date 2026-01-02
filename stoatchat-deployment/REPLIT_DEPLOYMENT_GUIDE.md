# Stoatchat Replit Deployment Guide

This guide will help you deploy the complete Stoatchat platform on Replit, including all 7 repositories and services.

## 🚀 Quick Start (5 minutes)

### Step 1: Import to Replit

1. **Create a new Replit**
   - Go to [replit.com](https://replit.com)
   - Click "Create Repl"
   - Choose "Import from GitHub"
   - Use this repository URL

2. **Configure as Docker Repl**
   - Set Repl type to "Docker"
   - Choose "Linux" as OS
   - Click "Create Repl"

### Step 2: Configure Secrets

1. **Open Replit Secrets**
   - Go to Tools → Secrets
   - Add the following secrets:

```env
# Required Secrets
JWT_SECRET=your-super-secret-jwt-key-here
MONGO_ROOT_PASSWORD=secure-mongodb-password-123
REDIS_PASSWORD=secure-redis-password-123
RABBITMQ_PASSWORD=secure-rabbitmq-password-123
ADMIN_API_KEY=admin-secret-key-123

# Optional Secrets
DOMAIN_NAME=your-repl-name.repl.co
ENABLE_SSL=false
ENABLE_REGISTRATION=true
```

2. **Generate Secure Secrets**
   - Use a password generator for each secret
   - Make them at least 32 characters long
   - Use different secrets for each service

### Step 3: Deploy

1. **Run the Deployment**
   ```bash
   ./scripts/start.sh
   ```

2. **Wait for Completion**
   - First deployment takes 5-10 minutes
   - Watch the console for progress
   - All services will start automatically

### Step 4: Access Your Instance

Replit will provide public URLs for your services:

- **Main App**: `https://your-repl-name.repl.co`
- **Admin Panel**: `https://your-repl-name.repl.co/admin`
- **Landing Page**: `https://your-repl-name.repl.co` (main domain)
- **API**: `https://your-repl-name.repl.co/api`
- **WebSocket**: `wss://your-repl-name.repl.co/ws`

## 📋 Repository Setup

### 1. Main Components (Auto-included)

This deployment includes all repositories:

- ✅ **for-legacy-web** - Main web application (TypeScript/React)
- ✅ **stoatchat** - Backend API server (Rust)
- ✅ **service-admin-panel** - Admin interface (Next.js)
- ✅ **stoat.chat** - Landing page (Astro)
- ✅ **developer-wiki** - Documentation (Static HTML)
- ✅ **for-desktop** - Desktop app (Electron) - *Build configuration*
- ✅ **for-android** - Android app (Kotlin) - *Build configuration*

### 2. Individual Repository Deployment

If you want to deploy individual repositories as separate Repls:

#### Backend Service (stoatchat)
```bash
# In a new Replit
# Import: https://github.com/stoatchat/stoatchat
# Type: Docker
# Secrets:
#   MONGODB_URI=mongodb://localhost:27017/stoatchat
#   REDIS_URI=redis://localhost:6379
```

#### Web App (for-legacy-web)
```bash
# In a new Replit
# Import: https://github.com/stoatchat/for-legacy-web
# Type: Node.js
# Install: yarn install
# Run: yarn dev
```

#### Admin Panel (service-admin-panel)
```bash
# In a new Replit
# Import: https://github.com/stoatchat/service-admin-panel
# Type: Node.js
# Install: npm install
# Run: npm run dev
```

## 🔧 Advanced Configuration

### Custom Domain Setup

1. **Add Custom Domain in Replit**
   - Go to Settings → Custom Domain
   - Add your domain
   - Follow DNS configuration instructions

2. **Update Environment**
   ```env
   DOMAIN_NAME=yourdomain.com
   ENABLE_SSL=true
   ```

3. **SSL Certificates**
   - Replit provides automatic SSL for custom domains
   - No additional configuration needed

### Scaling Resources

Replit provides different resource tiers:

| Tier | RAM | vCPUs | Storage | Concurrent Users |
|------|-----|-------|---------|------------------|
| Free | 512MB | 0.5 | 500MB | 10-20 |
| Hacker | 2GB | 2 | 5GB | 50-100 |
| Pro | 4GB | 4 | 10GB | 200-500 |

**Recommendation**: Use Hacker or Pro for production use.

### Database Management

#### Access MongoDB
```bash
# Connect to MongoDB container
docker-compose exec mongodb mongosh stoatchat

# Backup database
docker-compose exec mongodb mongodump --out /backup/$(date +%Y%m%d)
```

#### Database Indexes
```javascript
// Create performance indexes
db.messages.createIndex({"channel": 1, "created_at": -1})
db.users.createIndex({"username": 1})
db.servers.createIndex({"owner": 1})
```

### Environment Variables Reference

#### Required Variables
```env
# Security
JWT_SECRET=64-character-random-string
ADMIN_API_KEY=32-character-random-string

# Database
MONGO_ROOT_PASSWORD=32-character-random-string
REDIS_PASSWORD=32-character-random-string
RABBITMQ_PASSWORD=32-character-random-string

# Instance
DOMAIN_NAME=your-repl-name.repl.co
```

#### Optional Variables
```env
# Features
ENABLE_REGISTRATION=true
ENABLE_INVITES=false
ENABLE_MONITORING=true

# External Services
AUTUMN_S3_REGION=us-east-1
AUTUMN_S3_BUCKET=stoatchat-uploads

# Limits
MAX_FILE_SIZE=52428800
MAX_SERVERS_PER_USER=100
```

## 📊 Monitoring & Logs

### Built-in Monitoring

Access monitoring dashboards:

- **Grafana**: `https://your-repl-name.repl.co/grafana` (admin/admin)
- **Prometheus**: `https://your-repl-name.repl.co/prometheus`
- **RabbitMQ**: `https://your-repl-name.repl.co/rabbitmq` (stoatchat/stoatchat_mq_pass)

### Log Management

```bash
# View all logs
./scripts/logs.sh

# Follow specific service
./scripts/logs.sh -f stoatchat-backend

# Show recent logs
./scripts/logs.sh -n 100
```

### Performance Metrics

Monitor these key metrics:

- **Response Time**: < 200ms for API calls
- **Error Rate**: < 1% for all services
- **Memory Usage**: < 80% of available RAM
- **CPU Usage**: < 70% average
- **Active Connections**: WebSocket connections

## 🔄 Updates & Maintenance

### Updating Services

```bash
# Pull latest images
docker-compose pull

# Rebuild with new images
docker-compose up --build -d

# Check service status
docker-compose ps
```

### Backup Strategy

```bash
# Automated daily backup
0 2 * * * docker-compose exec mongodb mongodump --out /backup/$(date +%Y%m%d)

# Manual backup
./scripts/backup.sh
```

### Security Updates

1. **Regular Updates**
   - Update base images monthly
   - Check for security advisories
   - Monitor dependency vulnerabilities

2. **Password Rotation**
   - Change secrets every 90 days
   - Use Replit Secrets management
   - Update all connected services

## 🚀 Production Deployment

### Pre-Production Checklist

- [ ] All secrets are properly configured
- [ ] Custom domain is set up
- [ ] SSL is enabled and working
- [ ] Monitoring is configured
- [ ] Backup strategy is in place
- [ ] Performance testing completed
- [ ] Security review passed

### Scaling for Production

1. **Upgrade Replit Plan**
   - Hacker plan for small communities
   - Pro plan for larger communities

2. **Optimize Performance**
   - Enable CDN for static assets
   - Configure database indexing
   - Set up caching strategies

3. **Security Hardening**
   - Enable rate limiting
   - Configure CORS properly
   - Set up authentication

## 🐛 Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check Docker status
docker-compose ps

# View error logs
./scripts/logs.sh | grep ERROR

# Restart services
docker-compose restart
```

**Database connection failed:**
```bash
# Check MongoDB status
./scripts/logs.sh mongodb

# Test connection
docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"
```

**Memory issues:**
```bash
# Check resource usage
docker stats

# Reduce concurrent connections
# Upgrade Replit plan
```

### Getting Help

1. **Check Logs**: Always start by checking service logs
2. **Replit Community**: Join Replit Discord for support
3. **Documentation**: Read the main README.md
4. **Issues**: Report problems in the repository

## 📱 Mobile & Desktop App Configuration

### Android App (for-android)

1. **Update API Endpoints**
   ```kotlin
   // In app configuration
   const val API_BASE_URL = "https://your-repl-name.repl.co/api"
   const val WS_BASE_URL = "wss://your-repl-name.repl.co/ws"
   ```

2. **Build Configuration**
   ```bash
   # Update build.gradle
   android {
       defaultConfig {
           buildConfigField "String", "API_URL", "\"https://your-repl-name.repl.co/api\""
       }
   }
   ```

### Desktop App (for-desktop)

1. **Update API Configuration**
   ```typescript
   // In electron configuration
   export const API_URL = 'https://your-repl-name.repl.co/api'
   export const WS_URL = 'wss://your-repl-name.repl.co/ws'
   ```

2. **Build for Platforms**
   ```bash
   npm run build:win
   npm run build:mac
   npm run build:linux
   ```

## 🎯 Best Practices

### Security
- Never commit secrets to version control
- Use Replit Secrets for all sensitive data
- Regularly update dependencies
- Enable 2FA on your Replit account

### Performance
- Use CDN for static assets
- Enable gzip compression
- Optimize database queries
- Monitor resource usage

### Maintenance
- Set up automated backups
- Monitor error logs regularly
- Update services monthly
- Test disaster recovery procedures

## 📚 Additional Resources

- [Replit Documentation](https://docs.replit.com)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Stoatchat Documentation](DEPLOYMENT_ARCHITECTURE.md)
- [MongoDB Documentation](https://docs.mongodb.com)

---

**Ready to deploy?** Your Stoatchat instance will be live in minutes! 🎉