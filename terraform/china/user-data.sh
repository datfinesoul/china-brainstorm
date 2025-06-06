#!/bin/bash
# WordPress Installation Script for Amazon Linux 2
# AWS China Region - Manual WordPress Setup

# Set variables from Terraform template
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USERNAME="${db_username}"
SECRET_ARN="${secret_arn}"
REGION="${region}"

# Log all output
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting WordPress installation on Amazon Linux 2..."

# Update system
yum update -y

# Install required packages
yum install -y httpd php php-mysqlnd php-gd php-xml php-mbstring php-json awscli jq

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Configure PHP
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php.ini

# Get database password from AWS Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --region "$REGION" --query SecretString --output text | jq -r .password)

# Download and configure WordPress
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
mv wordpress/* .
rm -rf wordpress latest.tar.gz

# Set ownership and permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Create wp-config.php
cat > wp-config.php << EOF
<?php
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$DB_USERNAME');
define('DB_PASSWORD', '$DB_PASSWORD');
define('DB_HOST', '$DB_HOST');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// Security keys (will be replaced with real ones below)
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

\$table_prefix = 'wp_';

// ALB and CloudFront configuration
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    \$_SERVER['HTTPS'] = 'on';
}

// Trust ALB forwarded headers
if (isset(\$_SERVER['HTTP_X_FORWARDED_FOR'])) {
    \$forwarded_ips = explode(',', \$_SERVER['HTTP_X_FORWARDED_FOR']);
    \$_SERVER['REMOTE_ADDR'] = trim(\$forwarded_ips[0]);
}

define('WP_DEBUG', false);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

require_once( ABSPATH . 'wp-settings.php' );
EOF

# Generate unique security keys
curl -s https://api.wordpress.org/secret-key/1.1/salt/ > /tmp/wp-salt.txt
if [ -s /tmp/wp-salt.txt ]; then
    # Replace placeholder keys with real ones
    sed -i '/AUTH_KEY/,/NONCE_SALT/d' wp-config.php
    sed -i '/DB_COLLATE/r /tmp/wp-salt.txt' wp-config.php
fi

# Set proper permissions for wp-config.php
chmod 644 wp-config.php

# Create .htaccess for pretty URLs
cat > .htaccess << 'EOF'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %%{REQUEST_FILENAME} !-f
RewriteCond %%{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF

# Configure Apache virtual host
cat > /etc/httpd/conf.d/wordpress.conf << EOF
<Directory "/var/www/html">
    AllowOverride All
    Options Indexes FollowSymLinks
    Require all granted
</Directory>

# ALB health check endpoint
<Location "/health">
    SetHandler server-status
    Require all granted
</Location>

# Enable status module for health checks
LoadModule status_module modules/mod_status.so
ExtendedStatus On
EOF

# Enable mod_rewrite for pretty URLs
echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/httpd/conf/httpd.conf

# Restart Apache to apply configuration
systemctl restart httpd

# Install CloudWatch agent for monitoring
yum install -y amazon-cloudwatch-agent

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/aws/ec2/wordpress/apache/access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "/aws/ec2/wordpress/apache/error",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/wordpress/user-data",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "WordPress/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 300
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 300,
                "resources": ["*"]
            },
            "diskio": {
                "measurement": ["io_time"],
                "metrics_collection_interval": 300,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 300
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Create a completion marker
echo "WORDPRESS_INSTALL_COMPLETE" > /tmp/wordpress-ready

echo "WordPress installation completed. Server ready for configuration."
echo "Access WordPress at: http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)/"
echo "Database connection configured for: $DB_HOST"
echo "Log files available in CloudWatch Logs"
