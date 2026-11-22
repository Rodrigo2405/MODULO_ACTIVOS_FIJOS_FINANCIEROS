import { HttpException } from '@nestjs/common';

/** Error de la API con el cuerpo del contrato: { codigo, mensaje, detalle }. */
export class ApiError extends HttpException {
  constructor(
    status: number,
    codigo: string,
    mensaje: string,
    detalle: unknown = null,
  ) {
    super({ codigo, mensaje, detalle }, status);
  }
}
