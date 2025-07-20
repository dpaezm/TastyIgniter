#!/bin/sh
set -e

echo "--- INICIANDO ENTRYPOINT SCRIPT ---"

echo "--- Limpiando cachés... ---"
CACHE_DRIVER=file php artisan config:clear
CACHE_DRIVER=file php artisan route:clear
CACHE_DRIVER=file php artisan view:clear

echo "--- Verificando existencia de tabla 'migrations' con migrate:status ---"

# Plan B: robusto y probado en entornos Laravel reales
php artisan migrate:status >/dev/null 2>&1
CHECK_RESULT=$?

echo "--- Resultado del chequeo: $CHECK_RESULT ---"

if [ "$CHECK_RESULT" != "0" ]; then
  echo "--- ❌ No se encontró la tabla 'migrations'. Ejecutando instalación completa... ---"
  php artisan igniter:install --no-interaction
  php artisan storage:link
else
  echo "--- ✅ Tabla 'migrations' encontrada. Ejecutando migraciones... ---"
  php artisan migrate --force
  php artisan storage:link
fi

echo "--- Instalación/Migración completada. Iniciando servidor ---"
exec php artisan serve --host=0.0.0.0 --port=3000
