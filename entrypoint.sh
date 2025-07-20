#!/bin/sh
set -e

echo "--- ENTRYPOINT iniciado ---"
echo "--- Variables de entorno cargadas ---"
env | grep -E '^(APP_|DB_|CACHE_|SESSION_)'

# Forzamos drivers simples para evitar errores si aún no está migrada la base de datos
export CACHE_DRIVER=file
export SESSION_DRIVER=file

APP_DIR="/var/www/html"
cd "$APP_DIR"

# Generar .env si no existe
if [ ! -f "$APP_DIR/.env" ]; then
  echo "--- .env no encontrado, creando uno nuevo ---"
  cp .env.example .env
fi

# Asegurar que APP_KEY está presente
if ! grep -q "^APP_KEY=" .env && [ -n "$APP_KEY" ]; then
  echo "APP_KEY=$APP_KEY" >> .env
  echo "--- APP_KEY añadido al .env automáticamente ---"
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

# Limpiar cachés
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- Arrancando php-fpm y nginx... ---"
php-fpm &

# Esperar a que php-fpm cree el socket antes de lanzar nginx
while [ ! -S /var/run/php/php-fpm.sock ]; do
  echo "Esperando php-fpm.sock..."
  sleep 1
done

exec nginx -g "daemon off;"
