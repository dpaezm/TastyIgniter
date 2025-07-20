#!/bin/sh
set -e

# Limpiamos las cachés para asegurarnos de que se usan las variables de entorno frescas de Coolify
echo "--- Limpiando cachés de Laravel... ---"
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Forzamos la ejecución de las migraciones. Laravel usará las variables DB_* inyectadas por Coolify.
echo "--- Ejecutando migraciones de la base de datos... ---"
php artisan migrate --force --seed

# Creamos el enlace simbólico para el almacenamiento público.
echo "--- Creando enlace de almacenamiento... ---"
php artisan storage:link

# Arrancamos el servidor. Usará la APP_KEY que Coolify le ha inyectado.
echo "--- ¡Listo! Arrancando el servidor de la aplicación... ---"
exec php artisan serve --host=0.0.0.0 --port=80
