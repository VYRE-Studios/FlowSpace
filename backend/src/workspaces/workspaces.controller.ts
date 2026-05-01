import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';

import { JwtAuthGuard } from '../auth/jwt.guard';
import { WorkspacesService } from './workspaces.service';

@Controller('workspaces')
export class WorkspacesController {
  constructor(private readonly workspaces: WorkspacesService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  async listForUser(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Query('userId') userId?: string,
    @Query('email') email?: string,
  ) {
    if (req.user) {
      await this.workspaces.ensureUserProfile(req.user);
    }
    const resolvedUserId = userId ?? req.user?.id;
    const resolvedEmail = email ?? req.user?.email;
    return this.workspaces.listForUser({
      userId: resolvedUserId,
      email: resolvedEmail,
    });
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  async createWorkspace(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Body() body: { name: string; ownerId?: string; description?: string },
  ) {
    if (req.user) {
      await this.workspaces.ensureUserProfile(req.user);
    }
    const ownerId = body.ownerId ?? req.user?.id;
    return this.workspaces.createWorkspace(
      body.name,
      ownerId,
      body.description,
    );
  }

  @UseGuards(JwtAuthGuard)
  @Get(':workspaceId/channels')
  async getWorkspaceChannels(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
  ) {
    if (req.user) {
      await this.workspaces.ensureUserProfile(req.user);
    }
    return this.workspaces.getWorkspaceChannels(workspaceId, req.user?.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':workspaceId/members')
  async getMembers(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
  ) {
    return this.workspaces.getMembers(workspaceId, req.user?.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':workspaceId/members')
  async addMember(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
    @Body() body: { email: string },
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    return this.workspaces.addMember(workspaceId, body.email, req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':workspaceId/members/:userId/remove')
  async removeMember(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
    @Param('userId') userId: string,
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    return this.workspaces.removeMember(workspaceId, userId, req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':workspaceId/members/:userId/role')
  async updateMemberRole(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
    @Param('userId') userId: string,
    @Body() body: { role: 'ADMIN' | 'MEMBER' },
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    return this.workspaces.updateMemberRole(workspaceId, userId, body.role, req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':workspaceId/delete')
  async deleteWorkspace(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Param('workspaceId') workspaceId: string,
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    return this.workspaces.deleteWorkspace(workspaceId, req.user.id);
  }
}
