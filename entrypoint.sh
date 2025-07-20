#!/bin/sh

echo "--- INICIANDO ENTRYPOINT SCRIPT ---"

# Copiar .env si no existe
if [ ! -f .env ]; then
  echo "[entrypoint] .env no existe, copiando plantilla..."
  cp .env.example .env
fi

# Generar clave si no existe
if ! grep -q "APP_KEY=base64" .env; then
  echo "[entrypoint] Generando APP_KEY..."
  php artisan key:generate
fi

# Migraciones y caches
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan migrate --force

# Lanzar servidor integrado
echo "--- Arrancando Laravel en puerto 80 ---"
exec php artisan serve --host=0.0.0.0 --port=80
