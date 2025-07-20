# --- FASE 1: Builder ---
# Usamos una imagen completa para compilar todo sin problemas de dependencias.
FROM php:8.3-fpm as builder

# Instalar dependencias del sistema y Composer
RUN apt-get update && apt-get install -y \
    git unzip zip curl nodejs npm \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run prod

# --- FASE 2: Producción ---
FROM php:8.3-fpm

# Instalar Nginx y las librerías runtime
RUN apt-get update && apt-get install -y nginx \
    libpng16-16 libzip4 libjpeg62-turbo libfreetype6 libicu72 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Copiar la aplicación, configuraciones y extensiones desde el builder
COPY --from=builder /var/www/html .
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY nginx.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Establecer permisos
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80

# ----> ¡ESTA ES LA LÍNEA FINAL PARA PRODUCCIÓN! <----
ENTRYPOINT ["entrypoint.sh"]
