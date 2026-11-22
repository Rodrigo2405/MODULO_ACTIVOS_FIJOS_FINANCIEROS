-- =============================================================================
-- Datos de prueba para la BASE LOCAL (no es parte de la estructura de db/).
-- Empresa, áreas, ubicaciones, trabajadores y un proveedor.
-- Se puede ejecutar varias veces: no duplica registros.
--
--   docker compose exec -T db psql -U postgres -d ple_sunat < backend/sql/datos_prueba.sql
--
-- Antes de llevarlo a db/ hay que avisar a Diego (DevOps).
-- =============================================================================
BEGIN;
SET search_path TO ple;

-- Empresa de prueba (en una base recién creada queda con empresa_id = 1)
INSERT INTO empresa (ruc, razon_social, direccion)
VALUES ('20123456789', 'EMPRESA DE PRUEBA S.A.C.', 'Av. Principal 123, Arequipa')
ON CONFLICT (ruc) DO NOTHING;

-- Áreas (centros de costo): 96 gastos administrativos, 97 gastos de ventas
INSERT INTO area (empresa_id, codigo, nombre, cuenta_destino)
SELECT e.empresa_id, v.codigo, v.nombre, v.cuenta
  FROM empresa e,
       (VALUES ('ADM', 'Administración', '96'),
               ('CON', 'Contabilidad',   '96'),
               ('VEN', 'Ventas',         '97')) AS v(codigo, nombre, cuenta)
 WHERE e.ruc = '20123456789'
ON CONFLICT (empresa_id, codigo) DO NOTHING;

-- Ubicaciones físicas
INSERT INTO ubicacion (empresa_id, codigo, nombre, direccion)
SELECT e.empresa_id, v.codigo, v.nombre, v.direccion
  FROM empresa e,
       (VALUES ('SP-P1', 'Sede principal - Piso 1', 'Av. Principal 123, Arequipa'),
               ('SP-P2', 'Sede principal - Piso 2', 'Av. Principal 123, Arequipa'),
               ('ALM',   'Almacén',                 'Calle Industrial 45, Arequipa')) AS v(codigo, nombre, direccion)
 WHERE e.ruc = '20123456789'
ON CONFLICT (empresa_id, codigo) DO NOTHING;

-- Trabajadores (custodios), DNI de 8 dígitos
INSERT INTO trabajador (empresa_id, tipo_documento, numero_documento, nombre, area_id)
SELECT e.empresa_id, '1', v.dni, v.nombre, a.area_id
  FROM empresa e
  JOIN (VALUES ('40000001', 'QUISPE MAMANI, ANA',     'ADM'),
               ('40000002', 'FLORES TORRES, LUIS',    'CON'),
               ('40000003', 'HUAMAN ROJAS, CARMEN',   'VEN')) AS v(dni, nombre, area) ON true
  JOIN area a ON a.empresa_id = e.empresa_id AND a.codigo = v.area
 WHERE e.ruc = '20123456789'
ON CONFLICT (empresa_id, tipo_documento, numero_documento) DO NOTHING;

-- Proveedor (simula Compras / Cuentas por pagar)
INSERT INTO tercero (tipo_documento, numero_documento, nombre, es_proveedor)
VALUES ('6', '20987654321', 'PROVEEDOR DE EQUIPOS S.A.', true)
ON CONFLICT (tipo_documento, numero_documento) DO NOTHING;

COMMIT;
