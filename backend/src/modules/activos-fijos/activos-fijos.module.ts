import { Module } from '@nestjs/common';
import { ActivosFijosController } from './activos-fijos.controller.js';
import { ActivosFijosService } from './activos-fijos.service.js';

@Module({
  controllers: [ActivosFijosController],
  providers: [ActivosFijosService],
})
export class ActivosFijosModule {}
