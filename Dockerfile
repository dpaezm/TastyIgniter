# --- FASE 1: Builder ---
# Usamos una imagen completa para compilar todo sin problemas de dependencias.
FROM php:8.3-fpm as builder

# Instalar dependencias del sistema, extensiones de PHP, Node.js y Composer
RUN apt-get update && apt-get install -y \
    git unzip zip curl nodejs npm \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copiamos todo el código ANTES de instalar para que 'artisan' esté disponible
COPY . .

# Instalar dependencias de PHP y Node
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run prod

# ---------------------------------------------------------------------

# --- FASE 2: Producción ---
# Usamos la misma imagen base para máxima compatibilidad, pero copiaremos solo lo necesario.
FROM php:8.3-fpm

# Instalar Nginx y las librerías runtime que necesitan las extensiones de PHP
RUN apt-get update && apt-get install -y nginx \
    libpng16-16 \
    libzip4 \
    libjpeg62-turbo \
    libfreetype6 \
    libicu72 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Copiar la aplicación, la configuración y las extensiones compiladas desde el builder
COPY --from=builder /app .
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Copiar nuestra configuración de Nginx y el script de arranque
COPY nginx.conf /etc/nginx/sites-enabled/default
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Establecer permisos
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Exponer el puerto 80, que es el que escuchará Nginx
EXPOSE 80

# Usar nuestro script inteligente como punto de entrada
ENTRYPOINT ["entrypoint.sh"]
