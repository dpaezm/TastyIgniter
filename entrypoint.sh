#!/bin/sh
set -e

echo "--- ENTRYPOINT iniciado ---"

APP_DIR="/var/www/html"
cd "$APP_DIR"

echo "--- Variables de entorno cargadas ---"
env | grep -E "APP|DB|CACHE|SESSION"

export CACHE_DRIVER=file
export SESSION_DRIVER=file

# Crear .env si no existe
if [ ! -f "$APP_DIR/.env" ]; then
  echo "--- .env no encontrado, creando uno nuevo ---"
  cp .env.example .env

  # Añadir APP_KEY si viene por entorno
  if [ ! -z "$APP_KEY" ]; then
    echo "APP_KEY=$APP_KEY" >> .env
    echo "--- APP_KEY añadido al .env automáticamente ---"
  else
    php artisan key:generate --force || true
  fi
fi

# Instalación inicial si no hay migraciones
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación por primera vez... ---"
  php artisan igniter:install --no-interaction
  php artisan storage:link
else
  echo "--- La aplicación ya está instalada. Aplicando migraciones pendientes... ---"
  php artisan migrate --force
fi

php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- Arrancando php-fpm y nginx... ---"
php-fpm -D
exec nginx -g "daemon off;"
