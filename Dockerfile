# --- FASE 1: Builder ---
FROM php:8.3-fpm as builder

ENV COMPOSER_ALLOW_SUPERUSER=1

# Instalar dependencias del sistema, PHP, Node.js y Composer
RUN apt-get update && apt-get install -y \
    git unzip zip curl nodejs npm \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Establecer el mismo directorio de trabajo en ambas fases
WORKDIR /var/www/html

# Copiar todo el proyecto
COPY . .

# Instalar dependencias de PHP y compilar assets
RUN composer install --no-dev --optimize-autoloader \
    && npm install \
    && npm run prod \
    && rm -rf node_modules

# ---------------------------------------------------------------------

# --- FASE 2: Producción ---
FROM php:8.3-fpm

# Instalar Nginx y librerías runtime de PHP
RUN apt-get update && apt-get install -y nginx \
    libpng16-16 libzip4 libjpeg62-turbo libfreetype6 libicu72 \
    && rm -rf /var/lib/apt/lists/*

# Mismo directorio de trabajo
WORKDIR /var/www/html

# Copiar aplicación y configuración desde builder
COPY --from=builder /var/www/html /var/www/html
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Copiar configuración Nginx y entrypoint
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Asignar permisos
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Exponer puerto HTTP
EXPOSE 80

# Entrypoint personalizado
ENTRYPOINT ["entrypoint.sh"]

# Fallback por si falla el entrypoint
CMD ["php-fpm"]
