import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
} from '@nestjs/common';
import { ActivosFijosService } from './activos-fijos.service.js';

@Controller('activos-fijos')
export class ActivosFijosController {
  constructor(private readonly service: ActivosFijosService) {}

  /** GET /api/v1/activos-fijos/clases */
  @Get('clases')
  listarClases() {
    return this.service.listarClases();
  }

  /** GET /api/v1/activos-fijos?page=1&limit=50 */
  @Get()
  listar(@Query('page') page?: string, @Query('limit') limit?: string) {
    return this.service.listar(page, limit);
  }

  /** GET /api/v1/activos-fijos/:id */
  @Get(':id')
  obtener(@Param('id', ParseIntPipe) id: number) {
    return this.service.obtener(id);
  }

  /** POST /api/v1/activos-fijos */
  @Post()
  crear(@Body() body: unknown) {
    return this.service.crear(body);
  }
}
