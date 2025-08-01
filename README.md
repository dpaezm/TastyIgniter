# TastyIgniter – Deploy automático con tema Orange

Este repositorio está preparado para hacer despliegues automáticos en producción mediante Coolify.

## 🚀 ¿Qué incluye?
- TastyIgniter + Laravel 10 + PHP 8.3
- Tema `ti-theme-orange` integrado por Composer
- NGINX y PHP-FPM listos para producción
- Migraciones automáticas con Artisan
- Publicación de assets del tema
- Activación automática del tema con `TI_THEME`

## 🧪 Requisitos de despliegue

Debes definir estas variables en Coolify o `.env`:

```env

APP_DEBUG=false
APP_ENV=production
APP_KEY=base64:
APP_NAME=
APP_URL=https:// .. gridded.agency
DB_CONNECTION=mysql
DB_DATABASE=default
DB_HOST=asgs...
DB_PASSWORD=...
DB_PORT=3306
DB_USERNAME=mariadb
LOG_CHANNEL=stderr
QUEUE_CONNECTION=sync
CACHE_DRIVER=database
SESSION_DRIVER=database
CACHE_DB_TABLE=ti_cache

´´´



```persistant storage

/var/www/html/storage
/var/www/html/extensions

´´´
