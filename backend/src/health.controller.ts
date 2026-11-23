import { Controller, Get } from '@nestjs/common';
import { DatabaseService } from './database/database.service.js';
import { ApiError } from './common/api-error.js';

@Controller('health')
export class HealthController {
  constructor(private readonly db: DatabaseService) {}

  @Get()
  async check() {
    try {
      await this.db.query('select 1');
    } catch (e) {
      throw new ApiError(
        503,
        'BD_NO_DISPONIBLE',
        'No se pudo conectar a la base de datos',
        (e as Error).message,
      );
    }
    return { estado: 'ok', base_datos: 'ok' };
  }
}
