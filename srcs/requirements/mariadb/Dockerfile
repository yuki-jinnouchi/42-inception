FROM alpine:3.22

# Install MariaDB
RUN apk update && apk add --no-cache \
	mariadb mariadb-client \
	envsubst

# Create mysql user if not exists
RUN addgroup -g 1000 mysql 2>/dev/null || true && \
	adduser -D -u 1000 -G mysql mysql 2>/dev/null || true

# Configure MariaDB directories
RUN mkdir -p /run/mysql /var/lib/mysql && \
	chown -R mysql:mysql /run/mysql /var/lib/mysql

# Copy MariaDB configuration
COPY ./conf/my.cnf /etc/my.cnf.d/custom.cnf

# Copy setup script and database initialization files
COPY tools/setup.sh .
RUN chmod +x setup.sh
COPY tools/database.sql .
RUN chmod 644 database.sql

# Set permissions for the plugin directory
RUN chmod +x /usr/lib/mariadb/plugin

# # Set proper user
# USER mysql

# Expose port 3306 for MariaDB
EXPOSE 3306

# Start MariaDB
CMD ["./setup.sh"]
