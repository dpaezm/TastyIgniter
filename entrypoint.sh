#!/bin/sh
set -e

# Asegura que el .env existe
if [ ! -f /var/www/html/.env ]; then
    echo "[entrypoint] .env no existe, copiando plantilla..."
    [ -f /var/www/html/.env.example ] && cp /var/www/html/.env.example /var/www/html/.env || touch /var/www/html/.env
fi

echo "--- INICIANDO ENTRYPOINT SCRIPT ---"
echo "--- Limpiando cachés... ---"
CACHE_DRIVER=file php artisan config:clear
CACHE_DRIVER=file php artisan route:clear
CACHE_DRIVER=file php artisan view:clear

# ✅ Flag correcto
INSTALL_FLAG="/var/www/html/.env.installed"

if [ ! -f "$INSTALL_FLAG" ]; then
  echo "--- Primera ejecución detectada. Ejecutando instalación completa... ---"
  php artisan igniter:install --no-interaction
  [ ! -L /var/www/html/public/storage ] && php artisan storage:link
  touch "$INSTALL_FLAG"
else
  echo "--- Sistema ya instalado previamente. Ejecutando migraciones... ---"
  php artisan migrate --force
  [ ! -L /var/www/html/public/storage ] && php artisan storage:link
fi

echo "--- Arrancando PHP-FPM ---"
exec php-fpm
