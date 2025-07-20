#!/bin/sh
set -e

# Limpiamos cachés por si acaso
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Verificamos si la instalación ya está hecha mirando si existe la tabla 'migrations'
# Forzamos CACHE_DRIVER=file solo para este chequeo para evitar el error del huevo y la gallina
CHECK_COMMAND=$(CACHE_DRIVER=file php -r "try { \\Illuminate\\Support\\Facades\\Schema::hasTable('migrations'); echo 0; } catch (\\Exception \$e) { echo 1; }")

if [ "$CHECK_COMMAND" = "1" ]; then
  echo "--- Base de datos vacía. Ejecutando instalación por primera vez... ---"
  php artisan igniter:install --no-interaction
  php artisan storage:link
else
  echo "--- La aplicación ya está instalada. Aplicando migraciones pendientes... ---"
  php artisan migrate --force
fi

# Iniciar PHP-FPM en segundo plano
php-fpm &

# Iniciar Nginx en primer plano (este será el proceso principal del contenedor)
exec nginx -g "daemon off;"
