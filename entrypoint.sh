#!/bin/sh
set -e

# Opcional: Limpiar cachés en cada arranque para asegurar frescura
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- ¡Listo! Iniciando Nginx y PHP-FPM... ---"

# Iniciar PHP-FPM en segundo plano
php-fpm &

# Iniciar Nginx en primer plano (este es el proceso principal)
exec nginx -g "daemon off;"
