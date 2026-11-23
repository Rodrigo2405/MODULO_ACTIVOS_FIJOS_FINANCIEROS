import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { HttpErrorFilter } from './common/http-error.filter.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api/v1');
  app.enableCors();
  app.useGlobalFilters(new HttpErrorFilter());

  const port = Number(process.env.PORT) || 3001;
  await app.listen(port, '0.0.0.0');
  console.log(`API escuchando en http://localhost:${port}/api/v1`);
}
await bootstrap();
