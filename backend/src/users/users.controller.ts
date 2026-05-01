import {
  Body,
  Controller,
  Get,
  Patch,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';

import { JwtAuthGuard } from '../auth/jwt.guard';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getProfile(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    return this.usersService.getProfile(req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('me')
  async updateProfile(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Body() body: { displayName?: string; nickname?: string },
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    return this.usersService.updateProfile(req.user.id, body);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/workspaces')
  async getUserWorkspaces(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    return this.usersService.getUserWorkspaces(req.user.id);
  }
}
