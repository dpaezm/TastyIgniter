FROM php:8.3-cli

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    git unzip zip curl libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copiar tu código al contenedor
COPY . .

# Instalar dependencias
RUN composer install --no-dev --optimize-autoloader

# Dar permisos de escritura
RUN chown -R www-data:www-data storage bootstrap/cache

# Puerto de Laravel (servido por Artisan)
EXPOSE 80

# Iniciar Laravel con PHP built-in server
ENTRYPOINT ["sh", "/app/entrypoint.sh"]
