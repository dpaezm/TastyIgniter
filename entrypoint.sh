#!/bin/sh
set -e

echo "--- ENTRYPOINT iniciado ---"

# Forzamos drivers simples para evitar errores si aún no está migrada la base de datos
export CACHE_DRIVER=file
export SESSION_DRIVER=file

# Ruta absoluta del proyecto (ajustar si cambia el WORKDIR en el Dockerfile)
APP_DIR="/var/www/html"

cd "$APP_DIR"

# Generar archivo .env si no existe (Coolify puede inyectar variables pero no crea el archivo)
if [ ! -f "$APP_DIR/.env" ]; then
  echo "--- .env no encontrado, creando uno nuevo ---"
  cp .env.example .env
  php artisan key:generate --force
fi

# Instalación inicial (sólo si la base de datos aún no está configurada)
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación por primera vez... ---"
  php artisan igniter:install --no-interaction
  php artisan storage:link
else
  echo "--- La aplicación ya está instalada. Aplicando migraciones pendientes... ---"
  php artisan migrate --force
fi

# Limpiar cachés por si hay cambios en entorno o rutas
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- Arrancando php-fpm y nginx... ---"
php-fpm &

# Mantener contenedor vivo con Nginx en primer plano
exec nginx -g "daemon off;"
