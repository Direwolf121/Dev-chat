# Stoatchat Self-Hosted Deployment

This repository contains everything you need to self-host your own Stoatchat instance with all components including the main web app, backend services, admin panel, landing page, developer wiki, and mobile/desktop app configurations.

## 🚀 Quick Start

### Prerequisites

- **Docker** and **Docker Compose** installed
- **Domain name** (optional but recommended for production)
- **At least 4GB RAM** and **2 vCPUs**
- **Linux/macOS/Windows** with Docker support

### 1. Clone and Setup

```bash
# Clone this deployment repository
git clone <your-deployment-repo>
cd stoatchat-deployment

# Copy environment configuration
cp .env.example .env

# Edit configuration (IMPORTANT!)
nano .env  # or use your preferred editor
```

### 2. Configure Environment

Edit the `.env` file with your settings:

```env
# Security - CHANGE THESE!
JWT_SECRET=your-super-secret-jwt-key-here
MONGO_ROOT_PASSWORD=secure-mongodb-password
REDIS_PASSWORD=secure-redis-password
RABBITMQ_PASSWORD=secure-rabbitmq-password

# Domain settings
DOMAIN_NAME=yourdomain.com
ENABLE_SSL=false  # Set to true for production

# Features
ENABLE_REGISTRATION=true
```

### 3. Deploy

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Start deployment
./scripts/start.sh
```

### 4. Access Your Instance

Once deployment completes, access your services:

- **Main Web App**: http://localhost:3000
- **Admin Panel**: http://localhost:3001
- **Landing Page**: http://localhost:3002
- **Developer Wiki**: http://localhost:3003
- **Backend API**: http://localhost:8000
- **WebSocket**: ws://localhost:9000

## 📁 Repository Structure

```
stoatchat-deployment/
├── docker-compose.yml          # Main Docker Compose configuration
├── .env.example               # Environment variables template
├── .replit                   # Replit configuration
├── DEPLOYMENT_ARCHITECTURE.md # Detailed architecture documentation
├── scripts/
│   ├── start.sh              # Main deployment script
│   ├── stop.sh               # Stop services script
│   └── logs.sh               # View logs script
├── config/
│   ├── nginx/                # Nginx configuration
│   ├── mongodb/              # MongoDB initialization
│   ├── prometheus/           # Monitoring configuration
│   └── grafana/              # Dashboard configuration
└── data/                     # Persistent data storage
```

## 🏗️ Architecture Overview

### Core Services

| Service | Port | Purpose |
|---------|------|---------|
| **MongoDB** | 27017 | Primary database |
| **Redis** | 6379 | Caching & sessions |
| **RabbitMQ** | 5672 | Message broker |
| **Backend API** | 8000 | Core API server |
| **WebSocket** | 9000 | Real-time messaging |

### Application Services

| Service | Port | Purpose |
|---------|------|---------|
| **Web App** | 3000 | Main chat interface |
| **Admin Panel** | 3001 | Content management |
| **Landing Page** | 3002 | Marketing site |
| **Developer Wiki** | 3003 | Documentation |
| **File Storage** | 5000 | File uploads |
| **Image Processing** | 5001 | Image optimization |
| **GIF Processing** | 5002 | GIF handling |

### Monitoring

| Service | Port | Purpose |
|---------|------|---------|
| **Grafana** | 3004 | Monitoring dashboard |
| **Prometheus** | 9090 | Metrics collection |
| **RabbitMQ Management** | 15672 | Queue management |

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

```env
# Security
JWT_SECRET=your-jwt-secret-key
ADMIN_API_KEY=admin-secret-key

# Database
MONGO_ROOT_PASSWORD=secure-password
REDIS_PASSWORD=secure-password
RABBITMQ_PASSWORD=secure-password

# Domain & SSL
DOMAIN_NAME=yourdomain.com
ENABLE_SSL=false
LETSENCRYPT_EMAIL=admin@yourdomain.com

# Features
ENABLE_REGISTRATION=true
ENABLE_INVITES=false
```

### Custom Domains

To use custom domains, update your DNS records:

```
A     @          → YOUR_SERVER_IP
A     api        → YOUR_SERVER_IP
A     ws         → YOUR_SERVER_IP
A     admin      → YOUR_SERVER_IP
```

Then configure Nginx and enable SSL.

## 🚀 Deployment Options

### Standard Deployment

```bash
./scripts/start.sh
```

### Development Mode

```bash
DEVELOPMENT_MODE=true ./scripts/start.sh
```

### With Monitoring

```bash
ENABLE_MONITORING=true ./scripts/start.sh
```

### Replit Deployment

This setup is fully compatible with Replit:

1. Import the repository to Replit
2. Configure environment variables in Replit Secrets
3. Click "Run" to deploy
4. Use Replit's public URLs to access services

## 📊 Monitoring

### Grafana Dashboard

Access Grafana at http://localhost:3004 (admin/admin)

### Logs

View logs for all services:
```bash
./scripts/logs.sh
```

Follow logs for specific service:
```bash
./scripts/logs.sh -f stoatchat-backend
```

Show last 50 lines:
```bash
./scripts/logs.sh -n 50
```

## 🔒 Security

### Production Checklist

- [ ] Change all default passwords
- [ ] Enable SSL/TLS certificates
- [ ] Configure firewall rules
- [ ] Set up rate limiting
- [ ] Enable monitoring
- [ ] Configure backups
- [ ] Set up log rotation
- [ ] Update dependencies regularly

### SSL/HTTPS Setup

1. Set `ENABLE_SSL=true` in `.env`
2. Update `LETSENCRYPT_EMAIL`
3. Configure your domain
4. Run deployment script

### Firewall Configuration

```bash
# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow SSH (adjust port if needed)
sudo ufw allow 22/tcp

# Enable firewall
sudo ufw enable
```

## 🛠️ Management

### Starting Services

```bash
./scripts/start.sh
```

### Stopping Services

```bash
./scripts/stop.sh
```

### Removing All Data

```bash
./scripts/stop.sh --clean
```

### Updating Services

```bash
# Pull latest images
docker-compose pull

# Rebuild and restart
docker-compose up --build -d
```

## 📱 Mobile & Desktop Apps

### Android App

1. Clone `for-android` repository
2. Update API endpoints in app configuration
3. Build with Android Studio
4. Distribute via APK or Play Store

### Desktop App

1. Clone `for-desktop` repository
2. Update API endpoints
3. Build for target platforms:
   ```bash
   npm run build:win
   npm run build:mac
   npm run build:linux
   ```

### iOS App

iOS app can be built using similar configuration patterns as Android.

## 🔄 Backup & Recovery

### Database Backup

```bash
# Backup MongoDB
docker-compose exec mongodb mongodump --out /backup/$(date +%Y%m%d)

# Restore MongoDB
docker-compose exec mongodb mongorestore /backup/20240101
```

### File Backup

```bash
# Backup uploads
tar -czf stoatchat-uploads-backup.tar.gz data/uploads/

# Backup configuration
tar -czf stoatchat-config-backup.tar.gz config/ .env
```

## 🚨 Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check logs
./scripts/logs.sh

# Check Docker status
docker-compose ps
```

**Database connection failed:**
```bash
# Check MongoDB status
./scripts/logs.sh mongodb

# Restart database
docker-compose restart mongodb
```

**Port conflicts:**
```bash
# Check port usage
netstat -tlnp | grep :3000

# Change ports in docker-compose.yml
```

### Performance Tuning

- Increase Docker memory limits
- Add database connection pooling
- Enable Redis clustering
- Use CDN for static assets
- Optimize MongoDB indexes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test deployment
5. Submit a pull request

## 📄 License

This deployment configuration is provided under the MIT License. See LICENSE file for details.

## 🆘 Support

- **Documentation**: Check `DEPLOYMENT_ARCHITECTURE.md`
- **Issues**: Report deployment issues in the repository
- **Community**: Join the Stoatchat community for support

## 🙏 Credits

- **Stoatchat Team**: Original platform development
- **Revolt Chat**: Foundation codebase
- **Open Source Community**: Various dependencies and tools

---

**Ready to deploy?** Start with `./scripts/start.sh` and join the Stoatchat revolution! 🚀