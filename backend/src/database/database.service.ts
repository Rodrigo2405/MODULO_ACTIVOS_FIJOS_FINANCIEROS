import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import pg from 'pg';

// DATE (1082) y TIMESTAMP (1114) llegan como texto tal cual los guarda la base
// ("2026-11-22", "2026-11-22 13:40:00.123"). Así no hay corrimientos por zona horaria.
// NUMERIC ya llega como texto ("6000.00").
pg.types.setTypeParser(1082, (v) => v);
pg.types.setTypeParser(1114, (v) => v);

@Injectable()
export class DatabaseService implements OnModuleDestroy {
  private readonly pool: pg.Pool;

  constructor(config: ConfigService) {
    const connectionString = config.get<string>('DATABASE_URL');
    if (!connectionString) {
      throw new Error(
        'Falta la variable de entorno DATABASE_URL (ver backend/.env.example)',
      );
    }
    this.pool = new pg.Pool({
      connectionString,
      // Solo si la nube lo exige: DB_SSL=true
      ssl:
        config.get<string>('DB_SSL') === 'true'
          ? { rejectUnauthorized: false }
          : undefined,
    });
    // Las funciones de los triggers en db/ usan las tablas sin el prefijo "ple."
    // (por ejemplo clase_activo, auditoria_activo): necesitan este search_path.
    this.pool.on('connect', (client) => {
      client.query('SET search_path TO ple, public').catch(() => {});
    });
  }

  query<T extends pg.QueryResultRow = any>(text: string, params?: unknown[]) {
    return this.pool.query<T>(text, params);
  }

  /** Ejecuta fn dentro de una transacción (BEGIN/COMMIT, ROLLBACK si falla). */
  async transaction<T>(fn: (client: pg.PoolClient) => Promise<T>): Promise<T> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await fn(client);
      await client.query('COMMIT');
      return result;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }

  async onModuleDestroy() {
    await this.pool.end();
  }
}
