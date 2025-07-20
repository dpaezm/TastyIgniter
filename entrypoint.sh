#!/bin/sh
set -e

# Copiamos el .env.example para que el instalador tenga un archivo físico con el que trabajar
echo "--- [ENTRYPOINT] Creando archivo .env desde la plantilla... ---"
cp .env.example .env

# Sustituimos los valores del .env con las variables de entorno que nos pasa Coolify
# Esto es crucial para que la instalación use la base de datos correcta.
sed -i "s|APP_KEY=.*|APP_KEY=${APP_KEY}|g" .env
sed -i "s|APP_URL=.*|APP_URL=${APP_URL}|g" .env
sed -i "s|DB_HOST=.*|DB_HOST=${DB_HOST}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_DATABASE}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USERNAME}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|g" .env

# Ahora sí, la instalación encontrará un .env y las variables correctas
echo "--- [ENTRYPOINT] Ejecutando instalación... ---"
php artisan igniter:install --no-interaction
php artisan storage:link

# Limpiamos las cachés
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- [ENTRYPOINT] ¡Listo! Iniciando Nginx y PHP-FPM... ---"
php-fpm &
exec nginx -g "daemon off;"
