#!/bin/sh
# setup.sh for MariaDB

# Load environment variables (secrets)
export MYSQL_ROOT_PASSWORD=$(cat ${MYSQL_ROOT_PASSWORD_FILE})
export MYSQL_PASSWORD=$(cat ${MYSQL_PASSWORD_FILE})

# Initialize MariaDB if not already done
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to initialize MariaDB"
        exit 1
    fi
    echo "MariaDB initialized successfully"
fi

# Start MariaDB in background for setup
echo "Starting MariaDB in background"
mariadbd \
    --defaults-file=/etc/my.cnf.d/custom.cnf \
    --user=mysql \
    --datadir='/var/lib/mysql' \
    --bind-address=0.0.0.0 \
    --port=3306 & \
MYSQL_PID=$!

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to start..."
timeout=${DB_SETUP_TIMEOUT:-30}
for i in $(seq 1 $timeout); do
    if mariadb --protocol=socket -u root -e "SELECT 1" >/dev/null 2>&1; then
        echo "MariaDB is ready"
        break
    fi
    sleep 1
    echo "Waiting... ($i/$timeout sec)"
done

# Run initialization SQL
echo "Initializing database with SQL scripts"
if [ -f "./database.sql" ]; then
    # envsubst < ./database.sql | cat
    envsubst < ./database.sql | mariadb
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to execute database.sql"
        exit 1
    fi
    echo "Database initialized successfully"
fi

# Stop background MariaDB
echo "Restarting MariaDB in foreground"
kill $MYSQL_PID
wait $MYSQL_PID 2>/dev/null || true
echo "MariaDB background process stopped"

# Start MariaDB in foreground
echo "MariaDB setup complete!"
exec mariadbd-safe \
    --defaults-file=/etc/my.cnf.d/custom.cnf \
    --user=mysql \
    --datadir='/var/lib/mysql' \
    --bind-address=0.0.0.0 \
    --port=3306
