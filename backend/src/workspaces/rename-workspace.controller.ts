import { Controller, Post, Body } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Controller('admin')
export class AdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Post('rename-workspace')
  async renameWorkspace(@Body() body: { workspaceId: string; name: string; description?: string }) {
    const workspace = await this.prisma.workspace.update({
      where: { id: body.workspaceId },
      data: {
        name: body.name,
        description: body.description || undefined,
      },
    });

    return {
      success: true,
      workspace: {
        id: workspace.id,
        name: workspace.name,
        slug: workspace.slug,
        description: workspace.description,
      },
    };
  }
}
