Aquí tienes el README completo **actualizado** con la sección de API corregida, **eliminando todo lo relacionado con Passport** y explicando cómo usar `igniter:api-token` como recomienda la documentación oficial:

````markdown
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

CACHE_DRIVER=database
SESSION_DRIVER=database
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

## 🧩 Acceso a la API REST (con `ti-ext-api`)

Este proyecto incluye la extensión oficial `tastyigniter/ti-ext-api`, que expone una API REST para acceder a pedidos, menús, reservas, clientes, etc.

### Cómo generar un token de acceso

Para autenticar peticiones desde Postman o herramientas como n8n, genera un token con el siguiente comando:

```bash
php artisan igniter:api-token --name=postman --email=diego@gridded.agency --admin
```

> Reemplaza el email por el de un usuario Staff registrado (ver en *Manage > Staff Members*).

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

### 🛑 No uses Passport

La extensión API oficial ya implementa Laravel Sanctum internamente. No es necesario instalar `laravel/passport` ni configurar clientes OAuth.

````

