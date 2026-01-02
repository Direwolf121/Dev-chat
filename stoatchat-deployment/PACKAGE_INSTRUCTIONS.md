# Stoatchat Deployment Package Instructions

This package contains everything you need to deploy Stoatchat without Docker. Choose your preferred deployment method below.

## 📦 Package Contents

### Configuration Files
- `docker-compose.yml` - Docker deployment (optional)
- `.env.example` - Environment variables template
- `config/` - All service configurations
- `scripts/` - Deployment and management scripts

### Documentation
- `README.md` - General deployment guide
- `NON_DOCKER_DEPLOYMENT.md` - Non-Docker setup guide
- `REPLIT_DEPLOYMENT_GUIDE.md` - Replit-specific guide
- `DEPLOYMENT_ARCHITECTURE.md` - Technical architecture
- `PACKAGE_INSTRUCTIONS.md` - This file

### Scripts
- `setup.sh` - Complete automated setup
- `scripts/start.sh` - Start all services
- `scripts/stop.sh` - Stop all services
- `scripts/logs.sh` - View service logs

## 🚀 Deployment Options

### Option A: Automated Script Setup (Recommended)

1. **Run the complete setup script:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Follow the interactive prompts**
3. **Access your instance** at the provided URLs

### Option B: Manual Step-by-Step Setup

Follow the detailed instructions in `NON_DOCKER_DEPLOYMENT.md` for complete control over the installation process.

### Option C: Replit Deployment

Perfect for quick testing and development:

1. **Import to Replit**
   - Create new Repl → Import from GitHub
   - Use this repository URL

2. **Configure Secrets**
   - Go to Tools → Secrets
   - Add required environment variables

3. **Run**
   - Click "Run" or execute `./scripts/start.sh`

## 🔧 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04+, Debian 10+, or similar Linux distribution
- **RAM**: 4GB minimum (8GB recommended)
- **CPU**: 2 cores minimum (4 cores recommended)
- **Storage**: 20GB+ free space
- **Network**: Public IP or domain name (for production)

### Required Software
The setup script will install:
- Node.js 18+
- Rust 1.70+
- MongoDB 6.0+
- Redis 7+
- RabbitMQ 3.11+
- Nginx
- Certbot (for SSL)

## 📋 Quick Start Checklist

### Pre-Deployment
- [ ] Server meets minimum requirements
- [ ] Domain name configured (optional but recommended)
- [ ] Firewall configured (ports 80, 443, 22)
- [ ] Backup strategy planned

### Deployment
- [ ] Run `./setup.sh` or follow manual setup
- [ ] Configure environment variables
- [ ] Set up SSL certificates (production)
- [ ] Test all services
- [ ] Configure monitoring

### Post-Deployment
- [ ] Change default passwords
- [ ] Set up automated backups
- [ ] Configure log rotation
- [ ] Test disaster recovery procedures

## 🌐 Service URLs (After Deployment)

### Local Development
- **Main Web App**: http://localhost:3000
- **Admin Panel**: http://localhost:3001
- **Landing Page**: http://localhost:3002
- **Developer Wiki**: http://localhost:3003
- **API Endpoint**: http://localhost:8000
- **WebSocket**: ws://localhost:9000

### Production (with domain)
- **Main Web App**: https://your-domain.com
- **Admin Panel**: https://your-domain.com/admin
- **API Endpoint**: https://your-domain.com/api
- **WebSocket**: wss://your-domain.com/ws

## 🔐 Default Credentials

**Important: Change these immediately after deployment!**

### Database
- MongoDB: `stoatchat` / (password from .env)
- Redis: (password from .env)
- RabbitMQ: `stoatchat` / (password from .env)

### Admin Access
- Admin API Key: (from .env file)
- Grafana: `admin` / `admin` (change immediately)

## 🛠️ Service Management

### Start/Stop Services
```bash
# Start all services
./scripts/start.sh

# Stop all services
./scripts/stop.sh

# Restart services
./scripts/stop.sh && ./scripts/start.sh
```

### View Logs
```bash
# View all logs
./scripts/logs.sh

# Follow specific service
./scripts/logs.sh -f stoatchat-backend

# Show recent logs
./scripts/logs.sh -n 100
```

### Backup and Recovery
```bash
# Backup database
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh backup-file.tar.gz
```

## 📊 Monitoring

### Built-in Monitoring
- **Grafana Dashboard**: http://localhost:3004
- **Prometheus Metrics**: http://localhost:9090
- **RabbitMQ Management**: http://localhost:15672

### Health Checks
```bash
# Check service health
curl http://localhost:8000/health
curl http://localhost:3000/health
```

## 🚨 Security Checklist

### Immediate Actions After Deployment
- [ ] Change all default passwords
- [ ] Configure firewall rules
- [ ] Set up SSL certificates
- [ ] Disable unnecessary services
- [ ] Configure log monitoring
- [ ] Set up fail2ban
- [ ] Regular security updates

### Production Security
- [ ] Use strong passwords (32+ characters)
- [ ] Enable rate limiting
- [ ] Configure CORS properly
- [ ] Set up intrusion detection
- [ ] Regular security audits
- [ ] Backup encryption

## 🐛 Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check service status
sudo systemctl status stoatchat-backend
sudo systemctl status stoatchat-web

# Check logs
sudo journalctl -u stoatchat-backend -f
./scripts/logs.sh
```

**Port conflicts:**
```bash
# Check port usage
netstat -tlnp | grep :3000
lsof -i :8000
```

**Database connection issues:**
```bash
# Test MongoDB
mongo stoatchat --eval "db.adminCommand('ping')"

# Test Redis
redis-cli ping
```

### Getting Help

1. **Check Documentation**: Read the relevant deployment guide
2. **Check Logs**: Always start by checking service logs
3. **System Status**: Verify system resources and services
4. **Community Support**: Join the Stoatchat community
5. **Professional Support**: Contact for managed hosting

## 📈 Scaling

### Vertical Scaling
- Increase RAM and CPU resources
- Optimize database queries
- Enable caching
- Use CDN for static assets

### Horizontal Scaling
- Multiple backend instances
- Database read replicas
- Load balancing
- Microservices architecture

## 🎯 Production Checklist

### Before Going Live
- [ ] Security audit completed
- [ ] Performance testing done
- [ ] Backup strategy tested
- [ ] Monitoring configured
- [ ] SSL certificates installed
- [ ] Domain DNS configured
- [ ] Rate limiting enabled
- [ ] Error handling reviewed

### Maintenance
- [ ] Regular security updates
- [ ] Database maintenance
- [ ] Log rotation
- [ ] Performance monitoring
- [ ] Backup verification
- [ ] Disaster recovery testing

## 📞 Support Options

### Self-Hosting Support
- Documentation included in package
- Community forums
- GitHub issues
- Setup assistance available

### Managed Hosting
- Fully managed deployment
- 24/7 monitoring
- Automatic backups
- Security updates
- Performance optimization
- Technical support

**Need help deciding?**
- For learning: Use Option A (automated setup)
- For production: Consider managed hosting
- For development: Use Replit deployment
- For customization: Use manual setup

## 🎉 You're Ready!

Choose your deployment method and get started:
1. **Quick**: Run `./setup.sh` for automated setup
2. **Detailed**: Follow `NON_DOCKER_DEPLOYMENT.md`
3. **Cloud**: Use Replit for instant deployment

**Good luck with your Stoatchat deployment!** 🚀