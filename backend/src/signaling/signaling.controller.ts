import { Body, Controller, Post, UseGuards, Req } from '@nestjs/common';
import type { Request } from 'express';

import { KratosSessionGuard } from '../auth/kratos-session.guard';
import { SignalingService } from './signaling.service';

@Controller('signaling')
export class SignalingController {
  constructor(private readonly signaling: SignalingService) {}

  @UseGuards(KratosSessionGuard)
  @Post('rooms')
  createRoom(
    @Req() _req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Body() body: { name: string },
  ) {
    return this.signaling.createRoom(body.name);
  }

  @UseGuards(KratosSessionGuard)
  @Post('token')
  getAccessToken(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Body() body: { roomName: string; identity?: string },
  ) {
    const identity = body.identity ?? req.user?.displayName ?? req.user?.id;
    return this.signaling.generateAccessToken(
      body.roomName,
      identity ?? undefined,
    );
  }
}