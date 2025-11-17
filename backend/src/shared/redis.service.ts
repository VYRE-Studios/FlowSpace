import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly publisher: Redis;
  private readonly subscriber: Redis;

  constructor(private readonly configService: ConfigService) {
    const url =
      this.configService.get<string>('REDIS_URL') ?? 'redis://localhost:6379';

    this.publisher = new Redis(url, {
      retryStrategy: (times) => {
        // Retry with exponential backoff, but don't fail startup
        const delay = Math.min(times * 50, 2000);
        return delay;
      },
      maxRetriesPerRequest: null,
      enableReadyCheck: false,
      lazyConnect: true, // Don't connect immediately
      showFriendlyErrorStack: false,
    });
    
    this.subscriber = new Redis(url, {
      retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
      },
      maxRetriesPerRequest: null,
      enableReadyCheck: false,
      lazyConnect: true,
      showFriendlyErrorStack: false,
    });
    
    // Handle errors gracefully - suppress unhandled error events
    this.publisher.on('error', (error: any) => {
      // Redis connection errors are expected if Redis isn't running
      // Suppress all connection-related errors silently
      const errorMsg = error?.message || error?.toString() || '';
      const isConnectionError = 
        errorMsg.includes('connect') || 
        errorMsg.includes('ECONNREFUSED') ||
        errorMsg.includes('AggregateError') ||
        error?.name === 'AggregateError';
      
      if (!isConnectionError) {
        console.debug('[Redis] Publisher error:', errorMsg);
      }
      // Silently ignore connection errors
    });
    
    this.subscriber.on('error', (error: any) => {
      // Redis connection errors are expected if Redis isn't running
      // Suppress all connection-related errors silently
      const errorMsg = error?.message || error?.toString() || '';
      const isConnectionError = 
        errorMsg.includes('connect') || 
        errorMsg.includes('ECONNREFUSED') ||
        errorMsg.includes('AggregateError') ||
        error?.name === 'AggregateError';
      
      if (!isConnectionError) {
        console.debug('[Redis] Subscriber error:', errorMsg);
      }
      // Silently ignore connection errors
    });
    
    // Connect in background, don't block startup
    this.publisher.connect().catch(() => {
      // Redis not available, but continue anyway
    });
    this.subscriber.connect().catch(() => {
      // Redis not available, but continue anyway
    });
  }

  getPublisher(): Redis {
    return this.publisher;
  }

  getSubscriber(): Redis {
    return this.subscriber;
  }

  async publish(channel: string, payload: unknown): Promise<number> {
    try {
      const message =
        typeof payload === 'string' ? payload : JSON.stringify(payload);
      
      // Check if publisher is connected
      if (this.publisher.status !== 'ready') {
        await this.publisher.connect().catch(() => {
          // Redis not available
          return 0;
        });
      }
      
      if (this.publisher.status === 'ready') {
        return await this.publisher.publish(channel, message);
      }
      return 0;
    } catch (error) {
      // Redis not available, but continue anyway
      return 0;
    }
  }

  async subscribe(
    channels: string[],
    handler: (channel: string, payload: string) => void,
  ): Promise<void> {
    if (channels.length === 0) {
      return;
    }

    try {
      // Check if subscriber is connected, if not try to connect
      if (this.subscriber.status !== 'ready') {
        await this.subscriber.connect().catch(() => {
          // Redis not available, but don't block startup
          return;
        });
      }
      
      if (this.subscriber.status === 'ready') {
        await this.subscriber.subscribe(...channels);
        this.subscriber.on('message', handler);
      }
    } catch (error) {
      // Redis not available, but continue anyway
      console.warn('Redis subscribe failed, continuing without Redis:', error);
    }
  }

  async onModuleDestroy(): Promise<void> {
    await Promise.all([this.publisher.quit(), this.subscriber.quit()]);
  }
}
