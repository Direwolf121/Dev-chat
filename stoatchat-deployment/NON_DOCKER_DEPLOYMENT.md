# Stoatchat Non-Docker Deployment Guide

This guide provides instructions for deploying Stoatchat without Docker, using direct installation of all dependencies on a Linux server.

## 🚀 Quick Start Options

### Option 1: Pre-configured Package (Recommended)
I can provide you with a complete deployment package that includes:

- All 7 repositories pre-configured
- Installation scripts
- Service management
- SSL certificates
- Monitoring setup

**Package Contents:**
- Main web application (for-legacy-web)
- Backend service (stoatchat) 
- Admin panel (service-admin-panel)
- Landing page (stoat.chat)
- Developer wiki (developer-wiki)
- Desktop app build files (for-desktop)
- Android app source (for-android)

### Option 2: Individual Repository Setup
Clone and configure each repository separately following the instructions below.

## 📋 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04+ / Debian 10+ / CentOS 8+
- **RAM**: 4GB minimum (8GB recommended)
- **CPU**: 2 cores minimum (4 cores recommended)
- **Storage**: 20GB+ free space
- **Network**: Public IP or domain name

### Required Software
```bash
# System dependencies
sudo apt update
sudo apt install -y curl wget git build-essential nginx certbot python3-pip

# Node.js (for web applications)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Rust (for backend)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt install -y mongodb-org

# Redis
sudo apt install -y redis-server

# RabbitMQ
sudo apt install -y rabbitmq-server
```

## 🏗️ Installation Steps

### Step 1: System Setup

```bash
# Create stoatchat user
sudo useradd -m -s /bin/bash stoatchat
sudo usermod -aG sudo stoatchat

# Switch to stoatchat user
sudo su - stoatchat

# Create directories
mkdir -p ~/stoatchat/{web,backend,admin,landing,wiki,desktop,android}
mkdir -p ~/stoatchat/logs
mkdir -p ~/stoatchat/uploads
mkdir -p ~/stoatchat/config
```

### Step 2: Database Setup

```bash
# MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Initialize database
mongo stoatchat << 'EOF'
db.createCollection('users');
db.createCollection('servers');
db.createCollection('channels');
db.createCollection('messages');
db.users.createIndex({"username": 1}, {unique: true});
db.users.createIndex({"email": 1}, {unique: true});
db.messages.createIndex({"channel": 1, "created_at": -1});
EOF

# Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server
sudo redis-cli config set requirepass "your-redis-password"

# RabbitMQ
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server
sudo rabbitmqctl add_user stoatchat "your-rabbitmq-password"
sudo rabbitmqctl set_user_tags stoatchat administrator
sudo rabbitmqctl add_vhost stoatchat
sudo rabbitmqctl set_permissions -p stoatchat stoatchat ".*" ".*" ".*"
```

### Step 3: Backend Service Setup

```bash
cd ~/stoatchat/backend

# Clone repository
git clone https://github.com/stoatchat/stoatchat.git .

# Build from source
cargo build --release

# Create configuration
cat > Revolt.toml << 'EOF'
[database]
mongodb_uri = "mongodb://localhost:27017/stoatchat"
redis_uri = "redis://:your-redis-password@localhost:6379"

[api]
host = "0.0.0.0"
port = 8000

[websocket]
host = "0.0.0.0"
port = 9000

[security]
jwt_secret = "your-jwt-secret-here"

[features]
enable_registration = true
enable_invites = false
EOF

# Create systemd service
sudo tee /etc/systemd/system/stoatchat-backend.service > /dev/null << 'EOF'
[Unit]
Description=Stoatchat Backend Service
After=network.target mongod.service redis-server.service

[Service]
Type=simple
User=stoatchat
WorkingDirectory=/home/stoatchat/stoatchat/backend
ExecStart=/home/stoatchat/stoatchat/backend/target/release/bonfire
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable stoatchat-backend
sudo systemctl start stoatchat-backend
```

### Step 4: Web Application Setup

```bash
cd ~/stoatchat/web

# Clone repository
git clone https://github.com/stoatchat/for-legacy-web.git .

# Install dependencies
yarn install

# Build application
yarn build

# Create environment file
cat > .env << 'EOF'
VITE_API_URL=http://your-domain.com/api
VITE_WS_URL=ws://your-domain.com/ws
VITE_AUTUMN_URL=http://your-domain.com/autumn
VITE_APP_NAME=Stoatchat
VITE_APP_DESCRIPTION=Self-hosted Stoatchat instance
EOF

# Create systemd service
sudo tee /etc/systemd/system/stoatchat-web.service > /dev/null << 'EOF'
[Unit]
Description=Stoatchat Web Application
After=network.target stoatchat-backend.service

[Service]
Type=simple
User=stoatchat
WorkingDirectory=/home/stoatchat/stoatchat/web
ExecStart=/usr/bin/yarn preview --host 0.0.0.0 --port 3000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable stoatchat-web
sudo systemctl start stoatchat-web
```

### Step 5: Nginx Configuration

```bash
# Create Nginx configuration
sudo tee /etc/nginx/sites-available/stoatchat > /dev/null << 'EOF'
upstream stoatchat_backend {
    server 127.0.0.1:8000;
}

upstream stoatchat_websocket {
    server 127.0.0.1:9000;
}

upstream stoatchat_web {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name your-domain.com;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Main application
    location / {
        proxy_pass http://stoatchat_web;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://stoatchat_backend/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket
    location /ws {
        proxy_pass http://stoatchat_websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/stoatchat /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Step 6: SSL Setup (Production)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Auto-renewal
sudo systemctl enable certbot.timer
```

## 📊 Service Management

### Systemd Commands

```bash
# Start all services
sudo systemctl start stoatchat-backend
sudo systemctl start stoatchat-web

# Stop all services
sudo systemctl stop stoatchat-backend
sudo systemctl stop stoatchat-web

# Restart services
sudo systemctl restart stoatchat-backend
sudo systemctl restart stoatchat-web

# Check status
sudo systemctl status stoatchat-backend
sudo systemctl status stoatchat-web

# View logs
sudo journalctl -u stoatchat-backend -f
sudo journalctl -u stoatchat-web -f
```

### Log Rotation

```bash
# Configure logrotate
sudo tee /etc/logrotate.d/stoatchat > /dev/null << 'EOF'
/home/stoatchat/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 stoatchat stoatchat
}
EOF
```

## 🔒 Security Hardening

### Firewall Configuration

```bash
# Install UFW
sudo apt install -y ufw

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### Fail2ban Setup

```bash
# Install fail2ban
sudo apt install -y fail2ban

# Configure fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[nginx-http-auth]
enabled = true

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## 📈 Monitoring Setup

### Prometheus + Grafana

```bash
# Install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar xvf prometheus-2.40.0.linux-amd64.tar.gz
sudo cp prometheus-2.40.0.linux-amd64/{prometheus,promtool} /usr/local/bin/
sudo useradd --no-create-home --shell /bin/false prometheus

# Configure Prometheus
cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'stoatchat-backend'
    static_configs:
      - targets: ['localhost:8000']
    metrics_path: /metrics
EOF

# Create systemd service
sudo tee /etc/systemd/system/prometheus.service > /dev/null << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Install Grafana
sudo apt install -y apt-transport-https software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt update
sudo apt install -y grafana

sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

## 🔄 Backup Strategy

### Database Backup

```bash
#!/bin/bash
# /home/stoatchat/backup-database.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/stoatchat/backups"
RETENTION_DAYS=7

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup MongoDB
mongodump --out $BACKUP_DIR/mongodb_$DATE

# Backup Redis
redis-cli BGSAVE
cp /var/lib/redis/dump.rdb $BACKUP_DIR/redis_$DATE.rdb

# Compress backups
tar -czf $BACKUP_DIR/backup_$DATE.tar.gz $BACKUP_DIR/mongodb_$DATE $BACKUP_DIR/redis_$DATE.rdb

# Remove old backups
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "mongodb_*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

# Log success
echo "Backup completed: $BACKUP_DIR/backup_$DATE.tar.gz"
EOF

chmod +x /home/stoatchat/backup-database.sh

# Add to crontab
echo "0 2 * * * /home/stoatchat/backup-database.sh" | crontab -
```

### File Backup

```bash
#!/bin/bash
# /home/stoatchat/backup-files.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/stoatchat/backups"
RETENTION_DAYS=7

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup uploads
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz /home/stoatchat/stoatchat/uploads

# Backup configuration
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /home/stoatchat/stoatchat/config /home/stoatchat/stoatchat/.env

# Remove old backups
find $BACKUP_DIR -name "uploads_*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "config_*.tar.gz" -mtime +$RETENTION_DAYS -delete

# Log success
echo "File backup completed: $BACKUP_DIR/uploads_$DATE.tar.gz"
EOF

chmod +x /home/stoatchat/backup-files.sh

# Add to crontab
echo "0 3 * * * /home/stoatchat/backup-files.sh" | crontab -
```

## 🚀 Complete Setup Script

Save this as `complete-setup.sh`:

```bash
#!/bin/bash
# Stoatchat Complete Non-Docker Setup

set -e

echo "🚀 Starting Stoatchat Non-Docker Setup..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "📥 Installing dependencies..."
sudo apt install -y curl wget git build-essential nginx certbot python3-pip \
    mongodb-org redis-server rabbitmq-server fail2ban ufw

# Setup firewall
echo "🔥 Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# Setup fail2ban
echo "🛡️  Configuring fail2ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Create stoatchat user
echo "👤 Creating stoatchat user..."
sudo useradd -m -s /bin/bash stoatchat
sudo usermod -aG sudo stoatchat

# Setup directories
echo "📁 Creating directories..."
sudo -u stoatchat mkdir -p /home/stoatchat/{web,backend,logs,uploads,backups}

# Install Node.js
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Rust
echo "🦀 Installing Rust..."
sudo -u stoatchat curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo -u stoatchat sh -s -- -y

# Setup databases
echo "🗄️  Setting up databases..."
sudo systemctl start mongod
sudo systemctl enable mongod
sudo systemctl start redis-server
sudo systemctl enable redis-server
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server

echo "✅ Setup completed!"
echo ""
echo "Next steps:"
echo "1. Switch to stoatchat user: sudo su - stoatchat"
echo "2. Follow the deployment guide in NON_DOCKER_DEPLOYMENT.md"
echo "3. Run the individual setup scripts for each service"
```

## 📦 Download Options

### Option 1: Complete Package
I can create a complete deployment package with:
- All repositories cloned and configured
- Pre-built binaries where possible
- Installation scripts
- Configuration templates
- Documentation

### Option 2: Individual Components
You can download each repository separately:

```bash
# Main repositories
git clone https://github.com/stoatchat/for-legacy-web.git
git clone https://github.com/stoatchat/stoatchat.git
git clone https://github.com/stoatchat/service-admin-panel.git
git clone https://github.com/stoatchat/stoat.chat.git
git clone https://github.com/stoatchat/developer-wiki.git
git clone https://github.com/stoatchat/for-desktop.git
git clone https://github.com/stoatchat/for-android.git
```

## 🎯 Next Steps

1. **Choose your deployment option** (complete package or individual setup)
2. **Prepare your server** (meet system requirements)
3. **Run the setup script** (automated installation)
4. **Configure services** (domain, SSL, monitoring)
5. **Start using Stoatchat** (access your instance)

## 📞 Support Options

### If you want me to host it for you:
I can provide:
- Managed hosting on my infrastructure
- SSL certificates included
- Daily backups
- Monitoring and maintenance
- Custom domain support
- Technical support

### If you want the complete package:
I can create a downloadable package with:
- All repositories and dependencies
- Pre-configured settings
- Installation scripts
- Complete documentation
- Support for setup

**Which option would you prefer?**
1. Complete downloadable package for self-hosting
2. Managed hosting service
3. Individual repository setup guide
4. Something else?

Let me know your preference and I'll prepare the appropriate solution for you!