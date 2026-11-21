# Modulo de Control de Activos Fijos (ERP)

Stack: PostgreSQL (`ple_sunat`, esquema `ple`) · Supabase + NestJS · API REST · Next.js · Docker · monolito modular

## Estructura
```
db/        ple_sunat.sql (base) y ple_activos_fijos.sql (modulo)
scripts/   utilidades de DevOps
backend/   (Backend)
frontend/  (Frontend)
```

## BD local
```bash
cp .env.example .env     # editar POSTGRES_PASSWORD
docker compose up -d
docker compose exec db psql -U postgres -d ple_sunat -c "\dt ple.*"
```
Reiniciar desde cero (borra datos): `docker compose down -v && docker compose up -d`

## BD en la nube (Supabase)
```bash
export DATABASE_URL='postgresql://...'
bash scripts/cargar_bd_nube.sh
```

## Ramas
`main` (estable, por Pull Request) · `develop` (integracion) · `feature/<tarea>`
