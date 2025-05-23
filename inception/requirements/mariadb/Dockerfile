FROM mariadb:latest

# Configuration pour écouter sur toutes les interfaces
RUN echo "[mysqld]" > /etc/mysql/conf.d/my.cnf && \
    echo "bind-address = 0.0.0.0" >> /etc/mysql/conf.d/my.cnf

EXPOSE 3306

CMD ["/setup.sh"]