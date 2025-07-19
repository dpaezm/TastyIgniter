# Fase 1: Construcción con todas las herramientas
FROM php:8.2-fpm as builder

# Instalar dependencias del sistema, extensiones de PHP, Node.js y Composer
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    nodejs \
    npm \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copiar solo los archivos de dependencias e instalar
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --optimize-autoloader

COPY package.json package-lock.json ./
RUN npm install

# Copiar el resto de la aplicación y construir assets
COPY . .
RUN npm run prod
RUN composer dump-autoload --optimize

# Fase 2: Imagen final de producción
FROM php:8.2-fpm-alpine

# Instalar solo las extensiones necesarias
RUN docker-php-ext-install pdo pdo_mysql exif gd intl zip mbstring xml

WORKDIR /app

# Copiar la aplicación construida desde la fase anterior
COPY --from=builder /app .

# Exponer el puerto
EXPOSE 3000

# Comando de arranque
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=3000"]
