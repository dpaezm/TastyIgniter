#!/bin/sh
# Salir inmediatamente si un comando falla
set -e

echo "--- Limpiando cachés de configuración de Laravel... ---"
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Ejecutamos las migraciones y los seeds FORZANDO el uso de caché de archivos para evitar el error.
# Esto crea TODAS las tablas necesarias, incluyendo ti_cache y ti_sessions.
echo "--- Ejecutando migraciones y seeds de la base de datos... ---"
CACHE_DRIVER=file SESSION_DRIVER=file php artisan migrate --force --seed

# Creamos el enlace simbólico para el almacenamiento
echo "--- Creando enlace de almacenamiento... ---"
php artisan storage:link

# Ahora que todo está instalado, la aplicación ya puede arrancar normalmente.
echo "--- ¡Instalación completa! Iniciando el servidor de la aplicación... ---"
exec php artisan serve --host=0.0.0.0 --port=3000
