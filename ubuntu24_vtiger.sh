#!/bin/bash

# Variables
MYSQL_USER="username"
MYSQL_PASSWORD="your_password"
VTIGER_URL="https://sourceforge.net/projects/vtigercrm/files/latest/download"
VTIGER_DIR="/var/www/html/vtigercrm"
DOMAIN="your_domain.com (or) Ip_address"
PHP_VERSION="8.3"

# Update and Upgrade System
echo "Updating system..."
sudo apt update -y

# Install Apache Web Server
echo "Installing Apache..."
sudo apt install apache2 -y

# Install MySQL Server
echo "Installing MySQL..."
sudo apt install mysql-server -y

# Secure MySQL Installation
echo "Securing MySQL..."
sudo mysql_secure_installation

# Install PHP and Required Modules
echo "Installing PHP and modules..."
sudo apt install php libapache2-mod-php php-mysql php-curl php-json php-cgi php-imap php-cli php-gd php-zip php-mbstring php-xml -y

# Configure PHP
echo "Configuring PHP..."
sudo sed -i "s/^memory_limit.*/memory_limit = 256M/" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/^max_execution_time.*/max_execution_time = 60/" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/^error_reporting.*/error_reporting = E_ERROR \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/^display_errors.*/display_errors = Off/" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/^short_open_tag.*/short_open_tag = Off/" /etc/php/${PHP_VERSION}/apache2/php.ini

# Create MySQL Database and User
echo "Setting up MySQL database and user..."
sudo mysql -u root -e "CREATE DATABASE vtiger;"
sudo mysql -u root -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON vtiger.* TO '${MYSQL_USER}'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

# Download and Extract vTiger CRM
echo "Downloading and setting up vTiger CRM..."
cd /tmp
wget -O vtigercrm.tar.gz ${VTIGER_URL}
tar -xvzf vtigercrm.tar.gz
sudo mv vtigercrm ${VTIGER_DIR}
sudo chown -R www-data:www-data ${VTIGER_DIR}
sudo chmod -R 755 ${VTIGER_DIR}

# Create Apache Configuration File
echo "Configuring Apache for vTiger CRM..."
cat <<EOF | sudo tee /etc/apache2/sites-available/vtigercrm.conf
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot ${VTIGER_DIR}
    ServerName ${DOMAIN}
    <Directory ${VTIGER_DIR}>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/vtigercrm_error.log
    CustomLog \${APACHE_LOG_DIR}/vtigercrm_access.log combined
</VirtualHost>
EOF

# Enable Apache Site and Module
echo "Enabling site and modules..."
sudo a2ensite vtigercrm.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

# Final Message
echo "vTiger CRM setup is complete. Access it via http://${DOMAIN} or http://<your_server_IP> in your browser."
