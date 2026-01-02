# Multi-stage Dockerfile for Stoatchat Web Application

# Build stage
FROM node:18-alpine AS builder

# Install system dependencies
RUN apk add --no-cache git python3 make g++

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json yarn.lock* .yarnrc.yml* ./

# Install dependencies
RUN if [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    else npm ci; fi

# Copy source code
COPY . .

# Build the application
RUN if [ -f yarn.lock ]; then yarn build; \
    else npm run build; fi

# Production stage
FROM nginx:alpine AS production

# Install Node.js for runtime scripts
RUN apk add --no-cache nodejs npm

# Copy built application
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Create startup script
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'node /usr/share/nginx/html/scripts/env-inject.js' >> /docker-entrypoint.sh && \
    echo 'exec "$@"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Create environment injection script
RUN mkdir -p /usr/share/nginx/html/scripts && \
    cat > /usr/share/nginx/html/scripts/env-inject.js << 'EOF'
const fs = require('fs');
const path = require('path');

// Environment variables to inject
const envVars = {
    VITE_API_URL: process.env.VITE_API_URL || 'http://localhost:8000',
    VITE_WS_URL: process.env.VITE_WS_URL || 'ws://localhost:9000',
    VITE_AUTUMN_URL: process.env.VITE_AUTUMN_URL || 'http://localhost:5000',
    VITE_APP_NAME: process.env.VITE_APP_NAME || 'Stoatchat',
    VITE_APP_DESCRIPTION: process.env.VITE_APP_DESCRIPTION || 'Self-hosted Stoatchat instance'
};

// Read index.html
const indexPath = path.join(__dirname, '..', 'index.html');
let indexContent = fs.readFileSync(indexPath, 'utf8');

// Inject environment variables
const envScript = `<script>window.ENV = ${JSON.stringify(envVars)};</script>`;
indexContent = indexContent.replace('</head>', `${envScript}</head>`);

// Write modified index.html
fs.writeFileSync(indexPath, indexContent);

console.log('Environment variables injected successfully');
EOF

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/ || exit 1

# Set entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]