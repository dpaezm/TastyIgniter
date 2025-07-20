# Usamos una única imagen base completa para máxima compatibilidad
FROM php:8.3-fpm

# Instalar todas las dependencias del sistema de una vez
RUN apt-get update && apt-get install -y \
    git unzip zip curl nodejs npm \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# ---> ¡EL CAMBIO CLAVE! Copiamos todo el código ANTES de instalar dependencias <---
COPY . .

# Ahora ejecutamos la instalación de dependencias, que ya encontrará el archivo 'artisan'
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run prod

# Establecer permisos
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

# Copiar y hacer ejecutable nuestro script de arranque inteligente
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Exponer el puerto
EXPOSE 3000

# Usar el script como punto de entrada
ENTRYPOINT ["entrypoint.sh"]
