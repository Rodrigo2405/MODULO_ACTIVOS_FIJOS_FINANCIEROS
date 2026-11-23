import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  Logger,
} from '@nestjs/common';
import type { Response } from 'express';
import pg from 'pg';

interface CuerpoError {
  codigo: string;
  mensaje: string;
  detalle: unknown;
}

const CODIGO_POR_ESTADO: Record<number, string> = {
  400: 'SOLICITUD_INVALIDA',
  404: 'NO_ENCONTRADO',
  409: 'CONFLICTO',
};

/**
 * Convierte cualquier error en { codigo, mensaje, detalle }.
 * Los errores de PostgreSQL suelen ser reglas de la base (restricciones o triggers),
 * no fallos: se devuelven como 400 o 409 con el mensaje de la base.
 */
@Catch()
export class HttpErrorFilter implements ExceptionFilter {
  private readonly logger = new Logger('HttpErrorFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const res = host.switchToHttp().getResponse<Response>();
    const [status, cuerpo] = this.traducir(exception);
    if (status >= 500) this.logger.error(exception);
    res.status(status).json(cuerpo);
  }

  private traducir(e: unknown): [number, CuerpoError] {
    if (e instanceof HttpException) {
      const status = e.getStatus();
      const r = e.getResponse() as any;
      if (r && typeof r === 'object' && 'codigo' in r) return [status, r];
      const mensaje =
        typeof r === 'string'
          ? r
          : Array.isArray(r?.message)
            ? r.message.join('; ')
            : (r?.message ?? e.message);
      return [
        status,
        {
          codigo: CODIGO_POR_ESTADO[status] ?? 'ERROR',
          mensaje,
          detalle: null,
        },
      ];
    }

    if (e instanceof pg.DatabaseError) return this.traducirPg(e);

    return [
      500,
      {
        codigo: 'ERROR_INTERNO',
        mensaje: 'Error interno del servidor',
        detalle: null,
      },
    ];
  }

  private traducirPg(e: pg.DatabaseError): [number, CuerpoError] {
    const detalle = {
      restriccion: e.constraint ?? null,
      columna: e.column ?? null,
      detalle: e.detail ?? null,
    };
    const code = e.code ?? '';
    if (code === '23505')
      return [
        409,
        {
          codigo: 'DUPLICADO',
          mensaje: 'Ya existe un registro con esos datos',
          detalle,
        },
      ];
    if (code === '23503')
      return [
        400,
        {
          codigo: 'REFERENCIA_INVALIDA',
          mensaje: 'Un dato hace referencia a un registro que no existe',
          detalle,
        },
      ];
    if (code === '23502')
      return [
        400,
        {
          codigo: 'DATO_OBLIGATORIO',
          mensaje: `Falta un dato obligatorio: ${e.column}`,
          detalle,
        },
      ];
    if (code === '23514')
      return [
        400,
        {
          codigo: 'REGLA_INCUMPLIDA',
          mensaje: `No se cumple la regla ${e.constraint}`,
          detalle,
        },
      ];
    if (code === 'P0001')
      return [409, { codigo: 'REGLA_NEGOCIO', mensaje: e.message, detalle }];
    if (code.startsWith('22'))
      return [400, { codigo: 'DATO_INVALIDO', mensaje: e.message, detalle }];
    return [
      500,
      {
        codigo: 'ERROR_BASE_DATOS',
        mensaje: 'Error en la base de datos',
        detalle: null,
      },
    ];
  }
}
