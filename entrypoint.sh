#!/bin/bash
set -e

echo "--- ENTRYPOINT iniciado ---"
env | grep -E '^(APP_|DB_|CACHE_|SESSION_|TI_THEME)'

# Configura drivers
export CACHE_DRIVER=file
export SESSION_DRIVER=file

cd /var/www/html

# Crear .env si no existe
if [ ! -f ".env" ]; then
  echo "--- .env no encontrado, creando uno nuevo ---"
  cp .env.example .env
fi

# Añadir APP_KEY si está disponible como variable
if ! grep -q "^APP_KEY=" .env && [ -n "$APP_KEY" ]; then
  echo "APP_KEY=$APP_KEY" >> .env
  echo "--- APP_KEY añadido al .env automáticamente ---"
fi

# Enlace de storage
[ ! -e public/storage ] && php artisan storage:link || true

# Registrar extensiones
php artisan package:discover || true

# Activar tema personalizado
php artisan igniter:util set theme --theme=$TI_THEME || true

# Instalar si no está instalado, o aplicar migraciones
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación por primera vez... ---"
  php artisan igniter:install --no-interaction
else
  echo "--- Aplicando migraciones pendientes ---"
  php artisan migrate --force
fi

# Limpieza de cachés
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- Arrancando php-fpm y nginx... ---"
php-fpm &
exec nginx -g "daemon off;"
