import { Controller, Get } from '@nestjs/common';

@Controller('api/v1/workspaces')
export class WorkspacesController {
  @Get()
  findAll() {
    const now = new Date().toISOString();

    return {
      workspaces: [
        { id: 'w1', name: 'Development', members: 5, updatedAt: now },
        { id: 'w2', name: 'Design Ops', members: 8, updatedAt: now },
      ],
    };
  }
}

