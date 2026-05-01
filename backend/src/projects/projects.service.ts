import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { TemplateService } from './template.service';

export interface CreateProjectDto {
  name: string;
  templateId: string;
  createdBy: string;
}

@Injectable()
export class ProjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly templateService: TemplateService,
  ) {}

  async getTemplates() {
    return this.templateService.getAllTemplates();
  }

  async getTemplate(templateId: string) {
    return this.templateService.getTemplate(templateId);
  }

  async createProject(dto: CreateProjectDto) {
    // 1. Validate template
    const template = this.templateService.getTemplate(dto.templateId);

    // 2. Create workspace
    const workspaceType = this.getWorkspaceTypeFromTemplate(dto.templateId);
    const workspace = await this.prisma.workspace.create({
      data: {
        name: dto.name,
        slug: this.generateSlug(dto.name),
        description: template.description,
        ownerId: dto.createdBy,
      },
    });

    // Add creator as workspace member
    await this.prisma.workspaceMember.create({
      data: {
        workspaceId: workspace.id,
        userId: dto.createdBy,
        role: 'OWNER',
      },
    });

    // 3. Create project
    const project = await this.prisma.project.create({
      data: {
        name: dto.name,
        templateId: dto.templateId,
        workspaceId: workspace.id,
        createdBy: dto.createdBy,
      },
    });

    // 4. Create default boards
    const boards = await Promise.all(
      template.defaultBoards.map((boardName, index) =>
        this.prisma.projectBoard.create({
          data: {
            projectId: project.id,
            name: boardName,
            type: 'kanban',
            order: index,
          },
        }),
      ),
    );

    // 5. Create project manifest
    const manifest = await this.createProjectManifest(project, workspace, boards, template);

    // 6. Return full project structure
    return {
      projectId: project.id,
      workspaceId: workspace.id,
      workspace: {
        id: workspace.id,
        name: workspace.name,
        slug: workspace.slug,
        workspace_type: workspaceType,
      },
      template: {
        ...template,
      },
      boards,
      tools: template.tools,
      backgroundModule: template.backgroundModule,
      manifest,
    };
  }

  async getProjectsByWorkspace(workspaceId: string) {
    return this.prisma.project.findMany({
      where: { workspaceId },
      include: {
        boards: true,
      },
    });
  }

  async getProjectById(projectId: string) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      include: {
        boards: true,
      },
    });

    if (!project) {
      return null;
    }

    const template = this.templateService.getTemplate(project.templateId);

    return {
      ...project,
      template,
      tools: template.tools,
      backgroundModule: template.backgroundModule,
    };
  }

  private generateSlug(name: string): string {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '') +
      '-' +
      Date.now().toString(36);
  }

  private getWorkspaceTypeFromTemplate(templateId: string): string {
    const typeMap: Record<string, string> = {
      whiteboard: 'whiteboard',
      story: 'document',
      workflow: 'project',
      game: 'project',
      'brainstorm-lite': 'whiteboard',
      blank: 'project',
    };
    return typeMap[templateId] || 'project';
  }

  async createProjectManifest(project: any, workspace: any, boards: any[], template: any) {
    const manifestData = {
      projectId: project.id,
      workspaceId: workspace.id,
      templateId: project.templateId,
      name: project.name,
      lastOpened: new Date().toISOString(),
      createdAt: project.createdAt.toISOString(),
      boards: boards.map(b => ({
        id: b.id,
        name: b.name,
        type: b.type,
        order: b.order,
      })),
      localPath: `VyreVault/Projects/${project.id}/`,
      manifestVersion: '1.0.0',
    };

    await this.prisma.projectManifest.create({
      data: {
        projectId: project.id,
        manifestJson: JSON.stringify(manifestData),
      },
    });

    return manifestData;
  }

  async getProjectManifest(projectId: string) {
    const manifestRecord = await this.prisma.projectManifest.findUnique({
      where: { projectId },
    });

    if (!manifestRecord) {
      throw new NotFoundException(`Manifest for project '${projectId}' not found`);
    }

    return JSON.parse(manifestRecord.manifestJson);
  }

  async updateProjectManifest(projectId: string, manifestData: any) {
    const existing = await this.prisma.projectManifest.findUnique({
      where: { projectId },
    });

    if (!existing) {
      // Create new manifest if it doesn't exist
      await this.prisma.projectManifest.create({
        data: {
          projectId,
          manifestJson: JSON.stringify(manifestData),
        },
      });
    } else {
      // Update existing manifest
      await this.prisma.projectManifest.update({
        where: { projectId },
        data: {
          manifestJson: JSON.stringify(manifestData),
        },
      });
    }

    return manifestData;
  }

  async reconcileProject(projectId: string, localManifest: any) {
    const serverManifest = await this.getProjectManifest(projectId);
    
    // Server wins for metadata, local wins for lastOpened
    const merged = {
      ...serverManifest,
      lastOpened: localManifest.lastOpened || serverManifest.lastOpened,
    };

    // Update server with merged data
    await this.updateProjectManifest(projectId, merged);

    return merged;
  }
}

