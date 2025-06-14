# Dockerfile for Nginx with SSL support
FROM alpine:3.22

# Install dependencies and clean cache in a single layer
RUN apk update && apk add --no-cache \
    nginx \
    openssl \
    curl \
    && rm -rf /var/cache/apk/*

# Create system directories and set proper permissions
RUN mkdir -p /run/nginx \
    /etc/nginx/ssl \
    /var/www/html \
    /var/log/nginx \
    && chown -R nginx:nginx /var/www/html /var/log/nginx \
    && chmod 755 /var/www/html

# Generate SSL certificate with stronger encryption
RUN openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=JP/ST=Tokyo/L=Tokyo/O=42School/OU=Student/CN=yjinnouc.42.fr" \
    && chmod 600 /etc/nginx/ssl/nginx.key \
    && chmod 644 /etc/nginx/ssl/nginx.crt \
    && chown nginx:nginx /etc/nginx/ssl/nginx.*

# Copy configuration files
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Create non-root user for better security
USER nginx

# Expose HTTPS port only
EXPOSE 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -fsSL https://localhost:443/ > /dev/null || exit 1

# Use exec form and run as non-root
CMD ["nginx", "-g", "daemon off;"]
