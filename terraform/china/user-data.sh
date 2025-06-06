#!/bin/bash
# WordPress Configuration Script for Bitnami AMI
# Configures WordPress to work with ALB and RDS MySQL

set -e

# Variables from Terraform
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USERNAME="${db_username}"
SECRET_ARN="${secret_arn}"
REGION="${region}"

# Log file for debugging
LOGFILE="/var/log/wordpress-config.log"
exec 1> >(tee -a $LOGFILE)
exec 2>&1

echo "Starting WordPress configuration at $(date)"

# Install AWS CLI if not present
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
fi

# Get database password from Secrets Manager
echo "Retrieving database password from Secrets Manager..."
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --region "$REGION" --query SecretString --output text)
DB_PASSWORD=$(echo "$DB_SECRET" | jq -r '.password')

if [ -z "$DB_PASSWORD" ]; then
    echo "ERROR: Could not retrieve database password from Secrets Manager"
    exit 1
fi

# Stop Apache and MySQL services
echo "Stopping Bitnami services..."
sudo /opt/bitnami/ctlscript.sh stop

# Configure WordPress wp-config.php for external RDS
echo "Configuring WordPress for external RDS database..."
WP_CONFIG="/opt/bitnami/wordpress/wp-config.php"

# Backup original wp-config.php
sudo cp "$WP_CONFIG" "$WP_CONFIG.backup"

# Update database configuration
sudo sed -i "s/define( 'DB_NAME', '.*' );/define( 'DB_NAME', '$DB_NAME' );/" "$WP_CONFIG"
sudo sed -i "s/define( 'DB_USER', '.*' );/define( 'DB_USER', '$DB_USERNAME' );/" "$WP_CONFIG"
sudo sed -i "s/define( 'DB_PASSWORD', '.*' );/define( 'DB_PASSWORD', '$DB_PASSWORD' );/" "$WP_CONFIG"
sudo sed -i "s/define( 'DB_HOST', '.*' );/define( 'DB_HOST', '$DB_HOST' );/" "$WP_CONFIG"

# Configure WordPress for ALB (handle X-Forwarded-Proto)
echo "Configuring WordPress for Application Load Balancer..."
cat << 'EOF' | sudo tee -a "$WP_CONFIG" > /dev/null

// ALB and CloudFront configuration
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// Trust ALB forwarded headers
if (isset($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $forwarded_ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
    $_SERVER['REMOTE_ADDR'] = trim($forwarded_ips[0]);
}
EOF

# Configure Apache for ALB health checks
echo "Configuring Apache for ALB health checks..."
cat << 'EOF' | sudo tee /opt/bitnami/apache/conf/vhosts/wordpress-alb.conf > /dev/null
<VirtualHost *:80>
    DocumentRoot /opt/bitnami/wordpress
    
    # ALB health check endpoint
    <Location "/health">
        SetHandler server-status
        Require all granted
    </Location>
    
    # WordPress configuration
    <Directory "/opt/bitnami/wordpress">
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>
    
    # Logging
    ErrorLog /opt/bitnami/apache/logs/wordpress_error.log
    CustomLog /opt/bitnami/apache/logs/wordpress_access.log combined
</VirtualHost>
EOF

# Enable mod_rewrite and headers for WordPress
echo "Enabling Apache modules..."
sudo /opt/bitnami/apache/bin/httpd -M | grep -q rewrite || sudo /opt/bitnami/apache/bin/a2enmod rewrite
sudo /opt/bitnami/apache/bin/httpd -M | grep -q headers || sudo /opt/bitnami/apache/bin/a2enmod headers

# Disable local MySQL service (using RDS)
echo "Disabling local MySQL service..."
sudo /opt/bitnami/ctlscript.sh stop mysql
sudo systemctl disable bitnami.service || true

# Start Apache
echo "Starting Apache service..."
sudo /opt/bitnami/ctlscript.sh start apache

# Install WordPress CLI for additional configuration
echo "Installing WP-CLI..."
curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/bin/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

# Set proper permissions
echo "Setting WordPress permissions..."
sudo chown -R bitnami:daemon /opt/bitnami/wordpress
sudo find /opt/bitnami/wordpress -type d -exec chmod 755 {} \;
sudo find /opt/bitnami/wordpress -type f -exec chmod 644 {} \;

# Signal that configuration is complete
echo "WordPress configuration completed successfully at $(date)"
echo "WORDPRESS_CONFIG_COMPLETE" > /tmp/wordpress-ready

# Test database connection
echo "Testing database connection..."
if wp db check --path=/opt/bitnami/wordpress --allow-root; then
    echo "Database connection successful"
else
    echo "WARNING: Database connection test failed"
fi

echo "WordPress setup script completed at $(date)"
