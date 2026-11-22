import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service.js';
import { ApiError } from '../../common/api-error.js';

// Columnas que devuelve la API para un activo (JSON en snake_case)
const SELECT_ACTIVO = `
  SELECT a.activo_fijo_id, a.empresa_id, a.codigo_patrimonial, a.descripcion,
         a.clase_activo_id, k.codigo AS clase_codigo, k.nombre AS clase_nombre,
         a.marca, a.modelo, a.serie_placa,
         a.fecha_adquisicion, a.fecha_inicio_uso,
         a.costo_adquisicion, a.valor_residual, a.vida_util_meses, a.tasa_tributaria,
         a.metodo_depreciacion, a.tipo_activo_fijo, a.estado_activo_fijo, a.situacion,
         a.proveedor_id, a.area_id, a.ubicacion_id, a.custodio_id, a.fecha_registro
    FROM ple.activo_fijo a
    JOIN ple.clase_activo k ON k.clase_activo_id = a.clase_activo_id`;

// Datos que se exigen al crear un activo (el código patrimonial lo genera el backend)
const OBLIGATORIOS = [
  'empresa_id',
  'descripcion',
  'clase_activo_id',
  'fecha_adquisicion',
  'costo_adquisicion',
];

// Datos opcionales que se aceptan al crear; si no se envían, la base pone su valor por defecto.
// situacion no se acepta: todo activo nuevo queda 'P' (pendiente de aprobación).
const OPCIONALES = [
  'marca',
  'modelo',
  'serie_placa',
  'fecha_inicio_uso',
  'valor_residual',
  'vida_util_meses',
  'tasa_tributaria',
  'metodo_depreciacion',
  'tipo_activo_fijo',
  'estado_activo_fijo',
  'proveedor_id',
  'area_id',
  'ubicacion_id',
  'custodio_id',
];

const FECHA = /^\d{4}-\d{2}-\d{2}$/;
const ENTERO_POSITIVO = /^[1-9]\d*$/;

@Injectable()
export class ActivosFijosService {
  constructor(private readonly db: DatabaseService) {}

  async listarClases() {
    const { rows } = await this.db.query(
      `SELECT clase_activo_id, codigo, nombre, cuenta_activo, cuenta_depreciacion, cuenta_gasto,
              depreciable, vida_util_meses, tasa_tributaria_max
         FROM ple.clase_activo
        WHERE activo
        ORDER BY clase_activo_id`,
    );
    return { data: rows };
  }

  async listar(pageTxt?: string, limitTxt?: string) {
    const page = this.leerEntero('page', pageTxt, 1);
    const limit = Math.min(this.leerEntero('limit', limitTxt, 50), 100);

    const [datos, conteo] = await Promise.all([
      this.db.query(
        `${SELECT_ACTIVO} ORDER BY a.activo_fijo_id LIMIT $1 OFFSET $2`,
        [limit, (page - 1) * limit],
      ),
      this.db.query<{ total: number }>(
        'SELECT count(*)::int AS total FROM ple.activo_fijo',
      ),
    ]);
    return { data: datos.rows, page, limit, total: conteo.rows[0].total };
  }

  async obtener(id: number) {
    const { rows } = await this.db.query(
      `${SELECT_ACTIVO} WHERE a.activo_fijo_id = $1`,
      [id],
    );
    if (rows.length === 0) {
      throw new ApiError(
        404,
        'NO_ENCONTRADO',
        `No existe el activo fijo ${id}`,
      );
    }
    return rows[0];
  }

  async crear(body: unknown) {
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      throw new ApiError(
        400,
        'SOLICITUD_INVALIDA',
        'Se esperaba un objeto JSON',
      );
    }
    const datos = body as Record<string, unknown>;

    const faltantes = OBLIGATORIOS.filter(
      (c) => datos[c] === undefined || datos[c] === null || datos[c] === '',
    );
    if (faltantes.length > 0) {
      throw new ApiError(400, 'DATOS_FALTANTES', 'Faltan datos obligatorios', {
        campos: faltantes,
      });
    }

    // Solo columnas conocidas; las opcionales sin valor se omiten para que la base ponga su DEFAULT
    const columnas = [
      ...OBLIGATORIOS,
      ...OPCIONALES.filter(
        (c) => datos[c] !== undefined && datos[c] !== null && datos[c] !== '',
      ),
    ];
    for (const c of columnas) {
      const v = datos[c];
      if (!['string', 'number', 'boolean'].includes(typeof v)) {
        throw new ApiError(
          400,
          'DATO_INVALIDO',
          `El campo ${c} tiene un valor no válido`,
          { campo: c },
        );
      }
      if (c.startsWith('fecha_') && !FECHA.test(String(v))) {
        throw new ApiError(
          400,
          'DATO_INVALIDO',
          `El campo ${c} debe tener el formato AAAA-MM-DD`,
          { campo: c },
        );
      }
    }

    const id = await this.db.transaction(async (client) => {
      // Bloquea la numeración de esta empresa hasta el COMMIT (evita códigos repetidos)
      await client.query(
        `SELECT pg_advisory_xact_lock(hashtext('ple.activo_fijo.codigo'), $1::int)`,
        [datos.empresa_id],
      );
      const { rows } = await client.query<{ ultimo: number | null }>(
        `SELECT max(substring(codigo_patrimonial FROM 4)::int) AS ultimo
           FROM ple.activo_fijo
          WHERE empresa_id = $1 AND codigo_patrimonial ~ '^AF-[0-9]{1,9}$'`,
        [datos.empresa_id],
      );
      const codigo = 'AF-' + String((rows[0].ultimo ?? 0) + 1).padStart(4, '0');

      const nombres = ['codigo_patrimonial', ...columnas];
      const valores = [codigo, ...columnas.map((c) => datos[c])];
      const marcadores = valores.map((_, i) => `$${i + 1}`);
      const insert = await client.query<{ activo_fijo_id: number }>(
        `INSERT INTO ple.activo_fijo (${nombres.join(', ')}) VALUES (${marcadores.join(', ')})
         RETURNING activo_fijo_id`,
        valores,
      );
      return insert.rows[0].activo_fijo_id;
    });

    return this.obtener(id);
  }

  private leerEntero(
    nombre: string,
    valor: string | undefined,
    porDefecto: number,
  ): number {
    if (valor === undefined || valor === '') return porDefecto;
    if (!ENTERO_POSITIVO.test(valor)) {
      throw new ApiError(
        400,
        'SOLICITUD_INVALIDA',
        `El parámetro ${nombre} debe ser un entero mayor que 0`,
      );
    }
    return Number(valor);
  }
}
