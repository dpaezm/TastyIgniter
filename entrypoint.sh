#!/bin/sh
set -e

echo "--- Limpiando cachés... ---"
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Creamos migraciones y seeds usando drivers seguros (file)
echo "--- Ejecutando migraciones y seeds... ---"
CACHE_DRIVER=file SESSION_DRIVER=file php artisan migrate --force --seed

php artisan storage:link

# Iniciamos app temporalmente en puerto 3000
exec php artisan serve --host=0.0.0.0 --port=3000
