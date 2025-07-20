# Imagen base única y completa
FROM php:8.3-fpm

# Instalar todas las dependencias del sistema, extensiones y Composer
RUN apt-get update && apt-get install -y \
    git unzip zip curl nodejs npm \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copiar todo el código de la aplicación
COPY . .

# Instalar dependencias de PHP y Node, y construir assets
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run prod

# Establecer permisos
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

# Exponer el puerto
EXPOSE 3000

# Comando de arranque que HACE TODO: Limpia, migra, siembra y arranca.
CMD ["sh", "-c", "php artisan config:clear && php artisan migrate --force --seed && php artisan serve --host=0.0.0.0 --port=3000"]
