#!/bin/sh
set -e

echo "--- ENTRYPOINT iniciado ---"

APP_DIR="/var/www/html"
cd "$APP_DIR"

# Mostrar variables clave para depuración
echo "--- Variables de entorno cargadas ---"
env | grep -E "APP|DB|CACHE|SESSION"

# Forzar drivers simples para instalación
export CACHE_DRIVER=file
export SESSION_DRIVER=file

# Si no existe .env, lo creamos desde el ejemplo
if [ ! -f "$APP_DIR/.env" ]; then
  echo "--- .env no encontrado, creando uno nuevo ---"
  cp .env.example .env
  php artisan key:generate --force || true
fi

# Añadir APP_KEY si no está en el .env pero sí como variable de entorno
if ! grep -q "APP_KEY=" .env && [ ! -z "$APP_KEY" ]; then
  echo "APP_KEY=$APP_KEY" >> .env
  echo "--- APP_KEY añadido al .env automáticamente ---"
fi

# Instalar si no hay migraciones registradas
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación por primera vez... ---"
  php artisan igniter:install --no-interaction
  php artisan storage:link
else
  echo "--- La aplicación ya está instalada. Aplicando migraciones pendientes... ---"
  php artisan migrate --force
fi

# Limpiar cachés
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Esperar al socket de PHP-FPM para evitar errores 502
for i in $(seq 1 10); do
  if [ -S /var/run/php/php-fpm.sock ]; then
    break
  fi
  echo "Esperando php-fpm.sock..."
  sleep 1
done

echo "--- Arrancando php-fpm y nginx... ---"
php-fpm &
exec nginx -g "daemon off;"
