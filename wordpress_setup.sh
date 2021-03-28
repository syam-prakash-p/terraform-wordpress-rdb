#!/bin/bash
apt-get update
apt-get install apache2 php libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip -y
systemctl start apache2
systemctl enable apache2
echo -e "
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/wordpress
</VirtualHost>
<Directory /var/www/wordpress>
    AllowOverride All
</Directory> " > /etc/apache2/sites-available/wordpress.conf
a2enmod rewrite
curl -O https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
touch wordpress/.htaccess
cp wordpress/wp-config-sample.php wordpress/wp-config.php
mkdir wordpress/wp-content/upgrade
cp -a wordpress/. /var/www/wordpress
chown -R www-data:www-data /var/www/wordpress
find /var/www/wordpress/ -type d -exec chmod 750 {} \;
find /var/www/wordpress/ -type f -exec chmod 640 {} \;

############ modify wordpress config file ##############
sed -i '/DB_HOST/ s/localhost/${db_address}/g' /var/www/wordpress/wp-config.php
sed -i '/DB_NAME/ s/database_name_here/${db_name}/g' /var/www/wordpress/wp-config.php
sed -i '/DB_USER/ s/username_here/${db_user}/g' /var/www/wordpress/wp-config.php
sed -i '/DB_PASSWORD/ s/password_here/${db_pass}/g' /var/www/wordpress/wp-config.php
a2ensite wordpress
a2dissite 000-default
systemctl restart apache2

