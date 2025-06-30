# Simplified WordPress Dockerfile for 42 Inception
FROM alpine:3.21

# Install PHP and necessary extensions in one layer
RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-json \
    php83-curl \
    php83-dom \
    php83-exif \
    php83-fileinfo \
    php83-mbstring \
    php83-openssl \
    php83-xml \
    php83-zip \
    php83-gd \
    curl \
    mariadb-client \
    netcat-openbsd \
    && rm -rf /var/cache/apk/*

# Install WP-CLI for WordPress automation
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/wp-cli/v2.10.0/bin/wp \
    && chmod +x /usr/local/bin/wp \
    && ln -s /usr/bin/php83 /usr/bin/php

# Create wordpress user and directories
RUN addgroup -g 1000 wordpress \
    && adduser -D -u 1000 -G wordpress wordpress \
    && mkdir -p /run/php /var/www/html /var/log/php83 \
    && chown -R wordpress:wordpress /run/php /var/www/html /var/log/php83

# Copy PHP-FPM configuration
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

# Download and extract WordPress
WORKDIR /var/www/html
RUN curl -O https://wordpress.org/latest.tar.gz \
    && tar -xzf latest.tar.gz --strip-components=1 \
    && rm latest.tar.gz

# Copy WordPress configuration and setup script with proper ownership
COPY --chown=wordpress:wordpress conf/wp-config.php ./
COPY --chown=wordpress:wordpress tools/setup.sh ./
RUN chmod +x setup.sh

# Switch to non-root user
USER wordpress

# Expose PHP-FPM port
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php-fpm83 -t || exit 1

# Start WordPress
CMD ["./setup.sh"]
