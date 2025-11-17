import { NestFactory } from "@nestjs/core";
import { Logger } from "@nestjs/common";
import { AppModule } from "./app.module";

async function findAvailablePort(startPort: number, maxAttempts: number): Promise<number> {
  const net = await import("net");
  const logger = new Logger("PortFinder");
  
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const port = startPort + attempt;
    const isAvailable = await new Promise<boolean>((resolve) => {
      const server = net.createServer();
      server.listen(port, () => {
        server.once("close", () => resolve(true));
        server.close();
      });
      server.on("error", () => resolve(false));
    });
    
    if (isAvailable) {
      return port;
    }
    
    if (attempt < maxAttempts - 1) {
      logger.debug(`Port ${port} is in use, checking ${port + 1}...`);
    }
  }
  
  throw new Error(`No available port found between ${startPort} and ${startPort + maxAttempts - 1}`);
}

async function bootstrap() {
  const logger = new Logger("?-06");
  const app = await NestFactory.create(AppModule, { cors: true });
  app.setGlobalPrefix("api/v1");
  
  // Auto-select available port starting from 4000
  const startPort = Number(process.env.PORT) || 4000;
  const maxAttempts = 10; // Try up to 10 ports (4000-4009)
  
  try {
    const port = await findAvailablePort(startPort, maxAttempts);
    
    await app.listen(port);
    logger.log(`?? Flowspace ?-06 running on http://localhost:${port}/api/v1/*`);
    
    if (port !== startPort) {
      logger.warn(`Note: Using port ${port} instead of ${startPort} (port ${startPort} was in use)`);
    }
  } catch (error: any) {
    logger.error(`Failed to find available port: ${error.message}`);
    logger.error(`Tried ports ${startPort} through ${startPort + maxAttempts - 1}`);
    logger.error(`Please free a port or set PORT environment variable to a different port.`);
    process.exit(1);
  }
}
bootstrap();
