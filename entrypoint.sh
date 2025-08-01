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

# Activar tema personalizado
php artisan igniter:util set theme --theme=$TI_THEME || true

# Instalar si no está instalado, o aplicar migraciones
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación por primera vez... ---"
  php artisan igniter:install --no-interaction

  # Crear tablas necesarias para sesiones/cache si están en modo database
  if [[ "$SESSION_DRIVER" == "database" ]]; then
    echo "--- Migrando tabla de sesiones (SESSION_DRIVER=database) ---"
    php artisan session:table || true
  fi

  if [[ "$CACHE_DRIVER" == "database" ]]; then
    echo "--- Migrando tabla de caché (CACHE_DRIVER=database) ---"
    php artisan cache:table || true
  fi

  php artisan migrate --force
else
  echo "--- Aplicando migraciones pendientes ---"
  php artisan migrate --force

  if [[ "$SESSION_DRIVER" == "database" ]]; then
    echo "--- Migrando tabla de sesiones (SESSION_DRIVER=database) ---"
    php artisan session:table || true
    php artisan migrate --force
  fi

  if [[ "$CACHE_DRIVER" == "database" ]]; then
    echo "--- Migrando tabla de caché (CACHE_DRIVER=database) ---"
    php artisan cache:table || true
    php artisan migrate --force
  fi
fi

# Limpieza de cachés
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "--- Arrancando php-fpm y nginx... ---"
php-fpm &
exec nginx -g "daemon off;"
