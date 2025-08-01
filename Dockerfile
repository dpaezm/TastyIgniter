# --- FASE 1: BUILDER ---
FROM php:8.3-fpm AS builder

# Instala dependencias necesarias
RUN apt-get update && apt-get install -y \
    git unzip zip curl libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copia código fuente
WORKDIR /var/www/html
COPY . .

# Instala dependencias (incluyendo el tema)
RUN composer require tastyigniter/ti-theme-orange -W && \
    composer install --no-dev --optimize-autoloader && \
    php artisan vendor:publish --tag=laravel-assets --ansi --force


# --- FASE 2: PRODUCCIÓN ---
FROM php:8.3-fpm

# Instala nginx y dependencias necesarias
RUN apt-get update && apt-get install -y \
    nginx mariadb-client \
    libpng16-16 libzip4 libjpeg62-turbo libfreetype6 libicu72 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Copia código fuente ya listo desde builder
COPY --from=builder /var/www/html .

# Configuración PHP
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Configuración NGINX
COPY nginx.conf /etc/nginx/nginx.conf

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Permisos necesarios
RUN chown -R www-data:www-data storage bootstrap/cache extensions

EXPOSE 80 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
