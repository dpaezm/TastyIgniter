# --- FASE 1: Builder ---
FROM php:8.3-fpm as builder

RUN apt-get update && apt-get install -y \
    git unzip zip curl nodejs npm \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

# Instala dependencias de PHP
RUN composer install --no-dev --optimize-autoloader

# Build del tema (CSS y JS)
WORKDIR /var/www/html/themes/tastyigniter-orange
RUN npm install 
RUN npm run build || npm run prod

# --- FASE 2: Producción ---
FROM php:8.3-fpm

apt-get install -y nginx \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml

WORKDIR /var/www/html

COPY --from=builder /var/www/html .
COPY --from=builder /var/www/html/themes/tastyigniter-orange/public /var/www/html/themes/tastyigniter-orange/public

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN chown -R www-data:www-data storage bootstrap/cache

# 🔥 Activar tema personalizado y sincronizar extensiones
# RUN php artisan extension:activate igniter.theme-orange \
# && php artisan ignite:sync \
# && php artisan config:clear \
# && php artisan view:clear
 
EXPOSE 80 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
