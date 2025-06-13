# Dockerfile for Nginx with SSL support
FROM alpine:3.22

# Install Nginx and necessary packages
RUN apk update && apk add --no-cache \
    nginx openssl

# # Create nginx user if not exists
# RUN addgroup -g 1000 nginx 2>/dev/null || true \
#     && adduser -D -u 1000 -G nginx nginx 2>/dev/null || true

# Create directories for Nginx
# Nginx runtime directory
RUN mkdir -p /run/nginx
# SSL certificates directory
RUN mkdir -p /etc/nginx/ssl
# WordPress files
RUN mkdir -p /var/www/html

# Create SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=JP/ST=Tokyo/L=Tokyo/O=42School/CN=yjinnouc.42.fr" && \
    chmod 600 /etc/nginx/ssl/nginx.key

# Copy Nginx configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Create directory for WordPress files
RUN mkdir -p /var/www/html

# Expose port 443 for HTTPS
EXPOSE 443

# # Set proper user
# USER nginx

# Start Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
