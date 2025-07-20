#!/bin/sh
set -e

export CACHE_DRIVER=file
export SESSION_DRIVER=file

# Crear .env si no existe
if [ ! -f .env ]; then
  echo "--- [ENTRYPOINT] Creando archivo .env desde .env.example ---"
  cp .env.example .env
fi

# Instalar si la base de datos está vacía
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación por primera vez... ---"
  php artisan igniter:install --no-interaction

  php artisan session:table
  php artisan cache:table
  php artisan migrate --force

  php artisan storage:link
else
  echo "--- La aplicación ya está instalada. Aplicando migraciones pendientes... ---"
  php artisan migrate --force
fi

php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- ¡Listo! Iniciando Nginx y PHP-FPM... ---"
php-fpm &
exec nginx -g "daemon off;"
