#!/bin/sh

# Salir inmediatamente si un comando falla
set -e

# 1. Limpiar cualquier configuración cacheada para asegurar que se leen las variables de entorno frescas
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# 2. Comprobar si la base de datos está instalada
# Usamos un pequeño script de PHP para verificar si la tabla 'migrations' existe.
# La variable CHECK_COMMAND nos dirá si la tabla existe (código de salida 0) o no (código de salida 1).
CHECK_COMMAND=$(php -r "try { \\Illuminate\\Support\\Facades\\Schema::hasTable('migrations'); echo 0; } catch (\\Exception \$e) { echo 1; }")

# 3. Si la tabla NO existe (código de salida 1), ejecutar la instalación por primera vez
if [ "$CHECK_COMMAND" = "1" ]; then
  echo "--- PRIMERA VEZ: LA BASE DE DATOS PARECE VACÍA. INSTALANDO TASTYIGNITER... ---"
  php artisan igniter:install --no-interaction
  php artisan storage:link
  echo "--- INSTALACIÓN COMPLETADA. ---"
else
  echo "--- La base de datos ya está instalada. Ejecutando migraciones por si hay actualizaciones... ---"
  # Si ya está instalado, solo ejecutamos las migraciones por si hay alguna nueva
  php artisan migrate --force
fi

# 4. Iniciar el servidor de la aplicación
echo "--- Iniciando el servidor de la aplicación... ---"
exec php artisan serve --host=0.0.0.0 --port=3000
