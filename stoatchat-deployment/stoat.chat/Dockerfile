# Multi-stage Dockerfile for Stoatchat Landing Page (Astro)

# Build stage
FROM node:18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine AS production

# Create non-root user
RUN adduser -D -s /bin/sh -u 1000 nginx-user

# Copy built application
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Create startup script for environment injection
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'envsubst < /usr/share/nginx/html/config.template.js > /usr/share/nginx/html/config.js' >> /docker-entrypoint.sh && \
    echo 'exec "$@"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Create config template
RUN mkdir -p /usr/share/nginx/html && \
    cat > /usr/share/nginx/html/config.template.js << 'EOF'
window.CONFIG = {
    PUBLIC_API_URL: '${PUBLIC_API_URL:-http://localhost:8000}',
    PUBLIC_APP_NAME: '${PUBLIC_APP_NAME:-Stoatchat}',
    PUBLIC_APP_DESCRIPTION: '${PUBLIC_APP_DESCRIPTION:-Self-hosted Stoatchat instance}'
};
EOF

# Switch to non-root user
USER nginx-user

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/ || exit 1

# Set entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]