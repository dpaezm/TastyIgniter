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

# ====================================================================
# ✅ INICIO DEL BLOQUE DE PERMISOS REFORZADO (AL PRINCIPIO)
# ====================================================================
echo "--- Asegurando permisos de directorios de escritura ---"
# Creamos las carpetas que podrían no existir en un volumen nuevo
mkdir -p storage/framework/{sessions,views,cache/data}
mkdir -p storage/logs
mkdir -p storage/app/public/media
# Damos propiedad a todos los directorios que Laravel/TastyIgniter necesita para escribir.
chown -R www-data:www-data storage bootstrap/cache public
# Aseguramos que los permisos sean correctos (lectura/escritura para el propietario y grupo)
chmod -R 775 storage bootstrap/cache
# ====================================================================
# ✅ FIN DEL BLOQUE
# ====================================================================

# ... (El resto de tu script de limpieza de caché y comandos de Artisan permanece igual) ...

echo "--- Realizando limpieza profunda de la caché ---"
rm -f bootstrap/cache/packages.php
rm -f bootstrap/cache/services.php
rm -f bootstrap/cache/config.php

echo "--- Redescubriendo paquetes y extensiones (ignorando errores) ---"
php artisan package:discover || true

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

# Todos los comandos de Artisan se ejecutan con '|| true' para ignorar el bug
echo "--- Ejecutando comandos de inicialización (ignorando errores) ---"
php artisan storage:link || true
php artisan migrate --force || true
php artisan igniter:up --force || true

if [[ "$CACHE_DRIVER" == "database" ]]; then
  php artisan cache:table || true
fi
if [[ "$SESSION_DRIVER" == "database" ]]; then
  php artisan session:table || true
fi

# El comando de instalación puede fallar si ya está instalado, así que lo ignoramos
if ! php artisan migrate:status > /dev/null 2>&1; then
  echo "--- Base de datos vacía. Ejecutando instalación inicial ---"
  php artisan igniter:install --no-interaction || true
fi

php artisan install:api --no-interaction || true
php artisan igniter:util set theme --theme=$TI_THEME || true

echo "--- Limpieza final de cachés (ignorando errores) ---"
php artisan config:clear || true
php artisan route:clear || true
php artisan view:clear || true

echo "--- Arrancando php-fpm y nginx... ---"
php-fpm &
exec nginx -g "daemon off;"