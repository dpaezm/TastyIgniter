# Imagen base única y completa
FROM php:8.3-fpm

# Instalar todas las dependencias
RUN apt-get update && apt-get install -y \
    git unzip zip curl nodejs npm \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY . .

RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run prod

RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 80

# ----> ¡ESTA ES LA LÍNEA QUE CAMBIAS! <----
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=80"]
