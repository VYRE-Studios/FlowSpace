import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import { sign } from 'jsonwebtoken';

@Injectable()
export class SignalingService {
  constructor(private readonly config: ConfigService) {}

  async createRoom(roomName: string) {
    const endpoint = this.config.get<string>('LIVEKIT_URL');
    if (!endpoint) {
      throw new Error('LIVEKIT_URL is not configured');
    }

    const response = await fetch(`${endpoint}/createRoom`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: roomName }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Failed to create room: ${response.status} ${text}`);
    }

    return response.json();
  }

  generateAccessToken(roomName: string, identity?: string) {
    const apiKey = this.config.get<string>('LIVEKIT_API_KEY');
    const apiSecret = this.config.get<string>('LIVEKIT_API_SECRET');

    if (!apiKey || !apiSecret) {
      throw new Error('LIVEKIT_API credentials are not configured');
    }

    const userIdentity = identity ?? randomUUID();

    const token = sign(
      {
        video: {
          room: roomName,
          roomJoin: true,
          canPublish: true,
          canSubscribe: true,
        },
      },
      apiSecret,
      {
        issuer: apiKey,
        expiresIn: '1h',
        subject: userIdentity,
      },
    );

    return {
      token,
      identity: userIdentity,
      wsUrl: this.config.get<string>('LIVEKIT_WS_URL') ?? '',
    };
  }
}
