#!/bin/sh
# Simplified WordPress setup script

echo "Loading WordPress secrets..."
export MYSQL_PASSWORD=$(cat ${MYSQL_PASSWORD_FILE})
export WP_DB_PASSWORD=$(cat ${WP_DB_PASSWORD_FILE})
export WP_ADMIN_PASSWORD=$(cat ${WP_ADMIN_PASSWORD_FILE})
export WP_USER_PASSWORD=$(cat ${WP_USER_PASSWORD_FILE})

echo "Waiting for MariaDB connection..."
while ! nc -z mariadb 3306; do
    echo "MariaDB not ready, waiting..."
    sleep 2
done
echo "MariaDB is ready!"

# WordPress initialization with WP-CLI
echo "Initializing WordPress..."

# Set up proper permissions for WordPress
chown -R wordpress:wordpress /var/www/html

# Check WP-CLI installation
if ! command -v wp > /dev/null; then
    echo "❌ WP-CLI not found. Installing..."
    curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/wp-cli/v2.10.0/bin/wp
    chmod +x /usr/local/bin/wp
fi

# Check if WordPress is installed
if ! wp core is-installed --allow-root --path=/var/www/html; then
    echo "Installing WordPress core..."
    wp core install \
        --path=/var/www/html \
        --url="${WP_URL:-https://yjinnouc.42.fr}" \
        --title="${WP_TITLE:-Inception WordPress}" \
        --admin_user="${WP_ADMIN_USER:-admin}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL:-admin@inception.local}" \
        --allow-root

    # Create additional user if specified
    if [ -n "${WP_USER_LOGIN}" ]; then
        echo "Creating additional WordPress user..."
        wp user create \
            "${WP_USER_LOGIN}" \
            "${WP_USER_EMAIL:-user@inception.local}" \
            --user_pass="${WP_USER_PASSWORD}" \
            --role=author \
            --path=/var/www/html \
            --allow-root
    fi

    echo "WordPress installation completed!"
else
    echo "WordPress already installed, skipping setup."
fi

echo "Starting PHP-FPM..."
exec php-fpm83 --nodaemonize
