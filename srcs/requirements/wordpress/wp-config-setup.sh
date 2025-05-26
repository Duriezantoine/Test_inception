#!/bin/bash

# Attendre que MariaDB soit prêt
echo "Waiting for MariaDB..."
max_retries=30
counter=0

if [ ! -f /var/www/html/wp-load.php ]; then
    echo "Téléchargement de WordPress..."
    wget -q https://wordpress.org/wordpress-6.0.zip -O /tmp/latest.zip
    unzip -q /tmp/latest.zip -d /tmp
    cp -a /tmp/wordpress/* /var/www/html/
    chown -R www-data:www-data /var/www/html
    rm -rf /tmp/latest.zip /tmp/wordpress
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar 
fi

# Boucle pour attendre que MariaDB soit disponible
while ! mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
    counter=$((counter+1))
    if [ $counter -gt $max_retries ]; then
        echo "Failed to connect to MariaDB after $max_retries attempts!"
        exit 1
    fi
    echo "MariaDB is unavailable - sleeping (attempt $counter/$max_retries)"
    sleep 5
done

echo "MariaDB is up - proceeding with WordPress configuration"

# Vérifier si wp-config.php existe déjà
if [ ! -f /var/www/html/wp-config.php ]; then
    # Générer des clés secrètes WordPress
    KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    
    # Créer wp-config.php
    cat > /var/www/html/wp-config.php << EOF
<?php
define('DB_NAME', '${WORDPRESS_DB_NAME}');
define('DB_USER', '${WORDPRESS_DB_USER}');
define('DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}');
define('DB_HOST', '${WORDPRESS_DB_HOST}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

${KEYS}

\$table_prefix = 'wp_';

define('WP_DEBUG', false);

if ( ! defined('ABSPATH') ) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOF
    echo "WordPress configuration file created"
    chown -R www-data:www-data /var/www/html
fi

# Configurer WordPress avec wp-cli
if [ -f wp-cli.phar ]; then
    echo "Configuring WordPress settings with wp-cli..."
    
    # Installer WordPress (si ce n'est pas déjà fait)
    php wp-cli.phar core install \
        --url="https://aduriez.42.fr" \
        --title="My WordPress Site" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # Ajouter un utilisateur WordPress
    if [ -z "${WORDPRESS_USER}" ] || [ -z "${WORDPRESS_USER_EMAIL}" ] || [ -z "${WORDPRESS_USER_PASSWORD}" ]; then
        echo "Error: Missing required environment variables for user creation (WORDPRESS_USER, WORDPRESS_USER_EMAIL, WORDPRESS_USER_PASSWORD)."
        exit 1
    fi

    php wp-cli.phar user create \
        "${WORDPRESS_USER}" "${WORDPRESS_USER_EMAIL}" \
        --role=subscriber \
        --user_pass="${WORDPRESS_USER_PASSWORD}" \
        --allow-root
    echo "WordPress has been configured with wp-cli."
else
    echo "wp-cli.phar not found. Skipping WordPress configuration."
fi

# Lancer PHP-FPM
echo "WordPress is running..."
exec php-fpm7.4 -F