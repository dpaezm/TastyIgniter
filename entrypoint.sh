#!/bin/bash
set -e

echo "--- ENTRYPOINT iniciado ---"

env | grep -E '^(APP_|DB_|CACHE_|SESSION_|TI_THEME)'

export CACHE_DRIVER=file
export SESSION_DRIVER=file

cd /var/www/html

# Generar .env si no existe
if [ ! -f ".env" ]; then
  echo "--- .env no encontrado, creando uno nuevo ---"
  cp .env.example .env
fi

# Asegurar que APP_KEY esté presente
if ! grep -q "^APP_KEY=" .env && [ -n "$APP_KEY" ]; then
  echo "APP_KEY=$APP_KEY" >> .env
  echo "--- APP_KEY añadido al .env automáticamente ---"
fi

# Enlace a storage público
[ ! -e public/storage ] && php artisan storage:link || true

# 🔥 Activar tema y sincronizar extensiones
php artisan package:discover || true
php artisan igniter:util set theme --theme=tastyigniter-orange || true

# Instalación o migraciones
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación por primera vez... ---"
  php artisan igniter:install --no-interaction
else
  echo "--- Aplicando migraciones pendientes ---"
  php artisan migrate --force
fi

php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- Arrancando php-fpm y nginx... ---"
php-fpm &
exec nginx -g "daemon off;"
