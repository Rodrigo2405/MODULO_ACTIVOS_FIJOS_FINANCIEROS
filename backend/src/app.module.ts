import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from './database/database.module.js';
import { HealthController } from './health.controller.js';
import { ActivosFijosModule } from './modules/activos-fijos/activos-fijos.module.js';

@Module({
  imports: [
    // Lee backend/.env y lo deja en process.env
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    ActivosFijosModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
