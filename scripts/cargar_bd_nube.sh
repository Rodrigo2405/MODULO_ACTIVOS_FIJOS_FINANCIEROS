#!/usr/bin/env bash
# Carga los 2 scripts SQL en la BD de la nube (Supabase).
# Uso:  export DATABASE_URL='postgresql://...'   &&   bash scripts/cargar_bd_nube.sh
# OJO: ple_sunat.sql hace DROP SCHEMA ple CASCADE -> volver a correrlo BORRA los datos.
set -euo pipefail
: "${DATABASE_URL:?Define DATABASE_URL con la cadena de conexion de Supabase}"

# En la nube no se puede crear la BD ni usar \connect: se quitan esas lineas.
sed '/^SELECT .CREATE DATABASE/,/^\\encoding UTF8/d' db/ple_sunat.sql > /tmp/ple_sunat_nube.sql

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f /tmp/ple_sunat_nube.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/ple_activos_fijos.sql
echo "BD cargada."
