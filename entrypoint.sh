#!/bin/sh
set -e

# Forzamos CACHE_DRIVER=file solo para los comandos de setup
export CACHE_DRIVER=file
export SESSION_DRIVER=file

# Verificamos si la base de datos ya está instalada
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación por primera vez... ---"
  # Usamos --no-interaction para que use las variables de entorno sin preguntar
  php artisan igniter:install --no-interaction
  php artisan storage:link
else
  echo "--- La aplicación ya está instalada. Aplicando migraciones pendientes... ---"
  php artisan migrate --force
fi

# Limpiamos las cachés antes de arrancar en modo producción
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- ¡Listo! Iniciando Nginx y PHP-FPM... ---"
php-fpm &
exec nginx -g "daemon off;"
