# Imagen base única y completa
FROM php:8.3-fpm

# Instalar dependencias
RUN apt-get update && apt-get install -y git unzip zip curl nodejs npm libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run prod
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copiamos la configuración de Nginx y PHP-FPM
COPY nginx.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

EXPOSE 80

# ----> COMANDO TEMPORAL SOLO PARA INSTALAR Y ESPERAR <----
CMD ["sh", "-c", "php artisan migrate --force --seed && php artisan storage:link && echo 'INSTALACION COMPLETADA' && sleep 3600"]
