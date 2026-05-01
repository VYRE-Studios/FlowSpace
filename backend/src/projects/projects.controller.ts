import { Controller, Get, Param, Post, Body, UseGuards, Req } from '@nestjs/common';
import type { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { ProjectsService } from './projects.service';

@Controller('projects')
export class ProjectsController {
  constructor(private readonly projects: ProjectsService) {}

  @Get('templates')
  getTemplates() {
    return this.projects.getTemplates();
  }

  @Get('templates/:templateId')
  getTemplate(@Param('templateId') templateId: string) {
    return this.projects.getTemplate(templateId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('create')
  createProject(
    @Req() req: Request & {
      user?: { id: string; email?: string; displayName?: string | null };
    },
    @Body()
    body: {
      name: string;
      templateId: string;
    },
  ) {
    if (!req.user?.id) {
      throw new Error('User not authenticated');
    }

    return this.projects.createProject({
      name: body.name,
      templateId: body.templateId,
      createdBy: req.user.id,
    });
  }

  @UseGuards(JwtAuthGuard)
  @Get('workspace/:workspaceId')
  getProjectsByWorkspace(@Param('workspaceId') workspaceId: string) {
    return this.projects.getProjectsByWorkspace(workspaceId);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':projectId')
  getProjectById(@Param('projectId') projectId: string) {
    return this.projects.getProjectById(projectId);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':projectId/manifest')
  getProjectManifest(@Param('projectId') projectId: string) {
    return this.projects.getProjectManifest(projectId);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':projectId/manifest')
  updateProjectManifest(
    @Param('projectId') projectId: string,
    @Body() manifestData: any,
  ) {
    return this.projects.updateProjectManifest(projectId, manifestData);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':projectId/reconcile')
  reconcileProject(
    @Param('projectId') projectId: string,
    @Body() body: { localManifest: any },
  ) {
    return this.projects.reconcileProject(projectId, body.localManifest);
  }
}

