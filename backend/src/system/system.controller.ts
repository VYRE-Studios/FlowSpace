import { Controller, Get, Param, Query, Req, UseGuards } from '@nestjs/common';
import type { Request } from 'express';
import { TaskService } from './task.service';
import { AuditService } from './audit.service';
import { KratosSessionGuard } from '../auth/kratos-session.guard';

@Controller('system')
export class SystemController {
  constructor(
    private readonly taskService: TaskService,
    private readonly auditService: AuditService,
  ) {}

  @Get('metrics')
  getMetrics() {
    return this.taskService.logMetric();
  }

  @UseGuards(KratosSessionGuard)
  @Get('activity/workspace/:workspaceId')
  async getWorkspaceActivity(
    @Param('workspaceId') workspaceId: string,
    @Query('limit') limit?: string,
  ) {
    const take = limit ? Math.min(parseInt(limit, 10), 100) : 50;
    return this.auditService.getWorkspaceActivity(workspaceId, take);
  }

  @UseGuards(KratosSessionGuard)
  @Get('activity/user')
  async getUserActivity(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Query('limit') limit?: string,
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }
    const take = limit ? Math.min(parseInt(limit, 10), 100) : 50;
    return this.auditService.getUserActivity(req.user.id, take);
  }
}
