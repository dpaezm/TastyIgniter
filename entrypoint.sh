#!/bin/sh
set -e

php artisan config:clear
php artisan route:clear
php artisan view:clear

php artisan storage:link

echo "--- Arrancando servidor en producción ---"
exec php artisan serve --host=0.0.0.0 --port=3000
