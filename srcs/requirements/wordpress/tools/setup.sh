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

echo "Starting PHP-FPM..."
exec php-fpm83 --nodaemonize
