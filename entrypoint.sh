#!/bin/sh
set -e

echo "--- INICIANDO ENTRYPOINT SCRIPT ---"

echo "--- Limpiando cachés... ---"
# Usamos CACHE_DRIVER=file temporalmente para que Artisan no falle
CACHE_DRIVER=file php artisan config:clear
CACHE_DRIVER=file php artisan route:clear
CACHE_DRIVER=file php artisan view:clear

echo "--- Verificando existencia de tabla 'migrations' ---"

# Opción A: método elegante con PHP inline
CHECK_COMMAND=$(CACHE_DRIVER=file php -r "try { echo \\Illuminate\\Support\\Facades\\Schema::hasTable('migrations') ? 0 : 1; } catch (\\Exception \$e) { echo 1; }")

# Opción B: método robusto alternativo con artisan
# CHECK_COMMAND=$(CACHE_DRIVER=file php artisan migrate:status >/dev/null 2>&1 && echo 0 || echo 1)

echo "--- Resultado del chequeo: $CHECK_COMMAND ---"

if [ "$CHECK_COMMAND" = "1" ]; then
  echo "--- ❌ No se encontró la tabla 'migrations'. Ejecutando instalación completa... ---"
  php artisan igniter:install --no-interaction
  php artisan storage:link
else
  echo "--- ✅ Tabla 'migrations' encontrada. Ejecutando migraciones... ---"
  php artisan migrate --force
  php artisan storage:link
fi

echo "--- Instalación/Migración completada. Iniciando servidor ---"

# OPCIÓN 1: Si la imagen tiene Nginx y php-fpm
# php-fpm &
# exec nginx -g "daemon off;"

# OPCIÓN 2: Si estás usando el servidor embebido (recomendado para pruebas)
exec php artisan serve --host=0.0.0.0 --port=3000
