import {
  Body,
  Controller,
  Get,
  Patch,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';

import { KratosSessionGuard } from '../auth/kratos-session.guard';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @UseGuards(KratosSessionGuard)
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

  @UseGuards(KratosSessionGuard)
  @Patch('me')
  async updateProfile(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Body() body: { displayName?: string },
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    return this.usersService.updateProfile(req.user.id, body);
  }

  @UseGuards(KratosSessionGuard)
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
