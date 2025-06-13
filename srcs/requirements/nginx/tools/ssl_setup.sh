#!/bin/sh

# SSL certificate setup script for Nginx

# Check if we're running as root
if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit 1
fi

# Configuration variables
SSL_DIR="/etc/nginx/ssl"
DOMAIN=${DOMAIN_NAME:-localhost}
CERT_FILE="$SSL_DIR/$DOMAIN.crt"
KEY_FILE="$SSL_DIR/$DOMAIN.key"

# Create SSL directory if it doesn't exist
mkdir -p $SSL_DIR

# Generate self-signed certificate
echo "Generating self-signed SSL certificate for $DOMAIN..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout $KEY_FILE \
	-out $CERT_FILE \
	-subj "/C=FR/ST=IDF/L=Paris/O=42/CN=$DOMAIN"

# Set appropriate permissions
chmod 600 $KEY_FILE
chmod 644 $CERT_FILE

echo "SSL certificate and key generated successfully:"
echo "Certificate: $CERT_FILE"
echo "Key: $KEY_FILE"

exit 0
