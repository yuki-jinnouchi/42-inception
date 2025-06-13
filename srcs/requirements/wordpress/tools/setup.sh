#!/bin/sh
# WordPress setup script

# Load environment variables (secrets)
export MYSQL_PASSWORD=$(cat ${MYSQL_PASSWORD_FILE})
export WP_DB_PASSWORD=$(cat ${WP_DB_PASSWORD_FILE})
export WP_ADMIN_PASSWORD=$(cat ${WP_ADMIN_PASSWORD_FILE})
export WP_USER_PASSWORD=$(cat ${WP_USER_PASSWORD_FILE})

# Wait for MariaDB to be ready
echo "Waiting for MariaDB..."
timeout=${WP_DB_ACCESS_TIMEOUT:-60}
while ! nc -z mariadb 3306; do
    sleep 1
    timeout=$(($timeout - 1))
    if [ $(($timeout % 10)) -eq 0 ]; then
        echo "Warning: MariaDB is not ready, retrying... ($timeout sec left)"
    fi
    if [ $timeout -lt 0 ]; then
        echo "ERROR: MariaDB not accessible after 60 seconds"
        exit 1
    fi
done
echo "MariaDB is ready!"

# Start PHP-FPM
echo "Starting PHP-FPM..."
exec php-fpm83 --nodaemonize
