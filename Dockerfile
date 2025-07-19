# Fase 1: Construcción con todas las herramientas
FROM php:8.3-fpm as builder

# Instalar dependencias del sistema y Composer
RUN apt-get update && apt-get install -y \
    git unzip zip curl nodejs npm \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Instalar dependencias de PHP y Node
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --optimize-autoloader
COPY package.json package-lock.json ./
RUN npm install

# Copiar el resto de la aplicación y construir assets
COPY . .
RUN npm run prod
RUN composer dump-autoload --optimize

# ---------------------------------------------------------------------

# Fase 2: Imagen final de producción
FROM php:8.3-fpm

WORKDIR /app

# Copiar la aplicación construida y la configuración de las extensiones de PHP
COPY --from=builder /app .
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Exponer el puerto y establecer el comando de arranque
EXPOSE 3000

# Comando de arranque (para la instalación inicial)
CMD ["sh", "-c", "touch .env && php artisan igniter:install --no-interaction && php artisan serve --host=0.0.0.0 --port=3000"]
