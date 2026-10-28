-- =====================================================================
--  BASE DE DATOS PLE-SUNAT
--  Script de arranque PostgreSQL (>= 12)
--  Catálogos: Tablas 1-12 SUNAT (Anexo de Libros y Registros Electrónicos)
--             + núcleo transaccional que las utiliza.
--
--  Ejecución:   psql -U postgres -f ple_sunat.sql
--  El script crea la base 'ple_sunat' si no existe, se conecta a ella y
--  (re)crea el esquema 'ple'. ¡Reejecutarlo BORRA el esquema 'ple'!
-- =====================================================================

\set ON_ERROR_STOP on
SET client_encoding = 'UTF8';

SELECT 'CREATE DATABASE ple_sunat ENCODING ''UTF8'' TEMPLATE template0'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'ple_sunat')\gexec

\connect ple_sunat
\encoding UTF8
SET client_encoding = 'UTF8';

BEGIN;

DROP SCHEMA IF EXISTS ple CASCADE;
CREATE SCHEMA ple;
COMMENT ON SCHEMA ple IS 'Esquema de libros y registros vinculados a asuntos tributarios (PLE-SUNAT).';
SET search_path TO ple, public;

-- =====================================================================
--  PARTE 1. CATÁLOGOS SUNAT (TABLAS 1 A 12)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tabla 1: tipos de medio de pago.
-- ---------------------------------------------------------------------
CREATE TABLE tipo_medio_pago (
    codigo        CHAR(3)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tipo_medio_pago PRIMARY KEY (codigo),
    CONSTRAINT ck_tipo_medio_pago_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  tipo_medio_pago IS 'Tabla 1 SUNAT: tipos de medio de pago.';
COMMENT ON COLUMN tipo_medio_pago.codigo IS 'Código oficial SUNAT (Tabla 1).';
COMMENT ON COLUMN tipo_medio_pago.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN tipo_medio_pago.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO tipo_medio_pago (codigo, descripcion) VALUES
    ('001', 'DEPÓSITO EN CUENTA'),
    ('002', 'GIRO'),
    ('003', 'TRANSFERENCIA DE FONDOS'),
    ('004', 'ORDEN DE PAGO'),
    ('005', 'TARJETA DE DÉBITO'),
    ('006', 'TARJETA DE CRÉDITO'),
    ('007', 'CHEQUES CON LA CLÁUSULA DE "NO NEGOCIABLE", "INTRANSFERIBLES", "NO A LA ORDEN" U OTRA EQUIVALENTE, A QUE SE REFIERE EL INCISO F) DEL ARTICULO 5° DEL DECRETO LEGISLATIVO.'),
    ('008', 'EFECTIVO, POR OPERACIONES EN LAS QUE NO EXISTE OBLIGACIÓN DE UTILIZAR MEDIOS DE PAGO'),
    ('009', 'EFECTIVO, EN LOS DEMÁS CASOS'),
    ('010', 'MEDIOS DE PAGO DE COMERCIO EXTERIOR'),
    ('011', 'LETRAS DE CAMBIO'),
    ('101', 'TRANSFERENCIAS - COMERCIO EXTERIOR'),
    ('102', 'CHEQUES BANCARIOS - COMERCIO EXTERIOR'),
    ('103', 'ORDEN DE PAGO SIMPLE - COMERCIO EXTERIOR'),
    ('104', 'ORDEN DE PAGO DOCUMENTARIO - COMERCIO EXTERIOR'),
    ('105', 'REMESA SIMPLE - COMERCIO EXTERIOR'),
    ('106', 'REMESA DOCUMENTARIA - COMERCIO EXTERIOR'),
    ('107', 'CARTA DE CRÉDITO SIMPLE - COMERCIO EXTERIOR'),
    ('108', 'CARTA DE CRÉDITO DOCUMENTARIO - COMERCIO EXTERIOR'),
    ('999', 'OTROS MEDIOS DE PAGO (ESPECIFICAR)');

-- ---------------------------------------------------------------------
-- Tabla 2: tipos de documento de identidad.
-- ---------------------------------------------------------------------
CREATE TABLE tipo_documento_identidad (
    codigo        CHAR(1)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tipo_documento_identidad PRIMARY KEY (codigo),
    CONSTRAINT ck_tipo_documento_identidad_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  tipo_documento_identidad IS 'Tabla 2 SUNAT: tipos de documento de identidad.';
COMMENT ON COLUMN tipo_documento_identidad.codigo IS 'Código oficial SUNAT (Tabla 2).';
COMMENT ON COLUMN tipo_documento_identidad.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN tipo_documento_identidad.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO tipo_documento_identidad (codigo, descripcion) VALUES
    ('0', 'OTROS TIPOS DE DOCUMENTOS'),
    ('1', 'DOCUMENTO NACIONAL DE IDENTIDAD (DNI)'),
    ('4', 'CARNET DE EXTRANJERIA'),
    ('6', 'REGISTRO ÚNICO DE CONTRIBUYENTES'),
    ('7', 'PASAPORTE');

-- ---------------------------------------------------------------------
-- Tabla 3: entidades financieras (bancos).
-- ---------------------------------------------------------------------
CREATE TABLE entidad_financiera (
    codigo        CHAR(2)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_entidad_financiera PRIMARY KEY (codigo),
    CONSTRAINT ck_entidad_financiera_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  entidad_financiera IS 'Tabla 3 SUNAT: entidades financieras (bancos).';
COMMENT ON COLUMN entidad_financiera.codigo IS 'Código oficial SUNAT (Tabla 3).';
COMMENT ON COLUMN entidad_financiera.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN entidad_financiera.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO entidad_financiera (codigo, descripcion) VALUES
    ('01', 'CENTRAL RESERVA DEL PERU'),
    ('02', 'DE CREDITO DEL PERU'),
    ('03', 'INTERNACIONAL DEL PERU'),
    ('05', 'LATINO'),
    ('07', 'CITIBANK DEL PERU S.A.'),
    ('08', 'STANDARD CHARTERED'),
    ('09', 'SCOTIABANK PERU'),
    ('11', 'CONTINENTAL'),
    ('12', 'DE LIMA'),
    ('16', 'MERCANTIL'),
    ('18', 'NACION'),
    ('22', 'SANTANDER CENTRAL HISPANO'),
    ('23', 'DE COMERCIO'),
    ('25', 'REPUBLICA'),
    ('26', 'NBK BANK'),
    ('29', 'BANCOSUR'),
    ('35', 'FINANCIERO DEL PERU'),
    ('37', 'DEL PROGRESO'),
    ('38', 'INTERAMERICANO FINANZAS'),
    ('39', 'BANEX'),
    ('40', 'NUEVO MUNDO'),
    ('41', 'SUDAMERICANO'),
    ('42', 'DEL LIBERTADOR'),
    ('43', 'DEL TRABAJO'),
    ('44', 'SOLVENTA'),
    ('45', 'SERBANCO SA.'),
    ('46', 'BANK OF BOSTON'),
    ('47', 'ORION'),
    ('48', 'DEL PAIS'),
    ('49', 'MI BANCO'),
    ('50', 'BNP PARIBAS'),
    ('53', 'HSBC BANK PERU S.A.'),
    ('99', 'OTROS');

-- ---------------------------------------------------------------------
-- Tabla 4: tipos de moneda.
-- ---------------------------------------------------------------------
CREATE TABLE tipo_moneda (
    codigo        CHAR(1)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tipo_moneda PRIMARY KEY (codigo),
    CONSTRAINT ck_tipo_moneda_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  tipo_moneda IS 'Tabla 4 SUNAT: tipos de moneda.';
COMMENT ON COLUMN tipo_moneda.codigo IS 'Código oficial SUNAT (Tabla 4).';
COMMENT ON COLUMN tipo_moneda.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN tipo_moneda.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO tipo_moneda (codigo, descripcion) VALUES
    ('1', 'NUEVOS SOLES'),
    ('2', 'DÓLARES AMERICANOS'),
    ('9', 'OTRA MONEDA (ESPECIFICAR)');

-- ---------------------------------------------------------------------
-- Tabla 5: tipos de existencia (inventarios).
-- ---------------------------------------------------------------------
CREATE TABLE tipo_existencia (
    codigo        CHAR(2)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tipo_existencia PRIMARY KEY (codigo),
    CONSTRAINT ck_tipo_existencia_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  tipo_existencia IS 'Tabla 5 SUNAT: tipos de existencia (inventarios).';
COMMENT ON COLUMN tipo_existencia.codigo IS 'Código oficial SUNAT (Tabla 5).';
COMMENT ON COLUMN tipo_existencia.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN tipo_existencia.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO tipo_existencia (codigo, descripcion) VALUES
    ('01', 'MERCADERÍA'),
    ('02', 'PRODUCTO TERMINADO'),
    ('03', 'MATERIAS PRIMAS Y AUXILIARES - MATERIALES'),
    ('04', 'ENVASES Y EMBALAJES'),
    ('05', 'SUMINISTROS DIVERSOS'),
    ('99', 'OTROS (ESPECIFICAR)');

-- ---------------------------------------------------------------------
-- Tabla 6: códigos de unidad de medida.
-- ---------------------------------------------------------------------
CREATE TABLE unidad_medida (
    codigo        CHAR(2)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_unidad_medida PRIMARY KEY (codigo),
    CONSTRAINT ck_unidad_medida_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  unidad_medida IS 'Tabla 6 SUNAT: códigos de unidad de medida.';
COMMENT ON COLUMN unidad_medida.codigo IS 'Código oficial SUNAT (Tabla 6).';
COMMENT ON COLUMN unidad_medida.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN unidad_medida.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO unidad_medida (codigo, descripcion) VALUES
    ('01', 'KILOGRAMOS'),
    ('02', 'LIBRAS'),
    ('03', 'TONELADAS LARGAS'),
    ('04', 'TONELADAS MÉTRICAS'),
    ('05', 'TONELADAS CORTAS'),
    ('06', 'GRAMOS'),
    ('07', 'UNIDADES'),
    ('08', 'LITROS'),
    ('09', 'GALONES'),
    ('10', 'BARRILES'),
    ('11', 'LATAS'),
    ('12', 'CAJAS'),
    ('13', 'MILLARES'),
    ('14', 'METROS CÚBICOS'),
    ('15', 'METROS'),
    ('99', 'OTROS (ESPECIFICAR)');

-- ---------------------------------------------------------------------
-- Tabla 7: tipos de intangible.
-- ---------------------------------------------------------------------
CREATE TABLE tipo_intangible (
    codigo        CHAR(2)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tipo_intangible PRIMARY KEY (codigo),
    CONSTRAINT ck_tipo_intangible_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  tipo_intangible IS 'Tabla 7 SUNAT: tipos de intangible.';
COMMENT ON COLUMN tipo_intangible.codigo IS 'Código oficial SUNAT (Tabla 7).';
COMMENT ON COLUMN tipo_intangible.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN tipo_intangible.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO tipo_intangible (codigo, descripcion) VALUES
    ('01', 'INTANGIBLE ADQUIRIDO'),
    ('02', 'INTANGIBLE EN ETAPA DE INVESTIGACIÓN'),
    ('03', 'INTANGIBLE EN ETAPA DE DESARROLLO');

-- ---------------------------------------------------------------------
-- Tabla 8: códigos de libros y registros contables.
-- ---------------------------------------------------------------------
CREATE TABLE libro_registro (
    codigo        CHAR(2)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_libro_registro PRIMARY KEY (codigo),
    CONSTRAINT ck_libro_registro_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  libro_registro IS 'Tabla 8 SUNAT: códigos de libros y registros contables.';
COMMENT ON COLUMN libro_registro.codigo IS 'Código oficial SUNAT (Tabla 8).';
COMMENT ON COLUMN libro_registro.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN libro_registro.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO libro_registro (codigo, descripcion) VALUES
    ('01', 'LIBRO CAJA Y BANCOS'),
    ('02', 'LIBRO DE INGRESOS Y GASTOS'),
    ('03', 'LIBRO DE INVENTARIOS Y BALANCES'),
    ('04', 'LIBRO DE RETENCIONES INCISOS E) Y F) DEL ARTICULO 34° DE LA LEY DEL IMPUESTO A LA RENTA'),
    ('05', 'LIBRO DIARIO'),
    ('06', 'LIBRO MAYOR'),
    ('07', 'REGISTRO DE ACTIVOS FIJOS'),
    ('08', 'REGISTRO DE COMPRAS'),
    ('09', 'REGISTRO DE CONSIGNACIONES'),
    ('10', 'REGISTRO DE COSTOS'),
    ('11', 'REGISTRO DE HUÉSPEDES'),
    ('12', 'REGISTRO DE INVENTARIO PERMANENTE EN UNIDADES FÍSICAS'),
    ('13', 'REGISTRO DE INVENTARIO PERMANENTE VALORIZADO'),
    ('14', 'REGISTRO DE VENTAS E INGRESOS'),
    ('15', 'REGISTRO DE VENTAS E INGRESOS - ARTÍCULO 23° RESOLUCIÓN DE SUPERINTENDENCIA N° 266-2004/SUNAT'),
    ('16', 'REGISTRO DEL RÉGIMEN DE PERCEPCIONES'),
    ('17', 'REGISTRO DEL RÉGIMEN DE RETENCIONES'),
    ('18', 'REGISTRO IVAP'),
    ('19', 'REGISTRO(S) AUXILIAR(ES) DE ADQUISICIONES - ARTÍCULO 8° RESOLUCIÓN DE SUPERINTENDENCIA N° 022-98/SUNAT'),
    ('20', 'REGISTRO(S) AUXILIAR(ES) DE ADQUISICIONES - INCISO A) PRIMER PÁRRAFO ARTÍCULO 5° RESOLUCIÓN DE SUPERINTENDENCIA N° 021-99/SUNAT'),
    ('21', 'REGISTRO(S) AUXILIAR(ES) DE ADQUISICIONES - INCISO A) PRIMER PÁRRAFO ARTÍCULO 5° RESOLUCIÓN DE SUPERINTENDENCIA N° 142-2001/SUNAT'),
    ('22', 'REGISTRO(S) AUXILIAR(ES) DE ADQUISICIONES - INCISO C) PRIMER PÁRRAFO ARTÍCULO 5° RESOLUCIÓN DE SUPERINTENDENCIA N° 256-2004/SUNAT'),
    ('23', 'REGISTRO(S) AUXILIAR(ES) DE ADQUISICIONES - INCISO A) PRIMER PÁRRAFO ARTÍCULO 5° RESOLUCIÓN DE SUPERINTENDENCIA N° 257-2004/SUNAT'),
    ('24', 'REGISTRO(S) AUXILIAR(ES) DE ADQUISICIONES - INCISO C) PRIMER PÁRRAFO ARTÍCULO 5° RESOLUCIÓN DE SUPERINTENDENCIA N° 258-2004/SUNAT'),
    ('25', 'REGISTRO(S) AUXILIAR(ES) DE ADQUISICIONES - INCISO A) PRIMER PÁRRAFO ARTÍCULO 5° RESOLUCIÓN DE SUPERINTENDENCIA N° 259-2004/SUNAT'),
    ('26', 'REGISTRO DE RETENCIONES ARTÍCULO 77-A DE LA LEY DEL IMPUESTO A LA RENTA'),
    ('27', 'LIBRO DE ACTAS DE LA EMPRESA INDIVIDUAL DE RESPONSABILIDAD LIMITADA'),
    ('28', 'LIBRO DE ACTAS DE LA JUNTA GENERAL DE ACCIONISTAS'),
    ('29', 'LIBRO DE ACTAS DEL DIRECTORIO'),
    ('30', 'LIBRO DE MATRÍCULA DE ACCIONES'),
    ('31', 'LIBRO DE PLANILLAS');

-- ---------------------------------------------------------------------
-- Tabla 9: códigos de cuenta contable (PCGR).
-- ---------------------------------------------------------------------
CREATE TABLE cuenta_contable (
    codigo        VARCHAR(5)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_cuenta_contable PRIMARY KEY (codigo),
    CONSTRAINT ck_cuenta_contable_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  cuenta_contable IS 'Tabla 9 SUNAT: códigos de cuenta contable (PCGR).';
COMMENT ON COLUMN cuenta_contable.codigo IS 'Código oficial SUNAT (Tabla 9).';
COMMENT ON COLUMN cuenta_contable.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN cuenta_contable.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO cuenta_contable (codigo, descripcion) VALUES
    ('10', 'CAJA Y BANCOS'),
    ('12', 'CLIENTES'),
    ('16', 'CUENTAS POR COBRAR DIVERSAS'),
    ('20', 'MERCADERÍAS'),
    ('21', 'PRODUCTOS TERMINADOS'),
    ('33', 'INMUEBLES, MAQUINARIAS Y EQUIPO'),
    ('34', 'INTANGIBLES'),
    ('38', 'CARGAS DIFERIDAS'),
    ('39', 'DEPRECIACIÓN Y AMORTIZACIÓN ACUMULADA'),
    ('4011D', 'TRIBUTOS POR PAGAR - IGV - DÉBITOS'),
    ('4011C', 'TRIBUTOS POR PAGAR - IGV - CRÉDITOS'),
    ('4017D', 'TRIBUTOS POR PAGAR - IMPUESTO A LA RENTA - DÉBITOS'),
    ('4017C', 'TRIBUTOS POR PAGAR - IMPUESTO A LA RENTA - CRÉDITOS'),
    ('402', 'TRIBUTOS POR PAGAR - OTROS IMPUESTOS'),
    ('42', 'PROVEEDORES'),
    ('46', 'CUENTAS POR PAGAR DIVERSAS'),
    ('50', 'CAPITAL'),
    ('58', 'RESERVAS'),
    ('59', 'RESULTADOS ACUMULADOS'),
    ('60', 'COMPRAS'),
    ('61', 'VARIACIÓN DE EXISTENCIAS'),
    ('62', 'CARGAS DE PERSONAL'),
    ('63', 'SERVICIOS PRESTADOS POR TERCEROS'),
    ('65', 'CARGAS DIVERSAS DE GESTIÓN'),
    ('66', 'CARGAS EXCEPCIONALES'),
    ('67', 'CARGAS FINANCIERAS'),
    ('68', 'PROVISIONES DEL EJERCICIO'),
    ('69', 'COSTO DE VENTAS'),
    ('96', 'GASTOS ADMINISTRATIVOS'),
    ('97', 'GASTOS DE VENTAS'),
    ('70', 'VENTAS'),
    ('75', 'INGRESOS DIVERSOS'),
    ('76', 'INGRESOS EXCEPCIONALES'),
    ('77', 'INGRESOS FINANCIEROS'),
    ('79', 'CARGAS IMPUTABLES A LA CUENTA DE COSTOS');

-- ---------------------------------------------------------------------
-- Tabla 10: tipos de comprobante de pago o documento.
-- ---------------------------------------------------------------------
CREATE TABLE tipo_comprobante (
    codigo        CHAR(2)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tipo_comprobante PRIMARY KEY (codigo),
    CONSTRAINT ck_tipo_comprobante_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  tipo_comprobante IS 'Tabla 10 SUNAT: tipos de comprobante de pago o documento.';
COMMENT ON COLUMN tipo_comprobante.codigo IS 'Código oficial SUNAT (Tabla 10).';
COMMENT ON COLUMN tipo_comprobante.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN tipo_comprobante.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO tipo_comprobante (codigo, descripcion) VALUES
    ('00', 'Otros (especificar)'),
    ('01', 'Factura'),
    ('02', 'Recibo por Honorarios'),
    ('03', 'Boleta de Venta'),
    ('04', 'Liquidación de compra'),
    ('05', 'Boleto de compañía de aviación comercial por el servicio de transporte aéreo de pasajeros'),
    ('06', 'Carta de porte aéreo por el servicio de transporte de carga aérea'),
    ('07', 'Nota de crédito'),
    ('08', 'Nota de débito'),
    ('09', 'Guía de remisión - Remitente'),
    ('10', 'Recibo por Arrendamiento'),
    ('11', 'Póliza emitida por las Bolsas de Valores, Bolsas de Productos o Agentes de Intermediación por operaciones realizadas en las Bolsas de Valores o Productos o fuera de las mismas, autorizadas por CONASEV'),
    ('12', 'Ticket o cinta emitido por máquina registradora'),
    ('13', 'Documento emitido por bancos, instituciones financieras, crediticias y de seguros que se encuentren bajo el control de la Superintendencia de Banca y Seguros'),
    ('14', 'Recibo por servicios públicos de suministro de energía eléctrica, agua, teléfono, telex y telegráficos y otros servicios complementarios que se incluyan en el recibo de servicio público'),
    ('15', 'Boleto emitido por las empresas de transporte público urbano de pasajeros'),
    ('16', 'Boleto de viaje emitido por las empresas de transporte público interprovincial de pasajeros dentro del país'),
    ('17', 'Documento emitido por la Iglesia Católica por el arrendamiento de bienes inmuebles'),
    ('18', 'Documento emitido por las Administradoras Privadas de Fondo de Pensiones que se encuentran bajo la supervisión de la Superintendencia de Administradoras Privadas de Fondos de Pensiones'),
    ('19', 'Boleto o entrada por atracciones y espectáculos públicos'),
    ('20', 'Comprobante de Retención'),
    ('21', 'Conocimiento de embarque por el servicio de transporte de carga marítima'),
    ('22', 'Comprobante por Operaciones No Habituales'),
    ('23', 'Pólizas de Adjudicación emitidas con ocasión del remate o adjudicación de bienes por venta forzada, por los martilleros o las entidades que rematen o subasten bienes por cuenta de terceros'),
    ('24', 'Certificado de pago de regalías emitidas por PERUPETRO S.A'),
    ('25', 'Documento de Atribución (Ley del Impuesto General a las Ventas e Impuesto Selectivo al Consumo, Art. 19º, último párrafo, R.S. N° 022-98-SUNAT).'),
    ('26', 'Recibo por el Pago de la Tarifa por Uso de Agua Superficial con fines agrarios y por el pago de la Cuota para la ejecución de una determinada obra o actividad acordada por la Asamblea General de la Comisión de Regantes o Resolución expedida por el Jefe de la Unidad de Aguas y de Riego (Decreto Supremo N° 003-90-AG, Arts. 28 y 48)'),
    ('27', 'Seguro Complementario de Trabajo de Riesgo'),
    ('28', 'Tarifa Unificada de Uso de Aeropuerto'),
    ('29', 'Documentos emitidos por la COFOPRI en calidad de oferta de venta de terrenos, los correspondientes a las subastas públicas y a la retribución de los servicios que presta'),
    ('30', 'Documentos emitidos por las empresas que desempeñan el rol adquirente en los sistemas de pago mediante tarjetas de crédito y débito'),
    ('31', 'Guía de Remisión - Transportista'),
    ('32', 'Documentos emitidos por las empresas recaudadoras de la denominada Garantía de Red Principal a la que hace referencia el numeral 7.6 del artículo 7° de la Ley N° 27133 – Ley de Promoción del Desarrollo de la Industria del Gas Natural'),
    ('34', 'Documento del Operador'),
    ('35', 'Documento del Partícipe'),
    ('36', 'Recibo de Distribución de Gas Natural'),
    ('37', 'Documentos que emitan los concesionarios del servicio de revisiones técnicas vehiculares, por la prestación de dicho servicio'),
    ('50', 'Declaración Única de Aduanas - Importación definitiva'),
    ('52', 'Despacho Simplificado - Importación Simplificada'),
    ('53', 'Declaración de Mensajería o Courier'),
    ('54', 'Liquidación de Cobranza'),
    ('87', 'Nota de Crédito Especial'),
    ('88', 'Nota de Débito Especial'),
    ('91', 'Comprobante de No Domiciliado'),
    ('96', 'Exceso de crédito fiscal por retiro de bienes'),
    ('97', 'Nota de Crédito - No Domiciliado'),
    ('98', 'Nota de Débito - No Domiciliado'),
    ('99', 'Otros -Consolidado de Boletas de Venta');

-- ---------------------------------------------------------------------
-- Tabla 11: códigos de aduana.
-- ---------------------------------------------------------------------
CREATE TABLE aduana (
    codigo        CHAR(3)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_aduana PRIMARY KEY (codigo),
    CONSTRAINT ck_aduana_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  aduana IS 'Tabla 11 SUNAT: códigos de aduana.';
COMMENT ON COLUMN aduana.codigo IS 'Código oficial SUNAT (Tabla 11).';
COMMENT ON COLUMN aduana.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN aduana.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO aduana (codigo, descripcion) VALUES
    ('019', 'TUMBES'),
    ('028', 'TALARA'),
    ('046', 'PAITA'),
    ('055', 'CHICLAYO'),
    ('082', 'SALAVERRY'),
    ('091', 'CHIMBOTE'),
    ('118', 'MARÍTIMA DEL CALLAO'),
    ('127', 'PISCO'),
    ('145', 'MOLLENDO MATARANI'),
    ('154', 'AREQUIPA'),
    ('163', 'ILO'),
    ('172', 'TACNA'),
    ('181', 'PUNO'),
    ('190', 'CUZCO'),
    ('217', 'PUCALLPA'),
    ('226', 'IQUITOS'),
    ('235', 'AÉREA DEL CALLAO'),
    ('244', 'POSTAL DE LIMA'),
    ('262', 'DESAGUADERO'),
    ('271', 'TARAPOTO'),
    ('280', 'PUERTO MALDONADO'),
    ('299', 'LA TINA'),
    ('884', 'DEPENDENCIA FERROVIARIA TACNA'),
    ('893', 'DEPENDENCIA POSTAL TACNA'),
    ('910', 'DEPENDENCIA POSTAL AREQUIPA'),
    ('929', 'COMPLEJO FRONTERIZO STA ROSA TACNA'),
    ('938', 'TERMINAL TERRESTRE TACNA'),
    ('947', 'AEROPUERTO TACNA'),
    ('956', 'CETICOS TACNA'),
    ('965', 'DEPENDENCIA POSTAL DE SALAVERRY');

-- ---------------------------------------------------------------------
-- Tabla 12: tipos de operación (movimientos de inventario).
-- ---------------------------------------------------------------------
CREATE TABLE tipo_operacion (
    codigo        CHAR(2)       NOT NULL,
    descripcion   VARCHAR(400) NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tipo_operacion PRIMARY KEY (codigo),
    CONSTRAINT ck_tipo_operacion_codigo CHECK (btrim(codigo) <> '')
);
COMMENT ON TABLE  tipo_operacion IS 'Tabla 12 SUNAT: tipos de operación (movimientos de inventario).';
COMMENT ON COLUMN tipo_operacion.codigo IS 'Código oficial SUNAT (Tabla 12).';
COMMENT ON COLUMN tipo_operacion.descripcion IS 'Descripción oficial del código.';
COMMENT ON COLUMN tipo_operacion.activo IS 'Indica si el código está vigente para nuevos registros.';

INSERT INTO tipo_operacion (codigo, descripcion) VALUES
    ('01', 'VENTA'),
    ('02', 'COMPRA'),
    ('03', 'CONSIGNACIÓN RECIBIDA'),
    ('04', 'CONSIGNACIÓN ENTREGADA'),
    ('05', 'DEVOLUCIÓN RECIBIDA'),
    ('06', 'DEVOLUCIÓN ENTREGADA'),
    ('07', 'PROMOCIÓN'),
    ('08', 'PREMIO'),
    ('09', 'DONACIÓN'),
    ('10', 'SALIDA A PRODUCCIÓN'),
    ('11', 'TRANSFERENCIA ENTRE ALMACENES'),
    ('12', 'RETIRO'),
    ('13', 'MERMAS'),
    ('14', 'DESMEDROS'),
    ('15', 'DESTRUCCIÓN'),
    ('16', 'SALDO INICIAL'),
    ('99', 'OTROS (ESPECIFICAR)');


-- =====================================================================
--  PARTE 2. NÚCLEO TRANSACCIONAL
-- =====================================================================

-- ---------------------------------------------------------------------
-- Empresa (contribuyente que lleva los libros)
-- ---------------------------------------------------------------------
CREATE TABLE empresa (
    empresa_id      INTEGER GENERATED ALWAYS AS IDENTITY,
    ruc             CHAR(11)     NOT NULL,
    razon_social    VARCHAR(200) NOT NULL,
    direccion       VARCHAR(250),
    fecha_registro  TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT pk_empresa PRIMARY KEY (empresa_id),
    CONSTRAINT uq_empresa_ruc UNIQUE (ruc),
    CONSTRAINT ck_empresa_ruc CHECK (ruc ~ '^(10|15|17|20)[0-9]{9}$')
);
COMMENT ON TABLE  empresa IS 'Contribuyente (empresa) obligado a llevar los libros y registros.';
COMMENT ON COLUMN empresa.empresa_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN empresa.ruc IS 'RUC de 11 dígitos (prefijo 10, 15, 17 o 20).';
COMMENT ON COLUMN empresa.razon_social IS 'Razón social o nombre del contribuyente.';
COMMENT ON COLUMN empresa.direccion IS 'Domicilio fiscal.';
COMMENT ON COLUMN empresa.fecha_registro IS 'Fecha y hora de alta en el sistema.';

-- ---------------------------------------------------------------------
-- Tercero (cliente / proveedor)
-- ---------------------------------------------------------------------
CREATE TABLE tercero (
    tercero_id        INTEGER GENERATED ALWAYS AS IDENTITY,
    tipo_documento    CHAR(1)      NOT NULL,
    numero_documento  VARCHAR(15)  NOT NULL,
    nombre            VARCHAR(200) NOT NULL,
    direccion         VARCHAR(250),
    es_cliente        BOOLEAN      NOT NULL DEFAULT FALSE,
    es_proveedor      BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_tercero PRIMARY KEY (tercero_id),
    CONSTRAINT uq_tercero_doc UNIQUE (tipo_documento, numero_documento),
    CONSTRAINT fk_tercero_tipo_doc FOREIGN KEY (tipo_documento)
        REFERENCES tipo_documento_identidad (codigo),
    CONSTRAINT ck_tercero_dni CHECK (tipo_documento <> '1' OR numero_documento ~ '^[0-9]{8}$'),
    CONSTRAINT ck_tercero_ruc CHECK (tipo_documento <> '6' OR numero_documento ~ '^[0-9]{11}$')
);
COMMENT ON TABLE  tercero IS 'Clientes y proveedores con los que opera la empresa.';
COMMENT ON COLUMN tercero.tercero_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN tercero.tipo_documento IS 'Tipo de documento de identidad (Tabla 2).';
COMMENT ON COLUMN tercero.numero_documento IS 'Número del documento (DNI 8 dígitos, RUC 11 dígitos).';
COMMENT ON COLUMN tercero.nombre IS 'Apellidos y nombres, denominación o razón social.';
COMMENT ON COLUMN tercero.direccion IS 'Dirección del tercero.';
COMMENT ON COLUMN tercero.es_cliente IS 'Verdadero si el tercero es cliente.';
COMMENT ON COLUMN tercero.es_proveedor IS 'Verdadero si el tercero es proveedor.';

-- ---------------------------------------------------------------------
-- Cuenta bancaria de la empresa
-- ---------------------------------------------------------------------
CREATE TABLE cuenta_bancaria (
    cuenta_bancaria_id  INTEGER GENERATED ALWAYS AS IDENTITY,
    empresa_id          INTEGER      NOT NULL,
    entidad_financiera  CHAR(2)      NOT NULL,
    tipo_moneda         CHAR(1)      NOT NULL,
    numero_cuenta       VARCHAR(30)  NOT NULL,
    cuenta_contable     VARCHAR(5)   NOT NULL DEFAULT '10',
    CONSTRAINT pk_cuenta_bancaria PRIMARY KEY (cuenta_bancaria_id),
    CONSTRAINT uq_cuenta_bancaria UNIQUE (entidad_financiera, numero_cuenta),
    CONSTRAINT fk_ctaban_empresa FOREIGN KEY (empresa_id) REFERENCES empresa (empresa_id),
    CONSTRAINT fk_ctaban_entidad FOREIGN KEY (entidad_financiera) REFERENCES entidad_financiera (codigo),
    CONSTRAINT fk_ctaban_moneda  FOREIGN KEY (tipo_moneda) REFERENCES tipo_moneda (codigo),
    CONSTRAINT fk_ctaban_cuenta  FOREIGN KEY (cuenta_contable) REFERENCES cuenta_contable (codigo)
);
COMMENT ON TABLE  cuenta_bancaria IS 'Cuentas bancarias de la empresa (Libro Caja y Bancos).';
COMMENT ON COLUMN cuenta_bancaria.cuenta_bancaria_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN cuenta_bancaria.empresa_id IS 'Empresa titular de la cuenta.';
COMMENT ON COLUMN cuenta_bancaria.entidad_financiera IS 'Banco (Tabla 3).';
COMMENT ON COLUMN cuenta_bancaria.tipo_moneda IS 'Moneda de la cuenta (Tabla 4).';
COMMENT ON COLUMN cuenta_bancaria.numero_cuenta IS 'Número de cuenta bancaria.';
COMMENT ON COLUMN cuenta_bancaria.cuenta_contable IS 'Cuenta contable asociada (Tabla 9), por defecto 10.';

-- ---------------------------------------------------------------------
-- Almacén / establecimiento
-- ---------------------------------------------------------------------
CREATE TABLE almacen (
    almacen_id   INTEGER GENERATED ALWAYS AS IDENTITY,
    empresa_id   INTEGER      NOT NULL,
    codigo       CHAR(7)      NOT NULL,
    nombre       VARCHAR(100) NOT NULL,
    direccion    VARCHAR(250),
    CONSTRAINT pk_almacen PRIMARY KEY (almacen_id),
    CONSTRAINT uq_almacen_codigo UNIQUE (empresa_id, codigo),
    CONSTRAINT fk_almacen_empresa FOREIGN KEY (empresa_id) REFERENCES empresa (empresa_id)
);
COMMENT ON TABLE  almacen IS 'Almacenes o establecimientos donde se custodian existencias.';
COMMENT ON COLUMN almacen.almacen_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN almacen.empresa_id IS 'Empresa propietaria del almacén.';
COMMENT ON COLUMN almacen.codigo IS 'Código de establecimiento anexo (7 caracteres).';
COMMENT ON COLUMN almacen.nombre IS 'Nombre del almacén.';
COMMENT ON COLUMN almacen.direccion IS 'Ubicación del almacén.';

-- ---------------------------------------------------------------------
-- Existencia (producto / bien inventariable)
-- ---------------------------------------------------------------------
CREATE TABLE existencia (
    existencia_id    INTEGER GENERATED ALWAYS AS IDENTITY,
    empresa_id       INTEGER      NOT NULL,
    codigo           VARCHAR(24)  NOT NULL,
    descripcion      VARCHAR(200) NOT NULL,
    tipo_existencia  CHAR(2)      NOT NULL,
    unidad_medida    CHAR(2)      NOT NULL,
    activo           BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_existencia PRIMARY KEY (existencia_id),
    CONSTRAINT uq_existencia_codigo UNIQUE (empresa_id, codigo),
    CONSTRAINT fk_exist_empresa FOREIGN KEY (empresa_id) REFERENCES empresa (empresa_id),
    CONSTRAINT fk_exist_tipo    FOREIGN KEY (tipo_existencia) REFERENCES tipo_existencia (codigo),
    CONSTRAINT fk_exist_unidad  FOREIGN KEY (unidad_medida) REFERENCES unidad_medida (codigo)
);
COMMENT ON TABLE  existencia IS 'Catálogo de existencias (bienes inventariables) de la empresa.';
COMMENT ON COLUMN existencia.existencia_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN existencia.empresa_id IS 'Empresa propietaria.';
COMMENT ON COLUMN existencia.codigo IS 'Código interno de la existencia.';
COMMENT ON COLUMN existencia.descripcion IS 'Descripción de la existencia.';
COMMENT ON COLUMN existencia.tipo_existencia IS 'Tipo de existencia (Tabla 5).';
COMMENT ON COLUMN existencia.unidad_medida IS 'Unidad de medida (Tabla 6).';
COMMENT ON COLUMN existencia.activo IS 'Indica si la existencia sigue en uso.';

-- ---------------------------------------------------------------------
-- Intangible
-- ---------------------------------------------------------------------
CREATE TABLE intangible (
    intangible_id      INTEGER GENERATED ALWAYS AS IDENTITY,
    empresa_id         INTEGER       NOT NULL,
    descripcion        VARCHAR(200)  NOT NULL,
    tipo_intangible    CHAR(2)       NOT NULL,
    fecha_inicio       DATE          NOT NULL,
    valor_contable     NUMERIC(14,2) NOT NULL,
    amortizacion_acum  NUMERIC(14,2) NOT NULL DEFAULT 0,
    cuenta_contable    VARCHAR(5)    NOT NULL DEFAULT '34',
    CONSTRAINT pk_intangible PRIMARY KEY (intangible_id),
    CONSTRAINT fk_intang_empresa FOREIGN KEY (empresa_id) REFERENCES empresa (empresa_id),
    CONSTRAINT fk_intang_tipo    FOREIGN KEY (tipo_intangible) REFERENCES tipo_intangible (codigo),
    CONSTRAINT fk_intang_cuenta  FOREIGN KEY (cuenta_contable) REFERENCES cuenta_contable (codigo),
    CONSTRAINT ck_intang_valores CHECK (valor_contable >= 0 AND amortizacion_acum BETWEEN 0 AND valor_contable)
);
COMMENT ON TABLE  intangible IS 'Activos intangibles (Libro de Inventarios y Balances).';
COMMENT ON COLUMN intangible.intangible_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN intangible.empresa_id IS 'Empresa propietaria.';
COMMENT ON COLUMN intangible.descripcion IS 'Descripción del intangible.';
COMMENT ON COLUMN intangible.tipo_intangible IS 'Tipo de intangible (Tabla 7).';
COMMENT ON COLUMN intangible.fecha_inicio IS 'Fecha de adquisición o inicio de la etapa.';
COMMENT ON COLUMN intangible.valor_contable IS 'Valor contable del intangible.';
COMMENT ON COLUMN intangible.amortizacion_acum IS 'Amortización acumulada.';
COMMENT ON COLUMN intangible.cuenta_contable IS 'Cuenta contable (Tabla 9), por defecto 34.';

-- ---------------------------------------------------------------------
-- Comprobante de pago (cabecera) - Registro de Compras / Ventas
-- ---------------------------------------------------------------------
CREATE TABLE comprobante (
    comprobante_id    BIGINT GENERATED ALWAYS AS IDENTITY,
    empresa_id        INTEGER       NOT NULL,
    libro_registro    CHAR(2)       NOT NULL,
    tipo_comprobante  CHAR(2)       NOT NULL,
    serie             VARCHAR(20)   NOT NULL,
    numero            VARCHAR(20)   NOT NULL,
    fecha_emision     DATE          NOT NULL,
    fecha_vencimiento DATE,
    tercero_id        INTEGER       NOT NULL,
    tipo_moneda       CHAR(1)       NOT NULL DEFAULT '1',
    tipo_cambio       NUMERIC(8,3)  NOT NULL DEFAULT 1.000,
    base_imponible    NUMERIC(14,2) NOT NULL DEFAULT 0,
    igv               NUMERIC(14,2) NOT NULL DEFAULT 0,
    no_gravado        NUMERIC(14,2) NOT NULL DEFAULT 0,
    total             NUMERIC(14,2) GENERATED ALWAYS AS (base_imponible + igv + no_gravado) STORED,
    aduana            CHAR(3),
    anio_dua          SMALLINT,
    estado            CHAR(1)       NOT NULL DEFAULT 'R',
    CONSTRAINT pk_comprobante PRIMARY KEY (comprobante_id),
    CONSTRAINT uq_comprobante UNIQUE (empresa_id, libro_registro, tercero_id, tipo_comprobante, serie, numero),
    CONSTRAINT fk_comp_empresa FOREIGN KEY (empresa_id) REFERENCES empresa (empresa_id),
    CONSTRAINT fk_comp_libro   FOREIGN KEY (libro_registro) REFERENCES libro_registro (codigo),
    CONSTRAINT fk_comp_tipo    FOREIGN KEY (tipo_comprobante) REFERENCES tipo_comprobante (codigo),
    CONSTRAINT fk_comp_tercero FOREIGN KEY (tercero_id) REFERENCES tercero (tercero_id),
    CONSTRAINT fk_comp_moneda  FOREIGN KEY (tipo_moneda) REFERENCES tipo_moneda (codigo),
    CONSTRAINT fk_comp_aduana  FOREIGN KEY (aduana) REFERENCES aduana (codigo),
    CONSTRAINT ck_comp_libro   CHECK (libro_registro IN ('08', '14')),
    CONSTRAINT ck_comp_estado  CHECK (estado IN ('R', 'A')),
    CONSTRAINT ck_comp_tc      CHECK (tipo_cambio > 0),
    CONSTRAINT ck_comp_fechas  CHECK (fecha_vencimiento IS NULL OR fecha_vencimiento >= fecha_emision),
    CONSTRAINT ck_comp_dua     CHECK ((aduana IS NULL) = (anio_dua IS NULL))
);
CREATE INDEX ix_comp_fecha   ON comprobante (empresa_id, fecha_emision);
CREATE INDEX ix_comp_tercero ON comprobante (tercero_id);
COMMENT ON TABLE  comprobante IS 'Cabecera de comprobantes de pago anotados en el Registro de Compras (08) o de Ventas (14).';
COMMENT ON COLUMN comprobante.comprobante_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN comprobante.empresa_id IS 'Empresa que registra el comprobante.';
COMMENT ON COLUMN comprobante.libro_registro IS 'Registro donde se anota (Tabla 8): 08 Compras o 14 Ventas.';
COMMENT ON COLUMN comprobante.tipo_comprobante IS 'Tipo de comprobante de pago (Tabla 10).';
COMMENT ON COLUMN comprobante.serie IS 'Serie del comprobante (o código de dependencia aduanera en DUA).';
COMMENT ON COLUMN comprobante.numero IS 'Número correlativo del comprobante.';
COMMENT ON COLUMN comprobante.fecha_emision IS 'Fecha de emisión.';
COMMENT ON COLUMN comprobante.fecha_vencimiento IS 'Fecha de vencimiento o de pago.';
COMMENT ON COLUMN comprobante.tercero_id IS 'Cliente (ventas) o proveedor (compras).';
COMMENT ON COLUMN comprobante.tipo_moneda IS 'Moneda del comprobante (Tabla 4).';
COMMENT ON COLUMN comprobante.tipo_cambio IS 'Tipo de cambio aplicado; 1.000 para moneda nacional.';
COMMENT ON COLUMN comprobante.base_imponible IS 'Base imponible gravada.';
COMMENT ON COLUMN comprobante.igv IS 'Impuesto General a las Ventas.';
COMMENT ON COLUMN comprobante.no_gravado IS 'Importe exonerado, inafecto o no gravado.';
COMMENT ON COLUMN comprobante.total IS 'Importe total (calculado: base + IGV + no gravado).';
COMMENT ON COLUMN comprobante.aduana IS 'Código de aduana (Tabla 11); solo para DUA/DSI.';
COMMENT ON COLUMN comprobante.anio_dua IS 'Año de emisión de la DUA/DSI.';
COMMENT ON COLUMN comprobante.estado IS 'Estado: R = registrado, A = anulado.';

-- ---------------------------------------------------------------------
-- Detalle de comprobante
-- ---------------------------------------------------------------------
CREATE TABLE comprobante_detalle (
    comprobante_id   BIGINT        NOT NULL,
    item             SMALLINT      NOT NULL,
    existencia_id    INTEGER       NOT NULL,
    cantidad         NUMERIC(14,4) NOT NULL,
    valor_unitario   NUMERIC(14,4) NOT NULL,
    valor_venta      NUMERIC(14,2) GENERATED ALWAYS AS (round(cantidad * valor_unitario, 2)) STORED,
    CONSTRAINT pk_comprobante_detalle PRIMARY KEY (comprobante_id, item),
    CONSTRAINT fk_compdet_comp FOREIGN KEY (comprobante_id)
        REFERENCES comprobante (comprobante_id) ON DELETE CASCADE,
    CONSTRAINT fk_compdet_exist FOREIGN KEY (existencia_id) REFERENCES existencia (existencia_id),
    CONSTRAINT ck_compdet_valores CHECK (cantidad > 0 AND valor_unitario >= 0)
);
COMMENT ON TABLE  comprobante_detalle IS 'Ítems (líneas) de cada comprobante de pago.';
COMMENT ON COLUMN comprobante_detalle.comprobante_id IS 'Comprobante al que pertenece la línea.';
COMMENT ON COLUMN comprobante_detalle.item IS 'Número de ítem dentro del comprobante.';
COMMENT ON COLUMN comprobante_detalle.existencia_id IS 'Existencia vendida o comprada.';
COMMENT ON COLUMN comprobante_detalle.cantidad IS 'Cantidad en la unidad de medida de la existencia.';
COMMENT ON COLUMN comprobante_detalle.valor_unitario IS 'Valor unitario sin impuestos.';
COMMENT ON COLUMN comprobante_detalle.valor_venta IS 'Valor de la línea (calculado: cantidad x valor unitario).';

-- ---------------------------------------------------------------------
-- Pago / cobro de comprobantes
-- ---------------------------------------------------------------------
CREATE TABLE pago (
    pago_id             BIGINT GENERATED ALWAYS AS IDENTITY,
    comprobante_id      BIGINT        NOT NULL,
    fecha_pago          DATE          NOT NULL,
    medio_pago          CHAR(3)       NOT NULL,
    cuenta_bancaria_id  INTEGER,
    tipo_moneda         CHAR(1)       NOT NULL DEFAULT '1',
    monto               NUMERIC(14,2) NOT NULL,
    numero_operacion    VARCHAR(30),
    CONSTRAINT pk_pago PRIMARY KEY (pago_id),
    CONSTRAINT fk_pago_comp   FOREIGN KEY (comprobante_id) REFERENCES comprobante (comprobante_id),
    CONSTRAINT fk_pago_medio  FOREIGN KEY (medio_pago) REFERENCES tipo_medio_pago (codigo),
    CONSTRAINT fk_pago_cuenta FOREIGN KEY (cuenta_bancaria_id) REFERENCES cuenta_bancaria (cuenta_bancaria_id),
    CONSTRAINT fk_pago_moneda FOREIGN KEY (tipo_moneda) REFERENCES tipo_moneda (codigo),
    CONSTRAINT ck_pago_monto  CHECK (monto > 0),
    CONSTRAINT ck_pago_banco  CHECK (medio_pago IN ('008', '009') OR cuenta_bancaria_id IS NOT NULL)
);
CREATE INDEX ix_pago_comp ON pago (comprobante_id);
COMMENT ON TABLE  pago IS 'Pagos y cobros asociados a comprobantes (bancarización, Libro Caja y Bancos).';
COMMENT ON COLUMN pago.pago_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN pago.comprobante_id IS 'Comprobante que se paga o cobra.';
COMMENT ON COLUMN pago.fecha_pago IS 'Fecha de la operación.';
COMMENT ON COLUMN pago.medio_pago IS 'Medio de pago utilizado (Tabla 1).';
COMMENT ON COLUMN pago.cuenta_bancaria_id IS 'Cuenta bancaria; obligatoria salvo pago en efectivo (008, 009).';
COMMENT ON COLUMN pago.tipo_moneda IS 'Moneda del pago (Tabla 4).';
COMMENT ON COLUMN pago.monto IS 'Importe pagado.';
COMMENT ON COLUMN pago.numero_operacion IS 'Número de operación bancaria, cheque, etc.';

-- ---------------------------------------------------------------------
-- Movimiento de inventario (Kardex)
-- ---------------------------------------------------------------------
CREATE TABLE movimiento_inventario (
    movimiento_id    BIGINT GENERATED ALWAYS AS IDENTITY,
    almacen_id       INTEGER       NOT NULL,
    existencia_id    INTEGER       NOT NULL,
    fecha            DATE          NOT NULL,
    tipo_operacion   CHAR(2)       NOT NULL,
    comprobante_id   BIGINT,
    cantidad_entrada NUMERIC(14,4) NOT NULL DEFAULT 0,
    cantidad_salida  NUMERIC(14,4) NOT NULL DEFAULT 0,
    costo_unitario   NUMERIC(14,4) NOT NULL DEFAULT 0,
    CONSTRAINT pk_movimiento_inventario PRIMARY KEY (movimiento_id),
    CONSTRAINT fk_mov_almacen FOREIGN KEY (almacen_id) REFERENCES almacen (almacen_id),
    CONSTRAINT fk_mov_exist   FOREIGN KEY (existencia_id) REFERENCES existencia (existencia_id),
    CONSTRAINT fk_mov_tipo    FOREIGN KEY (tipo_operacion) REFERENCES tipo_operacion (codigo),
    CONSTRAINT fk_mov_comp    FOREIGN KEY (comprobante_id) REFERENCES comprobante (comprobante_id),
    CONSTRAINT ck_mov_cant    CHECK (cantidad_entrada >= 0 AND cantidad_salida >= 0
                                     AND (cantidad_entrada > 0) <> (cantidad_salida > 0)),
    CONSTRAINT ck_mov_costo   CHECK (costo_unitario >= 0)
);
CREATE INDEX ix_mov_kardex ON movimiento_inventario (existencia_id, almacen_id, fecha);
COMMENT ON TABLE  movimiento_inventario IS 'Movimientos de entrada y salida de existencias (Registro de Inventario Permanente).';
COMMENT ON COLUMN movimiento_inventario.movimiento_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN movimiento_inventario.almacen_id IS 'Almacén donde ocurre el movimiento.';
COMMENT ON COLUMN movimiento_inventario.existencia_id IS 'Existencia movida.';
COMMENT ON COLUMN movimiento_inventario.fecha IS 'Fecha del movimiento.';
COMMENT ON COLUMN movimiento_inventario.tipo_operacion IS 'Tipo de operación (Tabla 12).';
COMMENT ON COLUMN movimiento_inventario.comprobante_id IS 'Comprobante que sustenta el movimiento, si existe.';
COMMENT ON COLUMN movimiento_inventario.cantidad_entrada IS 'Cantidad que ingresa (excluyente con salida).';
COMMENT ON COLUMN movimiento_inventario.cantidad_salida IS 'Cantidad que sale (excluyente con entrada).';
COMMENT ON COLUMN movimiento_inventario.costo_unitario IS 'Costo unitario del movimiento.';

-- ---------------------------------------------------------------------
-- Asiento contable (cabecera) - Libro Diario
-- ---------------------------------------------------------------------
CREATE TABLE asiento (
    asiento_id       BIGINT GENERATED ALWAYS AS IDENTITY,
    empresa_id       INTEGER      NOT NULL,
    periodo          CHAR(6)      NOT NULL,
    numero           INTEGER      NOT NULL,
    fecha            DATE         NOT NULL,
    libro_registro   CHAR(2)      NOT NULL DEFAULT '05',
    glosa            VARCHAR(250) NOT NULL,
    comprobante_id   BIGINT,
    CONSTRAINT pk_asiento PRIMARY KEY (asiento_id),
    CONSTRAINT uq_asiento_numero UNIQUE (empresa_id, periodo, numero),
    CONSTRAINT fk_asiento_empresa FOREIGN KEY (empresa_id) REFERENCES empresa (empresa_id),
    CONSTRAINT fk_asiento_libro   FOREIGN KEY (libro_registro) REFERENCES libro_registro (codigo),
    CONSTRAINT fk_asiento_comp    FOREIGN KEY (comprobante_id) REFERENCES comprobante (comprobante_id),
    CONSTRAINT ck_asiento_periodo CHECK (periodo ~ '^[0-9]{4}(0[1-9]|1[0-2])$'
                                         AND periodo = to_char(fecha, 'YYYYMM'))
);
COMMENT ON TABLE  asiento IS 'Cabecera de asientos contables (Libro Diario).';
COMMENT ON COLUMN asiento.asiento_id IS 'Identificador interno autogenerado.';
COMMENT ON COLUMN asiento.empresa_id IS 'Empresa que registra el asiento.';
COMMENT ON COLUMN asiento.periodo IS 'Periodo contable AAAAMM; debe coincidir con la fecha.';
COMMENT ON COLUMN asiento.numero IS 'Número correlativo del asiento dentro del periodo.';
COMMENT ON COLUMN asiento.fecha IS 'Fecha de la operación.';
COMMENT ON COLUMN asiento.libro_registro IS 'Libro o registro de origen (Tabla 8); por defecto 05 Diario.';
COMMENT ON COLUMN asiento.glosa IS 'Descripción de la operación.';
COMMENT ON COLUMN asiento.comprobante_id IS 'Comprobante que origina el asiento, si existe.';

-- ---------------------------------------------------------------------
-- Detalle de asiento contable
-- ---------------------------------------------------------------------
CREATE TABLE asiento_detalle (
    asiento_id       BIGINT        NOT NULL,
    linea            SMALLINT      NOT NULL,
    cuenta_contable  VARCHAR(5)    NOT NULL,
    debe             NUMERIC(14,2) NOT NULL DEFAULT 0,
    haber            NUMERIC(14,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_asiento_detalle PRIMARY KEY (asiento_id, linea),
    CONSTRAINT fk_asidet_asiento FOREIGN KEY (asiento_id) REFERENCES asiento (asiento_id) ON DELETE CASCADE,
    CONSTRAINT fk_asidet_cuenta  FOREIGN KEY (cuenta_contable) REFERENCES cuenta_contable (codigo),
    CONSTRAINT ck_asidet_importe CHECK (debe >= 0 AND haber >= 0 AND (debe > 0) <> (haber > 0))
);
CREATE INDEX ix_asidet_cuenta ON asiento_detalle (cuenta_contable);
COMMENT ON TABLE  asiento_detalle IS 'Movimientos al debe y al haber de cada asiento (base del Libro Mayor).';
COMMENT ON COLUMN asiento_detalle.asiento_id IS 'Asiento al que pertenece la línea.';
COMMENT ON COLUMN asiento_detalle.linea IS 'Número de línea dentro del asiento.';
COMMENT ON COLUMN asiento_detalle.cuenta_contable IS 'Cuenta contable afectada (Tabla 9).';
COMMENT ON COLUMN asiento_detalle.debe IS 'Importe al debe (excluyente con haber).';
COMMENT ON COLUMN asiento_detalle.haber IS 'Importe al haber (excluyente con debe).';

-- =====================================================================
--  PARTE 3. VISTAS DE APOYO
-- =====================================================================
CREATE VIEW v_asiento_cuadre AS
SELECT a.asiento_id, a.empresa_id, a.periodo, a.numero, a.fecha,
       COALESCE(SUM(d.debe), 0)  AS total_debe,
       COALESCE(SUM(d.haber), 0) AS total_haber,
       COALESCE(SUM(d.debe), 0) = COALESCE(SUM(d.haber), 0) AS cuadrado
FROM asiento a
LEFT JOIN asiento_detalle d ON d.asiento_id = a.asiento_id
GROUP BY a.asiento_id;
COMMENT ON VIEW v_asiento_cuadre IS 'Totales debe/haber por asiento e indicador de cuadre.';
COMMENT ON COLUMN v_asiento_cuadre.asiento_id IS 'Identificador del asiento.';
COMMENT ON COLUMN v_asiento_cuadre.empresa_id IS 'Empresa del asiento.';
COMMENT ON COLUMN v_asiento_cuadre.periodo IS 'Periodo contable AAAAMM.';
COMMENT ON COLUMN v_asiento_cuadre.numero IS 'Número del asiento.';
COMMENT ON COLUMN v_asiento_cuadre.fecha IS 'Fecha del asiento.';
COMMENT ON COLUMN v_asiento_cuadre.total_debe IS 'Suma de importes al debe.';
COMMENT ON COLUMN v_asiento_cuadre.total_haber IS 'Suma de importes al haber.';
COMMENT ON COLUMN v_asiento_cuadre.cuadrado IS 'Verdadero si debe = haber.';

CREATE VIEW v_kardex AS
SELECT m.movimiento_id, m.almacen_id, m.existencia_id, e.codigo AS codigo_existencia,
       m.fecha, m.tipo_operacion, t.descripcion AS operacion,
       m.cantidad_entrada, m.cantidad_salida, m.costo_unitario,
       SUM(m.cantidad_entrada - m.cantidad_salida)
           OVER (PARTITION BY m.almacen_id, m.existencia_id
                 ORDER BY m.fecha, m.movimiento_id) AS saldo_cantidad
FROM movimiento_inventario m
JOIN existencia e     ON e.existencia_id = m.existencia_id
JOIN tipo_operacion t ON t.codigo = m.tipo_operacion;
COMMENT ON VIEW v_kardex IS 'Kardex en unidades físicas con saldo acumulado por almacén y existencia.';
COMMENT ON COLUMN v_kardex.movimiento_id IS 'Identificador del movimiento.';
COMMENT ON COLUMN v_kardex.almacen_id IS 'Almacén del movimiento.';
COMMENT ON COLUMN v_kardex.existencia_id IS 'Existencia movida.';
COMMENT ON COLUMN v_kardex.codigo_existencia IS 'Código interno de la existencia.';
COMMENT ON COLUMN v_kardex.fecha IS 'Fecha del movimiento.';
COMMENT ON COLUMN v_kardex.tipo_operacion IS 'Código del tipo de operación (Tabla 12).';
COMMENT ON COLUMN v_kardex.operacion IS 'Descripción del tipo de operación.';
COMMENT ON COLUMN v_kardex.cantidad_entrada IS 'Cantidad ingresada.';
COMMENT ON COLUMN v_kardex.cantidad_salida IS 'Cantidad retirada.';
COMMENT ON COLUMN v_kardex.costo_unitario IS 'Costo unitario del movimiento.';
COMMENT ON COLUMN v_kardex.saldo_cantidad IS 'Saldo acumulado en unidades físicas.';

COMMIT;

-- Verificación rápida
SELECT 'tipo_medio_pago' AS tabla, count(*) FROM ple.tipo_medio_pago
UNION ALL SELECT 'tipo_documento_identidad', count(*) FROM ple.tipo_documento_identidad
UNION ALL SELECT 'entidad_financiera', count(*) FROM ple.entidad_financiera
UNION ALL SELECT 'tipo_moneda', count(*) FROM ple.tipo_moneda
UNION ALL SELECT 'tipo_existencia', count(*) FROM ple.tipo_existencia
UNION ALL SELECT 'unidad_medida', count(*) FROM ple.unidad_medida
UNION ALL SELECT 'tipo_intangible', count(*) FROM ple.tipo_intangible
UNION ALL SELECT 'libro_registro', count(*) FROM ple.libro_registro
UNION ALL SELECT 'cuenta_contable', count(*) FROM ple.cuenta_contable
UNION ALL SELECT 'tipo_comprobante', count(*) FROM ple.tipo_comprobante
UNION ALL SELECT 'aduana', count(*) FROM ple.aduana
UNION ALL SELECT 'tipo_operacion', count(*) FROM ple.tipo_operacion;