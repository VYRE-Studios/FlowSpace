import { Controller, Post, Body } from '@nestjs/common';

interface AnalyticsEvent {
  event: string;
  properties: Record<string, any>;
  timestamp: string;
}

@Controller('api/analytics')
export class AnalyticsController {
  @Post('batch')
  async receiveBatch(@Body() body: { events: AnalyticsEvent[] }) {
    console.log(`[Analytics] Received ${body.events.length} events`);
    
    for (const event of body.events) {
      console.log(`[Analytics] ${event.event}:`, event.properties);
    }

    return { success: true, received: body.events.length };
  }
}
