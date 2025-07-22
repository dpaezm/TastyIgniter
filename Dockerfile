# --- FASE 1: BUILDER ---
FROM php:8.3-fpm as builder

# Instalar dependencias del sistema y Composer
RUN apt-get update && apt-get install -y \
    git unzip zip curl nodejs npm \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copiar código y generar vendor + assets
WORKDIR /var/www/html
COPY . .
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run prod

# --- FASE 2: PRODUCCIÓN ---
FROM php:8.3-fpm

# Instalar Nginx y dependencias necesarias
RUN apt-get update && apt-get install -y nginx \
    libpng16-16 libzip4 libjpeg62-turbo libfreetype6 libicu72 \
    && rm -rf /var/lib/apt/lists/*

# Copiar app y configuraciones desde builder
WORKDIR /var/www/html
COPY --from=builder /var/www/html .
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Copiar config nginx y script de arranque
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Ajustar permisos (de nuevo por si volviste a sobrescribir)
RUN chown -R www-data:www-data storage bootstrap/cache

# Exponer puertos de Nginx y PHP-FPM
EXPOSE 80 9000

# Entrypoint + comando por defecto
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
