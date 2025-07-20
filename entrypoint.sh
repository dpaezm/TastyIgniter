#!/bin/sh
set -e

###############################################
# 1️⃣  GARANTIZAR QUE EXISTE /var/www/html/.env
###############################################
if [ ! -f /var/www/html/.env ]; then
    echo "[entrypoint] .env no existe, copiando plantilla..."
    # Usa .env.example si está en la imagen; si no, crea uno vacío
    if [ -f /var/www/html/.env.example ]; then
        cp /var/www/html/.env.example /var/www/html/.env
    else
        touch /var/www/html/.env
    fi
fi

echo "--- INICIANDO ENTRYPOINT SCRIPT ---"

echo "--- Limpiando cachés... ---"
CACHE_DRIVER=file php artisan config:clear
CACHE_DRIVER=file php artisan route:clear
CACHE_DRIVER=file php artisan view:clear

# Usamos un flag simple para evitar múltiples instalaciones
INSTALL_FLAG="/app/.env.installed"

if [ ! -f "$INSTALL_FLAG" ]; then
  echo "--- Primera ejecución detectada. Ejecutando instalación completa... ---"
  php artisan igniter:install --no-interaction
  php artisan storage:link
  touch "$INSTALL_FLAG"
else
  echo "--- Sistema ya instalado previamente. Ejecutando migraciones... ---"
  php artisan migrate --force
  php artisan storage:link
fi

echo "--- Arrancando servidor ---"
exec php artisan serve --host=0.0.0.0 --port=3000
