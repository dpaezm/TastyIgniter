Perfecto, aquí tienes la versión actualizada del README con la sección adicional sobre la API REST:

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
