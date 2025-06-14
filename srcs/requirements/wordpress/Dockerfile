# Dockerfile for WordPress
FROM alpine:3.22

# Install necessary packages
RUN apk update && apk add --no-cache \
    php \
    php-fpm \
    php-mysqli \
    php-json \
    php-curl \
    php-dom \
    php-exif \
    php-fileinfo \
    php-mbstring \
    php-openssl \
    php-xml \
    php-zip \
    php-gd \
    curl \
    mariadb-client

# Create wordpress user if not exists
RUN addgroup -g 1000 wordpress 2>/dev/null || true \
    && adduser -D -u 1000 -G wordpress wordpress 2>/dev/null || true

# Configure PHP-FPM
RUN mkdir -p /run/php
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

# Download WordPress
RUN mkdir -p /var/www/html
WORKDIR /var/www/html

RUN curl -O https://wordpress.org/latest.tar.gz && \
tar -xzf latest.tar.gz && \
mv wordpress/* . && \
rmdir wordpress && \
rm latest.tar.gz

# Copy configuration files
COPY conf/wp-config.php /var/www/html/
RUN chown -R wordpress:wordpress /var/www/html

COPY tools/setup.sh .
RUN chmod +x setup.sh

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# # Set proper user
# USER wordpress

# Start PHP-FPM
CMD ["./setup.sh"]
