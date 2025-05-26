FROM debian:latest

# Mise à jour et installation de Nginx
RUN apt update && apt upgrade -y && apt install -y nginx openssl

# Copier la configuration
COPY default /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
RUN mkdir -p /etc/nginx/requirements/nginx/ssl

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/requirements/nginx/ssl/nginx.key \
    -out /etc/nginx/requirements/nginx/ssl/nginx.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=Inception/CN=aduriez.42.fr"

# Exposer le port 80
EXPOSE 443

# Démarrer Nginx avec la commande correcte
CMD ["nginx", "-g", "daemon off;"]