-- =============================================================================
-- Módulo de Control de Activos Fijos — extensión de la base ple_sunat
-- Ejecutar DESPUÉS de ple_sunat.sql:
--     psql -U postgres -d ple_sunat -f ple_activos_fijos.sql
-- Agrega: Tablas SUNAT 18, 19 y 20; catálogos propios del módulo; activo fijo,
-- movimientos, depreciación, cierre de periodo, inventario físico y auditoría.
-- Cambia: comprobante_detalle (existencia_id deja de ser obligatorio).
-- Cuentas usadas (Tabla 9, PCGR): 33, 39, 68, 66, 76, 46, 16, 4011C, 4011D, 79, 96, 97.
-- =============================================================================
BEGIN;
SET search_path TO ple;

-- -----------------------------------------------------------------------------
-- 1. Catálogos SUNAT adicionales (misma estructura que las Tablas 1 a 12)
-- -----------------------------------------------------------------------------
CREATE TABLE tipo_activo_fijo (
    codigo      CHAR(1)      NOT NULL,
    descripcion VARCHAR(400) NOT NULL,
    activo      BOOLEAN      NOT NULL DEFAULT true,
    CONSTRAINT pk_tipo_activo_fijo PRIMARY KEY (codigo),
    CONSTRAINT ck_tipo_activo_fijo_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE tipo_activo_fijo IS 'Tabla 18 SUNAT: tipo de activo fijo.';

CREATE TABLE estado_activo_fijo (
    codigo      CHAR(1)      NOT NULL,
    descripcion VARCHAR(400) NOT NULL,
    activo      BOOLEAN      NOT NULL DEFAULT true,
    CONSTRAINT pk_estado_activo_fijo PRIMARY KEY (codigo),
    CONSTRAINT ck_estado_activo_fijo_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE estado_activo_fijo IS 'Tabla 19 SUNAT: estado del activo fijo.';

CREATE TABLE metodo_depreciacion (
    codigo      CHAR(1)      NOT NULL,
    descripcion VARCHAR(400) NOT NULL,
    activo      BOOLEAN      NOT NULL DEFAULT true,
    CONSTRAINT pk_metodo_depreciacion PRIMARY KEY (codigo),
    CONSTRAINT ck_metodo_depreciacion_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE metodo_depreciacion IS 'Tabla 20 SUNAT: método de depreciación.';

INSERT INTO tipo_activo_fijo (codigo, descripcion) VALUES
    ('1', 'NO REVALUADO O REVALUADO SIN EFECTO TRIBUTARIO'),
    ('2', 'REVALUADO CON EFECTO TRIBUTARIO');
INSERT INTO estado_activo_fijo (codigo, descripcion) VALUES
    ('1', 'ACTIVOS EN DESUSO'),
    ('2', 'ACTIVOS OBSOLETOS'),
    ('9', 'RESTO DE ACTIVOS');
INSERT INTO metodo_depreciacion (codigo, descripcion) VALUES
    ('1', 'LÍNEA RECTA'),
    ('2', 'UNIDADES PRODUCIDAS'),
    ('9', 'OTROS');

-- Comentarios de columnas de catálogo (para el diccionario)
DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['tipo_activo_fijo','estado_activo_fijo','metodo_depreciacion'] LOOP
        EXECUTE format('COMMENT ON COLUMN %I.codigo IS %L', t, 'Código oficial SUNAT.');
        EXECUTE format('COMMENT ON COLUMN %I.descripcion IS %L', t, 'Descripción oficial del código.');
        EXECUTE format('COMMENT ON COLUMN %I.activo IS %L', t, 'Indica si el código está vigente para nuevos registros.');
    END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- 2. Catálogos propios del módulo
-- -----------------------------------------------------------------------------
CREATE TABLE clase_activo (
    clase_activo_id      INTEGER GENERATED ALWAYS AS IDENTITY,
    codigo               VARCHAR(10)  NOT NULL,
    nombre               VARCHAR(100) NOT NULL,
    cuenta_activo        VARCHAR(5)   NOT NULL DEFAULT '33',
    cuenta_depreciacion  VARCHAR(5)   NOT NULL DEFAULT '39',
    cuenta_gasto         VARCHAR(5)   NOT NULL DEFAULT '68',
    depreciable          BOOLEAN      NOT NULL DEFAULT true,
    vida_util_meses      SMALLINT,
    tasa_tributaria_max  NUMERIC(5,2) NOT NULL DEFAULT 0,
    activo               BOOLEAN      NOT NULL DEFAULT true,
    CONSTRAINT pk_clase_activo PRIMARY KEY (clase_activo_id),
    CONSTRAINT uq_clase_activo_codigo UNIQUE (codigo),
    CONSTRAINT fk_clase_cta_activo FOREIGN KEY (cuenta_activo) REFERENCES cuenta_contable(codigo),
    CONSTRAINT fk_clase_cta_deprec FOREIGN KEY (cuenta_depreciacion) REFERENCES cuenta_contable(codigo),
    CONSTRAINT fk_clase_cta_gasto FOREIGN KEY (cuenta_gasto) REFERENCES cuenta_contable(codigo),
    CONSTRAINT ck_clase_tasa CHECK (tasa_tributaria_max BETWEEN 0 AND 100),
    CONSTRAINT ck_clase_vida CHECK ((NOT depreciable AND tasa_tributaria_max = 0)
                                    OR (depreciable AND vida_util_meses > 0))
);
COMMENT ON TABLE clase_activo IS 'Clases de activo fijo con sus cuentas, vida útil y tasa tributaria máxima.';
COMMENT ON COLUMN clase_activo.clase_activo_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN clase_activo.codigo IS 'Código corto de la clase.';
COMMENT ON COLUMN clase_activo.nombre IS 'Nombre de la clase (edificios, vehículos, etc.).';
COMMENT ON COLUMN clase_activo.cuenta_activo IS 'Cuenta del activo (Tabla 9), por defecto 33.';
COMMENT ON COLUMN clase_activo.cuenta_depreciacion IS 'Cuenta de depreciación acumulada (Tabla 9), por defecto 39.';
COMMENT ON COLUMN clase_activo.cuenta_gasto IS 'Cuenta del gasto de depreciación (Tabla 9), por defecto 68.';
COMMENT ON COLUMN clase_activo.depreciable IS 'Falso para terrenos.';
COMMENT ON COLUMN clase_activo.vida_util_meses IS 'Vida útil contable por defecto, en meses.';
COMMENT ON COLUMN clase_activo.tasa_tributaria_max IS 'Tasa anual máxima de depreciación tributaria (%).';
COMMENT ON COLUMN clase_activo.activo IS 'Indica si la clase se puede usar en nuevos registros.';

INSERT INTO clase_activo (codigo, nombre, depreciable, vida_util_meses, tasa_tributaria_max) VALUES
    ('TER', 'Terrenos',                       false, NULL,   0),
    ('EDI', 'Edificios y construcciones',     true,  240,    5),
    ('MAQ', 'Maquinaria y equipo',            true,  120,   10),
    ('VEH', 'Vehículos de transporte',        true,  60,    20),
    ('MUE', 'Muebles y enseres',              true,  120,   10),
    ('CMP', 'Equipos de procesamiento de datos', true, 48,  25),
    ('OTR', 'Otros activos fijos',            true,  120,   10);

CREATE TABLE area (
    area_id         INTEGER GENERATED ALWAYS AS IDENTITY,
    empresa_id      INTEGER      NOT NULL,
    codigo          VARCHAR(10)  NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    cuenta_destino  VARCHAR(5)   NOT NULL DEFAULT '96',
    CONSTRAINT pk_area PRIMARY KEY (area_id),
    CONSTRAINT uq_area_codigo UNIQUE (empresa_id, codigo),
    CONSTRAINT fk_area_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(empresa_id),
    CONSTRAINT fk_area_cuenta FOREIGN KEY (cuenta_destino) REFERENCES cuenta_contable(codigo)
);
COMMENT ON TABLE area IS 'Áreas o centros de costo a los que se carga la depreciación.';
COMMENT ON COLUMN area.area_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN area.empresa_id IS 'Empresa a la que pertenece el área. → empresa';
COMMENT ON COLUMN area.codigo IS 'Código del área.';
COMMENT ON COLUMN area.nombre IS 'Nombre del área.';
COMMENT ON COLUMN area.cuenta_destino IS 'Cuenta de destino del gasto (Tabla 9): 96 administrativos o 97 ventas.';

CREATE TABLE ubicacion (
    ubicacion_id  INTEGER GENERATED ALWAYS AS IDENTITY,
    empresa_id    INTEGER      NOT NULL,
    codigo        VARCHAR(10)  NOT NULL,
    nombre        VARCHAR(100) NOT NULL,
    direccion     VARCHAR(250),
    CONSTRAINT pk_ubicacion PRIMARY KEY (ubicacion_id),
    CONSTRAINT uq_ubicacion_codigo UNIQUE (empresa_id, codigo),
    CONSTRAINT fk_ubicacion_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(empresa_id)
);
COMMENT ON TABLE ubicacion IS 'Sedes, pisos u oficinas donde se encuentran físicamente los activos.';
COMMENT ON COLUMN ubicacion.ubicacion_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN ubicacion.empresa_id IS 'Empresa propietaria. → empresa';
COMMENT ON COLUMN ubicacion.codigo IS 'Código de la ubicación.';
COMMENT ON COLUMN ubicacion.nombre IS 'Nombre de la ubicación.';
COMMENT ON COLUMN ubicacion.direccion IS 'Dirección de la sede.';

CREATE TABLE trabajador (
    trabajador_id     INTEGER GENERATED ALWAYS AS IDENTITY,
    empresa_id        INTEGER      NOT NULL,
    tipo_documento    CHAR(1)      NOT NULL DEFAULT '1',
    numero_documento  VARCHAR(15)  NOT NULL,
    nombre            VARCHAR(200) NOT NULL,
    area_id           INTEGER,
    fecha_cese        DATE,
    CONSTRAINT pk_trabajador PRIMARY KEY (trabajador_id),
    CONSTRAINT uq_trabajador_doc UNIQUE (empresa_id, tipo_documento, numero_documento),
    CONSTRAINT fk_trab_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(empresa_id),
    CONSTRAINT fk_trab_tipo_doc FOREIGN KEY (tipo_documento) REFERENCES tipo_documento_identidad(codigo),
    CONSTRAINT fk_trab_area FOREIGN KEY (area_id) REFERENCES area(area_id),
    CONSTRAINT ck_trab_dni CHECK (tipo_documento <> '1' OR numero_documento ~ '^[0-9]{8}$')
);
COMMENT ON TABLE trabajador IS 'Custodios de activos. Réplica de solo lectura del maestro de Planillas.';
COMMENT ON COLUMN trabajador.trabajador_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN trabajador.empresa_id IS 'Empleador. → empresa';
COMMENT ON COLUMN trabajador.tipo_documento IS 'Tipo de documento de identidad (Tabla 2), por defecto 1 DNI. → tipo_documento_identidad';
COMMENT ON COLUMN trabajador.numero_documento IS 'Número del documento.';
COMMENT ON COLUMN trabajador.nombre IS 'Apellidos y nombres.';
COMMENT ON COLUMN trabajador.area_id IS 'Área donde labora. → area';
COMMENT ON COLUMN trabajador.fecha_cese IS 'Fecha de cese; con valor, sus activos deben reasignarse.';

-- -----------------------------------------------------------------------------
-- 3. Cambio a la base: comprobante_detalle puede ser un activo fijo
-- -----------------------------------------------------------------------------
ALTER TABLE comprobante_detalle ALTER COLUMN existencia_id DROP NOT NULL;
ALTER TABLE comprobante_detalle ADD COLUMN descripcion VARCHAR(200);
ALTER TABLE comprobante_detalle ADD CONSTRAINT ck_compdet_bien
    CHECK (existencia_id IS NOT NULL OR descripcion IS NOT NULL);
COMMENT ON COLUMN comprobante_detalle.existencia_id IS 'Existencia vendida o comprada; nulo si la línea es un activo fijo. → existencia';
COMMENT ON COLUMN comprobante_detalle.descripcion IS 'Descripción de la línea cuando no es una existencia (p. ej., activo fijo).';

-- -----------------------------------------------------------------------------
-- 4. Activo fijo
-- -----------------------------------------------------------------------------
CREATE TABLE activo_fijo (
    activo_fijo_id       INTEGER GENERATED ALWAYS AS IDENTITY,
    empresa_id           INTEGER       NOT NULL,
    codigo_patrimonial   VARCHAR(24)   NOT NULL,
    descripcion          VARCHAR(200)  NOT NULL,
    clase_activo_id      INTEGER       NOT NULL,
    marca                VARCHAR(60),
    modelo               VARCHAR(60),
    serie_placa          VARCHAR(60),
    fecha_adquisicion    DATE          NOT NULL,
    fecha_inicio_uso     DATE,
    costo_adquisicion    NUMERIC(14,2) NOT NULL,
    valor_residual       NUMERIC(14,2) NOT NULL DEFAULT 0,
    vida_util_meses      SMALLINT,
    tasa_tributaria      NUMERIC(5,2),
    metodo_depreciacion  CHAR(1)       NOT NULL DEFAULT '1',
    tipo_activo_fijo     CHAR(1)       NOT NULL DEFAULT '1',
    estado_activo_fijo   CHAR(1)       NOT NULL DEFAULT '9',
    situacion            CHAR(1)       NOT NULL DEFAULT 'P',
    proveedor_id         INTEGER,
    comprobante_id       BIGINT,
    comprobante_item     SMALLINT,
    activo_padre_id      INTEGER,
    area_id              INTEGER,
    ubicacion_id         INTEGER,
    custodio_id          INTEGER,
    fecha_registro       TIMESTAMP     NOT NULL DEFAULT now(),
    CONSTRAINT pk_activo_fijo PRIMARY KEY (activo_fijo_id),
    CONSTRAINT uq_activo_codigo UNIQUE (empresa_id, codigo_patrimonial),
    CONSTRAINT fk_af_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(empresa_id),
    CONSTRAINT fk_af_clase FOREIGN KEY (clase_activo_id) REFERENCES clase_activo(clase_activo_id),
    CONSTRAINT fk_af_metodo FOREIGN KEY (metodo_depreciacion) REFERENCES metodo_depreciacion(codigo),
    CONSTRAINT fk_af_tipo FOREIGN KEY (tipo_activo_fijo) REFERENCES tipo_activo_fijo(codigo),
    CONSTRAINT fk_af_estado FOREIGN KEY (estado_activo_fijo) REFERENCES estado_activo_fijo(codigo),
    CONSTRAINT fk_af_proveedor FOREIGN KEY (proveedor_id) REFERENCES tercero(tercero_id),
    CONSTRAINT fk_af_compdet FOREIGN KEY (comprobante_id, comprobante_item)
        REFERENCES comprobante_detalle(comprobante_id, item),
    CONSTRAINT fk_af_padre FOREIGN KEY (activo_padre_id) REFERENCES activo_fijo(activo_fijo_id),
    CONSTRAINT fk_af_area FOREIGN KEY (area_id) REFERENCES area(area_id),
    CONSTRAINT fk_af_ubicacion FOREIGN KEY (ubicacion_id) REFERENCES ubicacion(ubicacion_id),
    CONSTRAINT fk_af_custodio FOREIGN KEY (custodio_id) REFERENCES trabajador(trabajador_id),
    CONSTRAINT ck_af_costo CHECK (costo_adquisicion > 0 AND valor_residual >= 0
                                  AND valor_residual < costo_adquisicion),
    CONSTRAINT ck_af_fechas CHECK (fecha_inicio_uso IS NULL OR fecha_inicio_uso >= fecha_adquisicion),
    CONSTRAINT ck_af_tasa CHECK (tasa_tributaria IS NULL OR tasa_tributaria BETWEEN 0 AND 100),
    CONSTRAINT ck_af_situacion CHECK (situacion IN ('P', 'A', 'B')),
    CONSTRAINT ck_af_comp CHECK ((comprobante_id IS NULL) = (comprobante_item IS NULL)),
    CONSTRAINT ck_af_padre CHECK (activo_padre_id IS NULL OR activo_padre_id <> activo_fijo_id)
);
CREATE INDEX ix_af_clase ON activo_fijo (clase_activo_id);
CREATE INDEX ix_af_custodio ON activo_fijo (custodio_id);
COMMENT ON TABLE activo_fijo IS 'Bienes del activo fijo de la empresa (Registro de Activos Fijos, libro 07).';
COMMENT ON COLUMN activo_fijo.activo_fijo_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN activo_fijo.empresa_id IS 'Empresa propietaria. → empresa';
COMMENT ON COLUMN activo_fijo.codigo_patrimonial IS 'Código único que va en la etiqueta del bien.';
COMMENT ON COLUMN activo_fijo.descripcion IS 'Descripción del bien.';
COMMENT ON COLUMN activo_fijo.clase_activo_id IS 'Clase del activo. → clase_activo';
COMMENT ON COLUMN activo_fijo.marca IS 'Marca del bien.';
COMMENT ON COLUMN activo_fijo.modelo IS 'Modelo del bien.';
COMMENT ON COLUMN activo_fijo.serie_placa IS 'Número de serie o placa.';
COMMENT ON COLUMN activo_fijo.fecha_adquisicion IS 'Fecha de adquisición.';
COMMENT ON COLUMN activo_fijo.fecha_inicio_uso IS 'Fecha en que entra en uso; desde ese mes se deprecia.';
COMMENT ON COLUMN activo_fijo.costo_adquisicion IS 'Costo en soles: precio + gastos atribuibles, sin IGV recuperable.';
COMMENT ON COLUMN activo_fijo.valor_residual IS 'Valor residual contable estimado.';
COMMENT ON COLUMN activo_fijo.vida_util_meses IS 'Vida útil contable; si es nula se toma la de la clase.';
COMMENT ON COLUMN activo_fijo.tasa_tributaria IS 'Tasa tributaria anual (%); si es nula se toma la máxima de la clase.';
COMMENT ON COLUMN activo_fijo.metodo_depreciacion IS 'Método de depreciación (Tabla 20), por defecto 1 línea recta. → metodo_depreciacion';
COMMENT ON COLUMN activo_fijo.tipo_activo_fijo IS 'Tipo de activo fijo (Tabla 18). → tipo_activo_fijo';
COMMENT ON COLUMN activo_fijo.estado_activo_fijo IS 'Estado del activo fijo (Tabla 19). → estado_activo_fijo';
COMMENT ON COLUMN activo_fijo.situacion IS 'P = pendiente de aprobación, A = en uso (alta), B = dado de baja.';
COMMENT ON COLUMN activo_fijo.proveedor_id IS 'Proveedor del bien. → tercero';
COMMENT ON COLUMN activo_fijo.comprobante_id IS 'Comprobante de compra (con comprobante_item). → comprobante_detalle';
COMMENT ON COLUMN activo_fijo.comprobante_item IS 'Línea del comprobante de compra.';
COMMENT ON COLUMN activo_fijo.activo_padre_id IS 'Activo principal, si este registro es un componente. → activo_fijo';
COMMENT ON COLUMN activo_fijo.area_id IS 'Área o centro de costo actual. → area';
COMMENT ON COLUMN activo_fijo.ubicacion_id IS 'Ubicación física actual. → ubicacion';
COMMENT ON COLUMN activo_fijo.custodio_id IS 'Custodio vigente. → trabajador';
COMMENT ON COLUMN activo_fijo.fecha_registro IS 'Fecha y hora de registro en el sistema.';

-- Completa vida útil y tasa desde la clase; valida que un comprobante no genere más altas que su cantidad
CREATE FUNCTION fn_activo_defaults() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    c clase_activo%ROWTYPE;
    v_cant NUMERIC;
    v_usados INTEGER;
BEGIN
    SELECT * INTO c FROM clase_activo WHERE clase_activo_id = NEW.clase_activo_id;
    IF NEW.vida_util_meses IS NULL THEN NEW.vida_util_meses := c.vida_util_meses; END IF;
    IF NEW.tasa_tributaria IS NULL THEN NEW.tasa_tributaria := c.tasa_tributaria_max; END IF;
    IF c.depreciable AND NEW.vida_util_meses IS NULL THEN
        RAISE EXCEPTION 'El activo % necesita vida útil', NEW.codigo_patrimonial;
    END IF;
    IF NEW.comprobante_id IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.comprobante_id IS DISTINCT FROM OLD.comprobante_id
            OR NEW.comprobante_item IS DISTINCT FROM OLD.comprobante_item) THEN
        SELECT cantidad INTO v_cant FROM comprobante_detalle
         WHERE comprobante_id = NEW.comprobante_id AND item = NEW.comprobante_item;
        SELECT count(*) INTO v_usados FROM activo_fijo
         WHERE comprobante_id = NEW.comprobante_id AND comprobante_item = NEW.comprobante_item
           AND activo_padre_id IS NULL AND activo_fijo_id IS DISTINCT FROM NEW.activo_fijo_id;
        IF NEW.activo_padre_id IS NULL AND v_usados + 1 > v_cant THEN
            RAISE EXCEPTION 'La línea % del comprobante % ya generó % alta(s)', NEW.comprobante_item, NEW.comprobante_id, v_usados;
        END IF;
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER tg_activo_defaults BEFORE INSERT OR UPDATE ON activo_fijo
    FOR EACH ROW EXECUTE FUNCTION fn_activo_defaults();

-- -----------------------------------------------------------------------------
-- 5. Periodos contables del módulo
-- -----------------------------------------------------------------------------
CREATE TABLE periodo_contable (
    empresa_id   INTEGER     NOT NULL,
    periodo      CHAR(6)     NOT NULL,
    cerrado      BOOLEAN     NOT NULL DEFAULT false,
    cerrado_por  VARCHAR(60),
    fecha_cierre TIMESTAMP,
    motivo_reapertura VARCHAR(250),
    CONSTRAINT pk_periodo_contable PRIMARY KEY (empresa_id, periodo),
    CONSTRAINT fk_per_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(empresa_id),
    CONSTRAINT ck_per_periodo CHECK (periodo ~ '^[0-9]{4}(0[1-9]|1[0-2])$'),
    CONSTRAINT ck_per_cierre CHECK (NOT cerrado OR (cerrado_por IS NOT NULL AND fecha_cierre IS NOT NULL))
);
COMMENT ON TABLE periodo_contable IS 'Cierre mensual: un periodo cerrado no admite movimientos ni depreciación.';
COMMENT ON COLUMN periodo_contable.empresa_id IS 'Empresa. → empresa';
COMMENT ON COLUMN periodo_contable.periodo IS 'Periodo AAAAMM.';
COMMENT ON COLUMN periodo_contable.cerrado IS 'Verdadero si el periodo está cerrado.';
COMMENT ON COLUMN periodo_contable.cerrado_por IS 'Usuario que cerró el periodo.';
COMMENT ON COLUMN periodo_contable.fecha_cierre IS 'Fecha y hora del cierre.';
COMMENT ON COLUMN periodo_contable.motivo_reapertura IS 'Motivo, si el contador reabrió el periodo.';

CREATE FUNCTION fn_periodo_cerrado(p_empresa INTEGER, p_fecha DATE) RETURNS BOOLEAN
LANGUAGE sql STABLE AS $$
    SELECT COALESCE((SELECT cerrado FROM periodo_contable
                      WHERE empresa_id = p_empresa AND periodo = to_char(p_fecha, 'YYYYMM')), false);
$$;

-- -----------------------------------------------------------------------------
-- 6. Movimientos del activo
-- -----------------------------------------------------------------------------
CREATE TABLE movimiento_activo (
    movimiento_id        BIGINT GENERATED ALWAYS AS IDENTITY,
    activo_fijo_id       INTEGER       NOT NULL,
    tipo_movimiento      CHAR(2)       NOT NULL,
    fecha                DATE          NOT NULL,
    motivo               VARCHAR(250),
    monto                NUMERIC(14,2) NOT NULL DEFAULT 0,
    capitaliza           BOOLEAN,
    comprobante_id       BIGINT,
    medio_pago           CHAR(3),
    area_destino_id      INTEGER,
    ubicacion_destino_id INTEGER,
    custodio_destino_id  INTEGER,
    estado               CHAR(1)       NOT NULL DEFAULT 'P',
    registrado_por       VARCHAR(60)   NOT NULL,
    aprobado_por         VARCHAR(60),
    fecha_aprobacion     TIMESTAMP,
    movimiento_anulado_id BIGINT,
    asiento_id           BIGINT,
    CONSTRAINT pk_movimiento_activo PRIMARY KEY (movimiento_id),
    CONSTRAINT fk_mov_af FOREIGN KEY (activo_fijo_id) REFERENCES activo_fijo(activo_fijo_id),
    CONSTRAINT fk_movaf_comp FOREIGN KEY (comprobante_id) REFERENCES comprobante(comprobante_id),
    CONSTRAINT fk_movaf_medio FOREIGN KEY (medio_pago) REFERENCES tipo_medio_pago(codigo),
    CONSTRAINT fk_movaf_area FOREIGN KEY (area_destino_id) REFERENCES area(area_id),
    CONSTRAINT fk_movaf_ubic FOREIGN KEY (ubicacion_destino_id) REFERENCES ubicacion(ubicacion_id),
    CONSTRAINT fk_movaf_custodio FOREIGN KEY (custodio_destino_id) REFERENCES trabajador(trabajador_id),
    CONSTRAINT fk_movaf_anulado FOREIGN KEY (movimiento_anulado_id) REFERENCES movimiento_activo(movimiento_id),
    CONSTRAINT fk_movaf_asiento FOREIGN KEY (asiento_id) REFERENCES asiento(asiento_id),
    CONSTRAINT ck_movaf_tipo CHECK (tipo_movimiento IN ('AL','AS','TR','ME','RV','BA','AN')),
    CONSTRAINT ck_movaf_estado CHECK (estado IN ('P','A','N')),
    CONSTRAINT ck_movaf_monto CHECK (monto >= 0),
    CONSTRAINT ck_movaf_aprobador CHECK (aprobado_por IS NULL OR aprobado_por <> registrado_por),
    CONSTRAINT ck_movaf_aprob CHECK (estado <> 'A' OR (aprobado_por IS NOT NULL AND fecha_aprobacion IS NOT NULL)),
    CONSTRAINT ck_movaf_motivo CHECK (tipo_movimiento NOT IN ('TR','BA','AN','RV') OR motivo IS NOT NULL),
    CONSTRAINT ck_movaf_mejora CHECK (tipo_movimiento <> 'ME' OR (capitaliza IS NOT NULL AND comprobante_id IS NOT NULL)),
    CONSTRAINT ck_movaf_destino CHECK (tipo_movimiento NOT IN ('AS','TR')
              OR COALESCE(area_destino_id, ubicacion_destino_id, custodio_destino_id) IS NOT NULL),
    CONSTRAINT ck_movaf_anula CHECK ((tipo_movimiento = 'AN') = (movimiento_anulado_id IS NOT NULL))
);
CREATE INDEX ix_movaf_activo ON movimiento_activo (activo_fijo_id, fecha);
COMMENT ON TABLE movimiento_activo IS 'Altas, asignaciones, transferencias, mejoras, revaluaciones, bajas y anulaciones.';
COMMENT ON COLUMN movimiento_activo.movimiento_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN movimiento_activo.activo_fijo_id IS 'Activo afectado. → activo_fijo';
COMMENT ON COLUMN movimiento_activo.tipo_movimiento IS 'AL alta, AS asignación, TR transferencia, ME mejora, RV revaluación, BA baja, AN anulación.';
COMMENT ON COLUMN movimiento_activo.fecha IS 'Fecha del movimiento.';
COMMENT ON COLUMN movimiento_activo.motivo IS 'Motivo; obligatorio en transferencia, revaluación, baja y anulación.';
COMMENT ON COLUMN movimiento_activo.monto IS 'Importe: costo de la mejora, precio de venta o nuevo valor revaluado.';
COMMENT ON COLUMN movimiento_activo.capitaliza IS 'Solo mejoras: verdadero si aumenta el costo, falso si va a gasto.';
COMMENT ON COLUMN movimiento_activo.comprobante_id IS 'Comprobante que sustenta el movimiento. → comprobante';
COMMENT ON COLUMN movimiento_activo.medio_pago IS 'Medio de pago o cobro (Tabla 1). → tipo_medio_pago';
COMMENT ON COLUMN movimiento_activo.area_destino_id IS 'Área de destino (asignación o transferencia). → area';
COMMENT ON COLUMN movimiento_activo.ubicacion_destino_id IS 'Ubicación de destino. → ubicacion';
COMMENT ON COLUMN movimiento_activo.custodio_destino_id IS 'Nuevo custodio. → trabajador';
COMMENT ON COLUMN movimiento_activo.estado IS 'P = pendiente, A = aprobado, N = anulado.';
COMMENT ON COLUMN movimiento_activo.registrado_por IS 'Usuario que registró el movimiento.';
COMMENT ON COLUMN movimiento_activo.aprobado_por IS 'Usuario que aprobó; no puede ser quien registró.';
COMMENT ON COLUMN movimiento_activo.fecha_aprobacion IS 'Fecha y hora de la aprobación.';
COMMENT ON COLUMN movimiento_activo.movimiento_anulado_id IS 'Solo anulaciones: movimiento que se anula. → movimiento_activo';
COMMENT ON COLUMN movimiento_activo.asiento_id IS 'Asiento contable generado, si corresponde. → asiento';

-- Validaciones antes de registrar un movimiento
CREATE FUNCTION fn_movimiento_validar() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE a activo_fijo%ROWTYPE;
BEGIN
    SELECT * INTO a FROM activo_fijo WHERE activo_fijo_id = NEW.activo_fijo_id;
    IF TG_OP = 'INSERT' THEN
        IF a.situacion = 'B' THEN
            RAISE EXCEPTION 'El activo % está dado de baja y no admite movimientos', a.codigo_patrimonial;
        END IF;
        IF fn_periodo_cerrado(a.empresa_id, NEW.fecha) THEN
            RAISE EXCEPTION 'El periodo % está cerrado', to_char(NEW.fecha, 'YYYYMM');
        END IF;
        IF NEW.tipo_movimiento <> 'AL' AND a.situacion = 'P' THEN
            RAISE EXCEPTION 'El activo % aún no tiene el alta aprobada', a.codigo_patrimonial;
        END IF;
    ELSIF OLD.estado = 'A' AND NEW.estado = 'P' THEN
        RAISE EXCEPTION 'Un movimiento aprobado no vuelve a pendiente; anúlelo';
    END IF;
    RETURN NEW;
END $$;
CREATE TRIGGER tg_movimiento_validar BEFORE INSERT OR UPDATE ON movimiento_activo
    FOR EACH ROW EXECUTE FUNCTION fn_movimiento_validar();

-- Aplica al activo el efecto de un movimiento cuando queda aprobado
CREATE FUNCTION fn_movimiento_aplicar() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.estado <> 'A' OR (TG_OP = 'UPDATE' AND OLD.estado = 'A') THEN
        RETURN NEW;
    END IF;
    CASE NEW.tipo_movimiento
        WHEN 'AL' THEN
            UPDATE activo_fijo SET situacion = 'A' WHERE activo_fijo_id = NEW.activo_fijo_id;
        WHEN 'AS', 'TR' THEN
            UPDATE activo_fijo
               SET area_id      = COALESCE(NEW.area_destino_id, area_id),
                   ubicacion_id = COALESCE(NEW.ubicacion_destino_id, ubicacion_id),
                   custodio_id  = COALESCE(NEW.custodio_destino_id, custodio_id)
             WHERE activo_fijo_id = NEW.activo_fijo_id;
        WHEN 'BA' THEN
            UPDATE activo_fijo SET situacion = 'B' WHERE activo_fijo_id = NEW.activo_fijo_id;
        WHEN 'AN' THEN
            UPDATE movimiento_activo SET estado = 'N' WHERE movimiento_id = NEW.movimiento_anulado_id;
        ELSE
            NULL;  -- ME y RV se reflejan en v_activo_costo
    END CASE;
    RETURN NEW;
END $$;
CREATE TRIGGER tg_movimiento_aplicar AFTER INSERT OR UPDATE ON movimiento_activo
    FOR EACH ROW EXECUTE FUNCTION fn_movimiento_aplicar();

-- -----------------------------------------------------------------------------
-- 7. Depreciación mensual (contable y tributaria)
-- -----------------------------------------------------------------------------
CREATE TABLE depreciacion (
    activo_fijo_id           INTEGER       NOT NULL,
    periodo                  CHAR(6)       NOT NULL,
    area_id                  INTEGER,
    depreciacion_contable    NUMERIC(14,2) NOT NULL,
    depreciacion_tributaria  NUMERIC(14,2) NOT NULL,
    asiento_id               BIGINT,
    fecha_calculo            TIMESTAMP     NOT NULL DEFAULT now(),
    CONSTRAINT pk_depreciacion PRIMARY KEY (activo_fijo_id, periodo),
    CONSTRAINT fk_dep_af FOREIGN KEY (activo_fijo_id) REFERENCES activo_fijo(activo_fijo_id),
    CONSTRAINT fk_dep_area FOREIGN KEY (area_id) REFERENCES area(area_id),
    CONSTRAINT fk_dep_asiento FOREIGN KEY (asiento_id) REFERENCES asiento(asiento_id),
    CONSTRAINT ck_dep_periodo CHECK (periodo ~ '^[0-9]{4}(0[1-9]|1[0-2])$'),
    CONSTRAINT ck_dep_valores CHECK (depreciacion_contable >= 0 AND depreciacion_tributaria >= 0)
);
COMMENT ON TABLE depreciacion IS 'Depreciación mensual por activo; la clave impide calcular dos veces el mismo mes.';
COMMENT ON COLUMN depreciacion.activo_fijo_id IS 'Activo depreciado. → activo_fijo';
COMMENT ON COLUMN depreciacion.periodo IS 'Periodo AAAAMM.';
COMMENT ON COLUMN depreciacion.area_id IS 'Área a la que se cargó el gasto en ese mes. → area';
COMMENT ON COLUMN depreciacion.depreciacion_contable IS 'Depreciación según vida útil (NIC 16).';
COMMENT ON COLUMN depreciacion.depreciacion_tributaria IS 'Depreciación según la tasa tributaria.';
COMMENT ON COLUMN depreciacion.asiento_id IS 'Asiento 68/39 que la contabilizó. → asiento';
COMMENT ON COLUMN depreciacion.fecha_calculo IS 'Fecha y hora del cálculo.';

-- Costo vigente = costo de adquisición + mejoras capitalizadas aprobadas
CREATE VIEW v_activo_costo AS
SELECT a.activo_fijo_id,
       a.costo_adquisicion,
       COALESCE(sum(m.monto) FILTER (WHERE m.tipo_movimiento = 'ME' AND m.capitaliza), 0) AS mejoras,
       a.costo_adquisicion
         + COALESCE(sum(m.monto) FILTER (WHERE m.tipo_movimiento = 'ME' AND m.capitaliza), 0) AS costo_total
  FROM activo_fijo a
  LEFT JOIN movimiento_activo m ON m.activo_fijo_id = a.activo_fijo_id AND m.estado = 'A'
 GROUP BY a.activo_fijo_id;
COMMENT ON VIEW v_activo_costo IS 'Costo de adquisición más mejoras capitalizadas aprobadas.';

CREATE FUNCTION fn_calcular_depreciacion(p_empresa INTEGER, p_periodo CHAR(6), p_previsualizar BOOLEAN DEFAULT false)
RETURNS TABLE (activo_fijo_id INTEGER, codigo_patrimonial VARCHAR, dep_contable NUMERIC, dep_tributaria NUMERIC)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
DECLARE r RECORD;
BEGIN
    IF COALESCE((SELECT cerrado FROM periodo_contable pc
                  WHERE pc.empresa_id = p_empresa AND pc.periodo = p_periodo), false) THEN
        RAISE EXCEPTION 'El periodo % está cerrado', p_periodo;
    END IF;
    FOR r IN
        SELECT a.activo_fijo_id AS id, a.codigo_patrimonial AS cod, a.area_id AS area,
               c.costo_total, a.valor_residual, a.vida_util_meses, a.tasa_tributaria,
               COALESCE((SELECT sum(d.depreciacion_contable) FROM depreciacion d
                          WHERE d.activo_fijo_id = a.activo_fijo_id AND d.periodo < p_periodo), 0) AS acum_c,
               COALESCE((SELECT sum(d.depreciacion_tributaria) FROM depreciacion d
                          WHERE d.activo_fijo_id = a.activo_fijo_id AND d.periodo < p_periodo), 0) AS acum_t
          FROM activo_fijo a
          JOIN clase_activo k ON k.clase_activo_id = a.clase_activo_id
          JOIN v_activo_costo c ON c.activo_fijo_id = a.activo_fijo_id
         WHERE a.empresa_id = p_empresa
           AND a.situacion = 'A'
           AND k.depreciable
           AND a.metodo_depreciacion = '1'
           AND a.fecha_inicio_uso IS NOT NULL
           AND to_char(a.fecha_inicio_uso, 'YYYYMM') <= p_periodo
           AND NOT EXISTS (SELECT 1 FROM depreciacion d
                            WHERE d.activo_fijo_id = a.activo_fijo_id AND d.periodo = p_periodo)
    LOOP
        activo_fijo_id     := r.id;
        codigo_patrimonial := r.cod;
        dep_contable   := GREATEST(LEAST(round((r.costo_total - r.valor_residual) / r.vida_util_meses, 2),
                                         r.costo_total - r.valor_residual - r.acum_c), 0);
        dep_tributaria := GREATEST(LEAST(round(r.costo_total * r.tasa_tributaria / 100 / 12, 2),
                                         r.costo_total - r.acum_t), 0);
        CONTINUE WHEN dep_contable = 0 AND dep_tributaria = 0;
        IF NOT p_previsualizar THEN
            INSERT INTO depreciacion (activo_fijo_id, periodo, area_id, depreciacion_contable, depreciacion_tributaria)
            VALUES (r.id, p_periodo, r.area, dep_contable, dep_tributaria)
            ON CONFLICT DO NOTHING;
        END IF;
        RETURN NEXT;
    END LOOP;
END $$;
COMMENT ON FUNCTION fn_calcular_depreciacion(INTEGER, CHAR, BOOLEAN) IS
    'Calcula la depreciación por línea recta de un periodo; con p_previsualizar = true no graba nada.';

-- Valor neto en libros
CREATE VIEW v_activo_valor_neto AS
SELECT a.activo_fijo_id, a.empresa_id, a.codigo_patrimonial, a.descripcion, k.nombre AS clase,
       a.area_id, a.ubicacion_id, a.custodio_id, a.situacion,
       c.costo_total,
       COALESCE(sum(d.depreciacion_contable), 0)   AS depreciacion_acumulada,
       c.costo_total - COALESCE(sum(d.depreciacion_contable), 0) AS valor_neto,
       COALESCE(sum(d.depreciacion_tributaria), 0) AS depreciacion_tributaria_acumulada
  FROM activo_fijo a
  JOIN clase_activo k ON k.clase_activo_id = a.clase_activo_id
  JOIN v_activo_costo c ON c.activo_fijo_id = a.activo_fijo_id
  LEFT JOIN depreciacion d ON d.activo_fijo_id = a.activo_fijo_id
 GROUP BY a.activo_fijo_id, k.nombre, c.costo_total;
COMMENT ON VIEW v_activo_valor_neto IS 'Costo, depreciación acumulada y valor neto en libros por activo.';

-- Registro de Activos Fijos (libro 07) por ejercicio
CREATE VIEW v_registro_activos_fijos AS
WITH ej AS (
    SELECT DISTINCT a.activo_fijo_id, left(d.periodo, 4) AS ejercicio
      FROM activo_fijo a JOIN depreciacion d ON d.activo_fijo_id = a.activo_fijo_id
)
SELECT ej.ejercicio,
       a.empresa_id,
       a.codigo_patrimonial,
       k.cuenta_activo,
       a.descripcion, a.marca, a.modelo, a.serie_placa,
       c.costo_adquisicion                 AS saldo_inicial,
       c.mejoras,
       CASE WHEN a.situacion = 'B' THEN c.costo_total ELSE 0 END AS retiros_bajas,
       a.fecha_adquisicion, a.fecha_inicio_uso,
       m.descripcion                       AS metodo_aplicado,
       a.tasa_tributaria                   AS porcentaje_depreciacion,
       (SELECT COALESCE(sum(d.depreciacion_tributaria), 0) FROM depreciacion d
         WHERE d.activo_fijo_id = a.activo_fijo_id AND left(d.periodo, 4) < ej.ejercicio) AS depreciacion_acum_anterior,
       (SELECT COALESCE(sum(d.depreciacion_tributaria), 0) FROM depreciacion d
         WHERE d.activo_fijo_id = a.activo_fijo_id AND left(d.periodo, 4) = ej.ejercicio) AS depreciacion_ejercicio,
       (SELECT COALESCE(sum(d.depreciacion_tributaria), 0) FROM depreciacion d
         WHERE d.activo_fijo_id = a.activo_fijo_id AND left(d.periodo, 4) <= ej.ejercicio) AS depreciacion_acumulada
  FROM ej
  JOIN activo_fijo a ON a.activo_fijo_id = ej.activo_fijo_id
  JOIN clase_activo k ON k.clase_activo_id = a.clase_activo_id
  JOIN v_activo_costo c ON c.activo_fijo_id = a.activo_fijo_id
  JOIN metodo_depreciacion m ON m.codigo = a.metodo_depreciacion;
COMMENT ON VIEW v_registro_activos_fijos IS 'Datos del Registro de Activos Fijos (Tabla 8, código 07) por ejercicio.';

-- -----------------------------------------------------------------------------
-- 8. Inventario físico
-- -----------------------------------------------------------------------------
CREATE TABLE inventario_fisico (
    inventario_id  INTEGER GENERATED ALWAYS AS IDENTITY,
    empresa_id     INTEGER     NOT NULL,
    fecha          DATE        NOT NULL,
    area_id        INTEGER,
    ubicacion_id   INTEGER,
    estado         CHAR(1)     NOT NULL DEFAULT 'A',
    responsable    VARCHAR(60) NOT NULL,
    CONSTRAINT pk_inventario_fisico PRIMARY KEY (inventario_id),
    CONSTRAINT fk_inv_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(empresa_id),
    CONSTRAINT fk_inv_area FOREIGN KEY (area_id) REFERENCES area(area_id),
    CONSTRAINT fk_inv_ubic FOREIGN KEY (ubicacion_id) REFERENCES ubicacion(ubicacion_id),
    CONSTRAINT ck_inv_estado CHECK (estado IN ('A', 'C'))
);
COMMENT ON TABLE inventario_fisico IS 'Tomas de inventario físico por área o ubicación.';
COMMENT ON COLUMN inventario_fisico.inventario_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN inventario_fisico.empresa_id IS 'Empresa. → empresa';
COMMENT ON COLUMN inventario_fisico.fecha IS 'Fecha de la toma.';
COMMENT ON COLUMN inventario_fisico.area_id IS 'Área inventariada; nulo = toda la empresa. → area';
COMMENT ON COLUMN inventario_fisico.ubicacion_id IS 'Ubicación inventariada. → ubicacion';
COMMENT ON COLUMN inventario_fisico.estado IS 'A = abierto, C = cerrado.';
COMMENT ON COLUMN inventario_fisico.responsable IS 'Usuario responsable de la toma.';

CREATE TABLE inventario_detalle (
    inventario_id            INTEGER NOT NULL,
    activo_fijo_id           INTEGER NOT NULL,
    resultado                CHAR(1) NOT NULL DEFAULT 'N',
    estado_fisico            CHAR(1),
    ubicacion_encontrada_id  INTEGER,
    observacion              VARCHAR(250),
    CONSTRAINT pk_inventario_detalle PRIMARY KEY (inventario_id, activo_fijo_id),
    CONSTRAINT fk_invdet_inv FOREIGN KEY (inventario_id) REFERENCES inventario_fisico(inventario_id) ON DELETE CASCADE,
    CONSTRAINT fk_invdet_af FOREIGN KEY (activo_fijo_id) REFERENCES activo_fijo(activo_fijo_id),
    CONSTRAINT fk_invdet_ubic FOREIGN KEY (ubicacion_encontrada_id) REFERENCES ubicacion(ubicacion_id),
    CONSTRAINT ck_invdet_resultado CHECK (resultado IN ('E', 'N', 'O')),
    CONSTRAINT ck_invdet_estado CHECK (estado_fisico IS NULL OR estado_fisico IN ('B', 'R', 'M')),
    CONSTRAINT ck_invdet_otra CHECK (resultado <> 'O' OR ubicacion_encontrada_id IS NOT NULL)
);
COMMENT ON TABLE inventario_detalle IS 'Resultado de la toma por activo; base de la conciliación.';
COMMENT ON COLUMN inventario_detalle.inventario_id IS 'Toma de inventario. → inventario_fisico';
COMMENT ON COLUMN inventario_detalle.activo_fijo_id IS 'Activo esperado o encontrado. → activo_fijo';
COMMENT ON COLUMN inventario_detalle.resultado IS 'E = encontrado, N = no encontrado, O = en otra ubicación.';
COMMENT ON COLUMN inventario_detalle.estado_fisico IS 'B = bueno, R = regular, M = malo.';
COMMENT ON COLUMN inventario_detalle.ubicacion_encontrada_id IS 'Dónde se encontró, si no estaba en su ubicación. → ubicacion';
COMMENT ON COLUMN inventario_detalle.observacion IS 'Observación del inventariador.';

-- -----------------------------------------------------------------------------
-- 9. Auditoría (historial que no se puede borrar)
-- -----------------------------------------------------------------------------
CREATE TABLE auditoria_activo (
    auditoria_id  BIGINT GENERATED ALWAYS AS IDENTITY,
    tabla         VARCHAR(40) NOT NULL,
    operacion     CHAR(1)     NOT NULL,
    registro_id   BIGINT      NOT NULL,
    usuario       VARCHAR(60) NOT NULL DEFAULT current_user,
    fecha         TIMESTAMP   NOT NULL DEFAULT now(),
    antes         JSONB,
    despues       JSONB,
    CONSTRAINT pk_auditoria_activo PRIMARY KEY (auditoria_id),
    CONSTRAINT ck_aud_operacion CHECK (operacion IN ('I', 'U', 'D'))
);
CREATE INDEX ix_aud_registro ON auditoria_activo (tabla, registro_id);
COMMENT ON TABLE auditoria_activo IS 'Historial de cambios en activos y movimientos; no admite UPDATE ni DELETE.';
COMMENT ON COLUMN auditoria_activo.auditoria_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN auditoria_activo.tabla IS 'Tabla afectada.';
COMMENT ON COLUMN auditoria_activo.operacion IS 'I = alta, U = cambio, D = eliminación.';
COMMENT ON COLUMN auditoria_activo.registro_id IS 'Identificador del registro afectado.';
COMMENT ON COLUMN auditoria_activo.usuario IS 'Usuario de base de datos (o el que envíe la aplicación).';
COMMENT ON COLUMN auditoria_activo.fecha IS 'Fecha y hora del cambio.';
COMMENT ON COLUMN auditoria_activo.antes IS 'Registro antes del cambio.';
COMMENT ON COLUMN auditoria_activo.despues IS 'Registro después del cambio.';

CREATE FUNCTION fn_auditoria() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT; v_user TEXT;
BEGIN
    v_user := COALESCE(NULLIF(current_setting('app.usuario', true), ''), current_user);
    IF TG_OP = 'DELETE' THEN
        v_id := (to_jsonb(OLD) ->> TG_ARGV[0])::BIGINT;
    ELSE
        v_id := (to_jsonb(NEW) ->> TG_ARGV[0])::BIGINT;
    END IF;
    INSERT INTO auditoria_activo (tabla, operacion, registro_id, usuario, antes, despues)
    VALUES (TG_TABLE_NAME, left(TG_OP, 1), v_id, v_user,
            CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END,
            CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END);
    RETURN NULL;
END $$;
CREATE TRIGGER tg_aud_activo AFTER INSERT OR UPDATE OR DELETE ON activo_fijo
    FOR EACH ROW EXECUTE FUNCTION fn_auditoria('activo_fijo_id');
CREATE TRIGGER tg_aud_movimiento AFTER INSERT OR UPDATE OR DELETE ON movimiento_activo
    FOR EACH ROW EXECUTE FUNCTION fn_auditoria('movimiento_id');

CREATE FUNCTION fn_auditoria_inmutable() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'El historial de auditoría no se puede modificar ni borrar';
END $$;
CREATE TRIGGER tg_aud_inmutable BEFORE UPDATE OR DELETE ON auditoria_activo
    FOR EACH ROW EXECUTE FUNCTION fn_auditoria_inmutable();

COMMIT;
