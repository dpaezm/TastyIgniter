#!/bin/sh
set -e

echo "--- Limpieza de caché ---"
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- Migraciones y seed ---"
php artisan migrate --force --seed

echo "--- Enlace de almacenamiento ---"
php artisan storage:link

echo "--- Fase 1 completada. No arranco servidor. ---"
sleep infinity
