#!/bin/sh
set -e

echo "--- ENTRYPOINT iniciado ---"
echo "--- Variables de entorno cargadas ---"
env | grep -E '^(APP_|DB_|CACHE_|SESSION_|LOG_)?'

APP_DIR="/var/www/html"
cd "$APP_DIR"

# Forzar drivers simples para evitar errores en primeras ejecuciones
export CACHE_DRIVER=file
export SESSION_DRIVER=file
export LOG_CHANNEL=stderr

# Crear .env si no existe
if [ ! -f ".env" ]; then
  echo "--- .env no encontrado. Creando uno nuevo desde .env.example ---"
  cp .env.example .env
fi

# Añadir APP_KEY si falta y se define por env
if ! grep -q "^APP_KEY=" .env && [ -n "$APP_KEY" ]; then
  echo "--- APP_KEY no encontrado en .env. Añadiéndolo... ---"
  echo "APP_KEY=$APP_KEY" >> .env
fi

# Comprobar si hay migraciones pendientes o base de datos vacía
echo "--- Verificando estado de migraciones ---"
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación completa... ---"
  php artisan igniter:install --no-interaction || true
  php artisan storage:link || true
else
  echo "--- Aplicando migraciones pendientes ---"
  php artisan migrate --force || true
fi

# Limpiar y regenerar cachés
php artisan config:clear || true
php artisan route:clear || true
php artisan view:clear || true

php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

# Asegurar permisos correctos
echo "--- Ajustando permisos en storage y bootstrap/cache ---"
chown -R www-data:www-data storage bootstrap/cache || true
chmod -R ug+rwX storage bootstrap/cache || true

echo "--- Iniciando servicios: php-fpm + nginx ---"
php-fpm &

exec nginx -g "daemon off;"
