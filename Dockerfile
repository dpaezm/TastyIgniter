# ---------- FASE 1 : BUILDER ----------
FROM php:8.3-fpm AS builder

# extensiones de PHP, Composer, etc.
RUN apt-get update && apt-get install -y \
    git unzip zip curl libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev libonig-dev libxml2-dev libicu-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install gd pdo pdo_mysql exif intl zip mbstring xml

# Composer ya copiado
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

# 1) instala dependencias y genera autoloader optimizado
RUN composer install --no-dev --optimize-autoloader --classmap-authoritative

# 2) publica assets **DESPUÉS** de tener vendor/
RUN php artisan vendor:publish --tag=laravel-assets --ansi --force

# 3) refresca TI para que registre la extensión
RUN php artisan igniter:util refresh --ansi --no-interaction

# 4) (opcional) purga cachés para que la imagen arranque limpia
RUN php artisan config:clear && php artisan route:clear && php artisan cache:clear

RUN chown -R www-data:www-data /var/www/html


# ---------- FASE 2 : RUNTIME ----------
FROM php:8.3-fpm

RUN apt-get update && apt-get install -y \
    nginx mariadb-client \
    libpng16-16 libzip4 libjpeg62-turbo libfreetype6 libicu72 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# ❶ Copiamos TODO el árbol de la app, **incluyendo vendor/**
COPY --from=builder /var/www/html .

# ❷ Copiamos los ini de PHP y las extensiones ya compiladas
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN chown -R www-data:www-data storage bootstrap/cache || true

EXPOSE 80 9000
ENTRYPOINT ["entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]