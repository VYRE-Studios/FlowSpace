import { NestFactory } from "@nestjs/core";
import { Logger } from "@nestjs/common";
import { AppModule } from "./app.module";

async function bootstrap() {
  const logger = new Logger("?-06");
  const app = await NestFactory.create(AppModule, { cors: true });
  app.setGlobalPrefix("api/v1");
  const port = Number(process.env.PORT) || 4000;
  await app.listen(port);
  logger.log(`?? Flowspace ?-06 running on http://localhost:${port}/api/v1/*`);
}
bootstrap();
