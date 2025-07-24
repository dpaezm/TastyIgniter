# --- FASE 1: BUILDER ---
FROM php:8.3-fpm AS builder

# Instala dependencias necesarias para compilar extensiones y assets
RUN apt-get update && apt-get install -y \
    git unzip zip curl nodejs npm \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copia todo el código fuente
WORKDIR /var/www/html
COPY . .

# Instala dependencias PHP
RUN composer install --no-dev --optimize-autoloader

# Build de assets del tema gridded_agency-orange (si usa npm)
WORKDIR /var/www/html/themes/gridded_agency-orange
RUN [ -f package.json ] && npm install && npm run build || echo "No assets to build"

# --- FASE 2: PRODUCCIÓN ---
FROM php:8.3-fpm

# Instala nginx y librerías necesarias (sin compilación)
RUN apt-get update && apt-get install -y nginx \
    libpng16-16 libzip4 libjpeg62-turbo libfreetype6 libicu72 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Copia código PHP y vendor desde builder
COPY --from=builder /var/www/html .

# Copia assets del tema si existen
COPY --from=builder /var/www/html/themes/gridded_agency-orange/public /var/www/html/public/themes/gridded_agency-orange

# Configura PHP
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Configuración de NGINX
COPY nginx.conf /etc/nginx/nginx.conf

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Permisos necesarios
RUN chown -R www-data:www-data storage bootstrap/cache themes extensions

EXPOSE 80 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
