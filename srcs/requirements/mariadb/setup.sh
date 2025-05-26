#!/bin/bash

# Créer le répertoire pour le socket MySQL
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# Démarrer le service MariaDB
service mariadb start

# Attendre que MariaDB soit prêt
until mysqladmin ping -uroot --silent; do
    echo "Waiting for MariaDB to be ready..."
    sleep 1
done

# Vérifier si la base de données existe déjà
DB_EXISTS=$(mysql -uroot -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" | grep "${MYSQL_DATABASE}" > /dev/null; echo "$?")

# Si la base de données n'existe pas, initialiser MariaDB
if [ "$DB_EXISTS" -ne 0 ]; then
    echo "Initializing MariaDB..."
    
    # Sécuriser l'installation MariaDB (équivalent de mysql_secure_installation)
    mysql -uroot <<-EOSQL
        SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ROOT_PASSWORD}');
        DELETE FROM mysql.user WHERE User='';
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
        CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
        CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    echo "MariaDB initialized successfully!"
else
    echo "Database already exists, skipping initialization..."
fi

# Arrêter MariaDB pour le redémarrer proprement
service mariadb stop

# Démarrer MariaDB en premier plan
exec mysqld_safe