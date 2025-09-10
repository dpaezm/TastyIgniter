# TastyIgniter – Deploy automático con tema Orange

Este repositorio está preparado para hacer despliegues automáticos en producción mediante [Coolify](https://coolify.io/).

## 🚀 ¿Qué incluye?

- TastyIgniter + Laravel 10 + PHP 8.3
- Tema `ti-theme-orange` integrado por Composer
- NGINX y PHP-FPM listos para producción
- Migraciones automáticas con Artisan
- Publicación de assets del tema
- Activación automática del tema con `TI_THEME`
- `entrypoint.sh` personalizado que gestiona APP_KEY, migraciones, instalación inicial y activación del tema
- No requiere temas o extensiones locales: todo gestionado por Composer

## 🧪 Requisitos de despliegue

New resource - Public repository

Debes definir estas variables en Coolify (o en un archivo `.env` si haces despliegue manual):

```env
APP_DEBUG=false
APP_ENV=production
APP_KEY=base64:            # Puedes dejarlo vacío y se generará uno automáticamente si el sistema no está instalado
APP_NAME=Beautiful Parrilla
APP_URL=https://beautiful-app.gridded.agency

DB_CONNECTION=mysql
DB_DATABASE=default
DB_HOST=mariadb
DB_USERNAME=mariadb
DB_PASSWORD=****
DB_PORT=3306

LOG_CHANNEL=stderr
QUEUE_CONNECTION=sync

CACHE_DRIVER=file
SESSION_DRIVER=file
CACHE_DB_TABLE=ti_cache

TI_THEME=igniter-orange
```

> ℹ️ `TI_THEME` se usa para activar automáticamente el tema tras la instalación. Puedes cambiarlo si usas otro.

## 💾 Volúmenes persistentes

En la sección **Persistent Storage** de Coolify, define estos directorios para evitar pérdida de datos al actualizar:

```plaintext
/var/www/html/storage
/var/www/html/extensions
# /var/www/html/themes ← opcional si los temas se editan desde el panel
```

## 📝 Cómo funciona el entrypoint

El script `entrypoint.sh` se encarga de:

1. Esperar a que la base de datos esté lista
2. Crear `.env` si no existe
3. Añadir `APP_KEY` si no está presente
4. Crear enlace `public/storage`
5. Descubrir paquetes y extensiones (`package:discover`)
6. Activar el tema definido en `TI_THEME`
7. Ejecutar instalación inicial (`igniter:install`) si la base de datos está vacía
8. Ejecutar migraciones pendientes
9. Crear tablas `sessions` y `cache` si usas `SESSION_DRIVER=database` o `CACHE_DRIVER=database`
10. Limpiar cachés (`config`, `route`, `view`)
11. Iniciar `php-fpm` y `nginx`

---

## 🧩 Instalación opcional: API REST (`ti-ext-api`)

Si quieres exponer una API para acceder a pedidos, menús, clientes, etc., puedes instalar la extensión oficial `tastyigniter/ti-ext-api`.

### 1. Añadir Passport y la extensión API por Composer

```bash
composer require laravel/passport
composer require tastyigniter/ti-ext-api -W
```

### 2. Registrar el service provider en `config/app.php`

Abre `config/app.php` y añade al final del array `'providers'`:

```php
Laravel\Passport\PassportServiceProvider::class,
```

### 3. Commit y redeploy

```bash
git add composer.json composer.lock config/app.php
git commit -m "Instalar API y Passport para TastyIgniter"
git push
```

En Coolify, haz redeploy.

### 4. Verifica en consola

```bash
php artisan passport:install --no-interaction
php artisan install:api --no-interaction
php artisan route:list | grep api
```

---

### 5. Uso desde Postman o n8n

1. Genera un `access_token`:

```bash
curl -X POST https://tu-dominio.com/api/token \
  -d "grant_type=personal_access" \
  -d "client_id=CLIENT_ID" \
  -d "client_secret=CLIENT_SECRET" \
  -d "scope=*"
```

2. Llama a la API:

```bash
curl -H "Authorization: Bearer TU_ACCESS_TOKEN" \
     https://tu-dominio.com/api/menus
```

---

---

## 🧩 Acceso a la API REST (con `ti-ext-api`)

Este proyecto incluye la extensión oficial `tastyigniter/ti-ext-api`, que expone una API REST para acceder a pedidos, menús, reservas, clientes, etc.

### Cómo generar un token de acceso

Para autenticar peticiones desde Postman o herramientas como n8n, genera un token con el siguiente comando:

```bash
php artisan igniter:api-token --name=postman --email=diego@gridded.agency --admin
```

> Reemplaza el email por el de un usuario Staff registrado (ver en _Manage > Staff Members_).

Este comando devuelve un `access_token` listo para usar.

### Cómo usar el token

En tus llamadas HTTP añade el token en el header `Authorization`:

```http
Authorization: Bearer TU_ACCESS_TOKEN
```

Ejemplo con `curl`:

```bash
curl -H "Authorization: Bearer 1|ABCDEF..." \
     https://tu-dominio.com/api/menus
```

Puedes consultar todos los endpoints disponibles con:

```bash
php artisan route:list | grep api
```

---
