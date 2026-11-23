# Backend: API de Activos Fijos

NestJS + PostgreSQL con el paquete `pg` y SQL directo (esquema `ple`). Sin ORM.

## Arranque

```bash
cd backend
cp .env.example .env      # completar DATABASE_URL
npm install
npm run start:dev         # desarrollo
npm run build && node dist/main   # producción
```

Escucha en `0.0.0.0:3001` (variable `PORT`). Prefijo: `/api/v1`. CORS habilitado.

## Variables de entorno

| Variable | Uso |
|---|---|
| `DATABASE_URL` | Cadena de conexión de PostgreSQL (local o Supabase Session pooler) |
| `PORT` | Puerto de la API, por defecto 3001 |
| `DB_SSL` | `true` solo si la nube exige SSL (`ssl: { rejectUnauthorized: false }`) |

## Datos de prueba (base local)

La base no trae empresa, áreas, ubicaciones ni trabajadores. Para cargarlos (desde la raíz del repositorio):

```bash
docker compose exec -T db psql -U postgres -d ple_sunat < backend/sql/datos_prueba.sql
```

Crea la empresa `empresa_id = 1` (RUC 20123456789), 3 áreas, 3 ubicaciones, 3 trabajadores y 1 proveedor.

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/v1/health` | Hace `select 1` a la base. `200 { "estado": "ok", "base_datos": "ok" }` o `503` |
| GET | `/api/v1/activos-fijos/clases` | Clases de activo vigentes: `{ "data": [...] }` |
| GET | `/api/v1/activos-fijos?page=1&limit=50` | Lista paginada (máx. 100): `{ "data", "page", "limit", "total" }` |
| GET | `/api/v1/activos-fijos/:id` | Un activo. `404` si no existe |
| POST | `/api/v1/activos-fijos` | Alta mínima. Responde `201` con el activo creado |

### POST /api/v1/activos-fijos

Obligatorios: `empresa_id`, `descripcion`, `clase_activo_id`, `fecha_adquisicion` (AAAA-MM-DD), `costo_adquisicion`.

Opcionales: `marca`, `modelo`, `serie_placa`, `fecha_inicio_uso`, `valor_residual`, `vida_util_meses`, `tasa_tributaria`, `metodo_depreciacion`, `tipo_activo_fijo`, `estado_activo_fijo`, `proveedor_id`, `area_id`, `ubicacion_id`, `custodio_id`.

- El `codigo_patrimonial` lo genera el backend (`AF-0001`, `AF-0002`... por empresa).
- El activo nuevo queda con `situacion = "P"` (pendiente de aprobación).
- Si no se envían `vida_util_meses` y `tasa_tributaria`, la base los toma de la clase.

```json
{
  "empresa_id": 1,
  "descripcion": "Laptop Lenovo ThinkPad",
  "clase_activo_id": 6,
  "fecha_adquisicion": "2026-11-01",
  "costo_adquisicion": "4500.00",
  "marca": "Lenovo",
  "serie_placa": "PF-123456"
}
```

### Formato

- JSON en `snake_case`; importes como texto con 2 decimales (`"4500.00"`); fechas `AAAA-MM-DD`.
- Errores: `{ "codigo", "mensaje", "detalle" }` con HTTP 400, 404 o 409. Un 409 `REGLA_NEGOCIO` o un 400 `REGLA_INCUMPLIDA` es una regla de la base (trigger o restricción), no un fallo.
