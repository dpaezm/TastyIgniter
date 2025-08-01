#!/bin/bash
set -e

# Esperar a que la base de datos esté lista
echo "Esperando a que la base de datos esté disponible..."
until mysqladmin ping -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" --silent; do
  sleep 2
done
echo "Base de datos disponible ✔"

echo "--- ENTRYPOINT iniciado ---"
env | grep -E '^(APP_|DB_|CACHE_|SESSION_|TI_THEME)'

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

# Crear tablas necesarias para drivers database antes de migraciones o install
if [[ "$CACHE_DRIVER" == "database" ]]; then
  echo "--- Generando tabla de caché ---"
  php artisan cache:table || true
fi

if [[ "$SESSION_DRIVER" == "database" ]]; then
  echo "--- Generando tabla de sesiones ---"
  php artisan session:table || true
fi

# Aplicar migraciones necesarias
echo "--- Ejecutando migraciones previas ---"
php artisan migrate --force || true

# Instalar si no está instalado
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación inicial ---"
  php artisan igniter:install --no-interaction
fi

# Activar tema personalizado
php artisan igniter:util set theme --theme=$TI_THEME || true

# Limpieza de cachés
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- Arrancando php-fpm y nginx... ---"
php-fpm &
exec nginx -g "daemon off;"
