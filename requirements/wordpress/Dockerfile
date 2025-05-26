FROM debian:bullseye
# Mise à jour et installation des paquets nécessaires
RUN apt update && apt upgrade -y && \
    apt install -y php-fpm php-mysql wget unzip curl mariadb-client

# Créer les répertoires nécessaires
RUN mkdir -p /run/php

# Configuration de PHP-FPM
COPY www.conf /etc/php/*/fpm/pool.d/
RUN sed -i 's|listen = .*|listen = 9000|' /etc/php/*/fpm/pool.d/www.conf

# Copier le script de config WordPress
COPY wp-config-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-config-setup.sh

WORKDIR /var/www/html

EXPOSE 9000

# Lancer le script de setup qui lui-même lance PHP-FPM
CMD ["wp-config-setup.sh"]
