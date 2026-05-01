import { Injectable, NotFoundException } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

export interface ProjectTemplate {
  id: string;
  name: string;
  description: string;
  backgroundModule: string;
  tools: string[];
  defaultBoards: string[];
  defaultSettings: Record<string, any>;
}

interface TemplateRegistry {
  version: string;
  templates: ProjectTemplate[];
}

@Injectable()
export class TemplateService {
  private registry!: TemplateRegistry;

  constructor() {
    this.loadTemplateRegistry();
  }

  private loadTemplateRegistry(): void {
    const candidates = [
      path.join(process.cwd(), 'config', 'projectTemplates.json'),
      path.join(__dirname, '../../config/projectTemplates.json'),
      path.join(__dirname, '../config/projectTemplates.json'),
    ];

    const registryPath = candidates.find((p) => {
      try { return fs.existsSync(p); } catch { return false; }
    });

    if (!registryPath) {
      throw new Error(`projectTemplates.json not found. Searched: ${candidates.join(', ')}`);
    }

    const registryData = fs.readFileSync(registryPath, 'utf8');
    this.registry = JSON.parse(registryData);
  }

  getTemplate(templateId: string): ProjectTemplate {
    const template = this.registry.templates.find(t => t.id === templateId);
    if (!template) {
      throw new NotFoundException(`Template '${templateId}' not found`);
    }
    return template;
  }

  getAllTemplates(): ProjectTemplate[] {
    return this.registry.templates;
  }

  validateTemplateId(templateId: string): boolean {
    return this.registry.templates.some(t => t.id === templateId);
  }
}
