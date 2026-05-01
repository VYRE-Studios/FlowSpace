import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import { AppModule } from './app.module';
import { RedisIoAdapter } from './adapters/redis-io.adapter';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  
  const app = await NestFactory.create(AppModule, {
    cors: {
      origin: [
        'http://localhost',
        'http://localhost:*',
        'https://*.onrender.com',
        'https://*.railway.app',
        process.env.FRONTEND_URL || '*'
      ],
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Session-Token']
    }
  });

  app.setGlobalPrefix('api/v1', {
    exclude: ['assets/*']
  });

  // Set up Redis adapter for Socket.IO (if REDIS_URL available)
  try {
    const redisIoAdapter = new RedisIoAdapter(app);
    await redisIoAdapter.connectToRedis();
    app.useWebSocketAdapter(redisIoAdapter);
  } catch (error) {
    logger.error('Failed to connect Redis adapter:', error);
    logger.warn('Continuing with in-memory Socket.IO adapter');
  }

  const port = process.env.PORT || 4000;
  await app.listen(port, '0.0.0.0');
  
  logger.log(`🚀 FlowSpace backend running on port ${port}`);
  logger.log(`📡 API: http://localhost:${port}/api/v1`);
  logger.log(`🔌 WebSocket: ws://localhost:${port}`);
}

bootstrap();
