// Project Templates - Predefined project structures
export interface ProjectTemplate {
  id: string;
  name: string;
  description: string;
  icon: string;
  category: string;
  defaultTasks: Array<{
    title: string;
    description?: string;
    status: 'backlog' | 'todo' | 'in_progress' | 'done';
    priority: 'low' | 'medium' | 'high';
  }>;
  defaultChannels?: string[];
  metadata?: Record<string, any>;
}

export const PROJECT_TEMPLATES: ProjectTemplate[] = [
  {
    id: 'brainstorming-whiteboard',
    name: 'Brainstorming Whiteboard',
    description: 'Creative brainstorming and ideation project with visual collaboration',
    icon: '🧠',
    category: 'Creative',
    defaultTasks: [
      { title: 'Define Problem Space', description: 'Identify the core problem or opportunity to explore', status: 'todo', priority: 'high' },
      { title: 'Initial Brainstorming Session', description: 'Generate initial ideas and concepts', status: 'todo', priority: 'high' },
      { title: 'Organize Ideas', description: 'Group and categorize brainstormed concepts', status: 'backlog', priority: 'medium' },
      { title: 'Refine Concepts', description: 'Develop and refine promising ideas', status: 'backlog', priority: 'medium' },
      { title: 'Create Visual Maps', description: 'Build mind maps, flowcharts, and visual representations', status: 'backlog', priority: 'low' },
      { title: 'Prioritize & Plan', description: 'Select best ideas and create action plans', status: 'backlog', priority: 'high' },
    ],
    defaultChannels: ['ideas', 'visuals', 'refinement', 'planning'],
    metadata: {
      useCase: 'Idea generation, concept development, visual thinking',
      sessionTemplate: 'Use BRAINSTORM_SESSION_TEMPLATE.md for structured sessions',
    },
  },
  {
    id: 'vyrevault-identity-discovery',
    name: 'VyreVault Studios Identity Discovery',
    description: 'Structured brainstorming to translate 7-9 months of building into brand identity and website design',
    icon: '🎯',
    category: 'Creative',
    defaultTasks: [
      { title: 'Phase 1: Technical Inventory (30 min)', description: 'Document what FlowSpace, a9n, VyreVault 6, and CreativeOS actually are - features, unique characteristics, what they enable', status: 'todo', priority: 'high' },
      { title: 'Phase 2: Pattern Discovery (30 min)', description: 'Find the invisible thread - Visual-First, AI Partnership, Local+Cloud Hybrid, Creative Workflows, Unified Environment', status: 'todo', priority: 'high' },
      { title: 'Phase 3: Identity Discovery (45 min)', description: 'Answer: What\'s the vision no one else can see? What makes it beautiful? What makes it essential?', status: 'todo', priority: 'high' },
      { title: 'Phase 4: Brand Synthesis (30 min)', description: 'Create core identity statement, unique value proposition, and vision statement', status: 'backlog', priority: 'high' },
      { title: 'Phase 5: Website Design (45 min)', description: 'Translate identity into design principles, website structure, and content strategy', status: 'backlog', priority: 'high' },
      { title: 'Document Final Identity', description: 'Capture the core identity, value proposition, and vision in final form', status: 'backlog', priority: 'high' },
      { title: 'Create Website Wireframe', description: 'Design website structure based on identity discovery', status: 'backlog', priority: 'medium' },
      { title: 'Write Website Content', description: 'Create all website copy based on identity and design principles', status: 'backlog', priority: 'medium' },
    ],
    defaultChannels: ['technical-inventory', 'pattern-discovery', 'identity-discovery', 'website-design'],
    metadata: {
      useCase: 'Brand identity discovery, website design, translating technical work into creative vision',
      sessionRules: 'No generic answers. Start from what\'s built. Find patterns, not features. Think like Steve Jobs.',
      referenceDocs: ['VYREVAULT_IDENTITY_BRAINSTORM.md', 'BRAINSTORM_SESSION_TEMPLATE.md'],
      duration: '3 hours',
    },
  },
  {
    id: 'workflow-automation',
    name: 'Workflow Automation',
    description: 'Build workflow automation tools and visual node-based systems (like a9n/n8n)',
    icon: '⚙️',
    category: 'Development',
    defaultTasks: [
      { title: 'Node System Architecture', description: 'Design node-based workflow engine and execution model', status: 'todo', priority: 'high' },
      { title: 'Node Library Development', description: 'Create core node types (HTTP, database, transform, etc.)', status: 'todo', priority: 'high' },
      { title: 'Visual Editor', description: 'Build drag-and-drop workflow editor interface', status: 'backlog', priority: 'high' },
      { title: 'Workflow Execution Engine', description: 'Implement workflow runner and execution queue', status: 'backlog', priority: 'high' },
      { title: 'Trigger System', description: 'Build webhooks, schedules, and event triggers', status: 'backlog', priority: 'medium' },
      { title: 'Data Flow & Validation', description: 'Implement data passing between nodes and validation', status: 'backlog', priority: 'medium' },
      { title: 'Error Handling & Logging', description: 'Add error recovery, retries, and comprehensive logging', status: 'backlog', priority: 'medium' },
      { title: 'Testing & Performance', description: 'Test workflows and optimize execution performance', status: 'backlog', priority: 'low' },
    ],
    defaultChannels: ['core-engine', 'nodes', 'editor', 'execution', 'testing'],
  },
  {
    id: 'game-engine-ai',
    name: 'Game Engine with AI',
    description: 'Unreal Engine fork with AI integration (like VyreVault 6)',
    icon: '🎮',
    category: 'Development',
    defaultTasks: [
      { title: 'Engine Fork Setup', description: 'Fork Unreal Engine and set up development environment', status: 'todo', priority: 'high' },
      { title: 'AI Integration Architecture', description: 'Design AI system architecture and plugin structure', status: 'todo', priority: 'high' },
      { title: 'AI Model Integration', description: 'Integrate AI models (LLM, image generation, etc.) into engine', status: 'backlog', priority: 'high' },
      { title: 'Blueprint AI Nodes', description: 'Create Blueprint nodes for AI functionality', status: 'backlog', priority: 'high' },
      { title: 'AI Asset Generation', description: 'Build tools for AI-generated assets (textures, models, etc.)', status: 'backlog', priority: 'medium' },
      { title: 'AI-Assisted Workflows', description: 'Implement AI helpers for level design, scripting, etc.', status: 'backlog', priority: 'medium' },
      { title: 'Performance Optimization', description: 'Optimize AI calls and engine performance', status: 'backlog', priority: 'medium' },
      { title: 'Documentation & Examples', description: 'Create docs and example projects', status: 'backlog', priority: 'low' },
    ],
    defaultChannels: ['core-engine', 'ai-integration', 'blueprints', 'assets', 'optimization'],
  },
  {
    id: 'story-building-software',
    name: 'Story Building Software',
    description: 'Creative writing and story development tool (like CreativeOS)',
    icon: '📖',
    category: 'Creative',
    defaultTasks: [
      { title: 'Story Structure System', description: 'Design character, plot, world-building data models', status: 'todo', priority: 'high' },
      { title: 'Character Management', description: 'Build character profiles, relationships, and arcs', status: 'todo', priority: 'high' },
      { title: 'Plot & Timeline Tools', description: 'Create timeline visualization and plot thread management', status: 'backlog', priority: 'high' },
      { title: 'World Building System', description: 'Build tools for locations, lore, and world consistency', status: 'backlog', priority: 'medium' },
      { title: 'Writing Interface', description: 'Create rich text editor with story element linking', status: 'backlog', priority: 'high' },
      { title: 'AI Writing Assistant', description: 'Integrate AI for suggestions, continuity checking, etc.', status: 'backlog', priority: 'medium' },
      { title: 'Export & Publishing', description: 'Build export formats and publishing workflows', status: 'backlog', priority: 'low' },
      { title: 'Collaboration Features', description: 'Add multi-user editing and sharing', status: 'backlog', priority: 'low' },
    ],
    defaultChannels: ['characters', 'plot', 'world-building', 'writing', 'ai-assistant'],
  },
  {
    id: 'software-development',
    name: 'Software Development',
    description: 'General software development project with sprints, features, and bug tracking',
    icon: '💻',
    category: 'Development',
    defaultTasks: [
      { title: 'Project Setup', description: 'Initialize repository, set up CI/CD, configure development environment', status: 'todo', priority: 'high' },
      { title: 'Architecture Design', description: 'Design system architecture, database schema, API structure', status: 'todo', priority: 'high' },
      { title: 'Core Features Development', description: 'Implement main features and functionality', status: 'backlog', priority: 'medium' },
      { title: 'Testing & QA', description: 'Write unit tests, integration tests, and perform QA', status: 'backlog', priority: 'medium' },
      { title: 'Documentation', description: 'Write API docs, user guides, and technical documentation', status: 'backlog', priority: 'low' },
      { title: 'Deployment', description: 'Deploy to staging and production environments', status: 'backlog', priority: 'high' },
    ],
    defaultChannels: ['development', 'code-review', 'bugs', 'deployment'],
  },
  {
    id: 'product-launch',
    name: 'Product Launch',
    description: 'Complete product launch from planning to post-launch support',
    icon: '🚀',
    category: 'Product',
    defaultTasks: [
      { title: 'Product Planning', description: 'Define product requirements and roadmap', status: 'todo', priority: 'high' },
      { title: 'Development', description: 'Build and develop the product', status: 'backlog', priority: 'high' },
      { title: 'Beta Testing', description: 'Conduct beta testing and gather feedback', status: 'backlog', priority: 'high' },
      { title: 'Launch Preparation', description: 'Prepare launch materials and documentation', status: 'backlog', priority: 'medium' },
      { title: 'Launch Day', description: 'Execute product launch', status: 'backlog', priority: 'high' },
      { title: 'Post-Launch Support', description: 'Monitor, support, and iterate based on feedback', status: 'backlog', priority: 'medium' },
    ],
    defaultChannels: ['product', 'engineering', 'launch', 'support'],
  },
  {
    id: 'research-project',
    name: 'Research Project',
    description: 'Technical research project with phases and milestones',
    icon: '🔬',
    category: 'Research',
    defaultTasks: [
      { title: 'Research Proposal', description: 'Define research goals, scope, and methodology', status: 'todo', priority: 'high' },
      { title: 'Literature Review', description: 'Review existing research, papers, and implementations', status: 'backlog', priority: 'high' },
      { title: 'Prototype Development', description: 'Build proof-of-concept and prototypes', status: 'backlog', priority: 'high' },
      { title: 'Experimentation', description: 'Run experiments and collect data', status: 'backlog', priority: 'medium' },
      { title: 'Analysis & Documentation', description: 'Analyze results and document findings', status: 'backlog', priority: 'medium' },
      { title: 'Presentation', description: 'Present findings and conclusions', status: 'backlog', priority: 'low' },
    ],
    defaultChannels: ['research', 'prototyping', 'experiments', 'analysis'],
  },
  {
    id: 'blank',
    name: 'Blank Project',
    description: 'Start with an empty project and build your own structure',
    icon: '📋',
    category: 'General',
    defaultTasks: [],
    defaultChannels: [],
  },
];

export function getTemplateById(id: string): ProjectTemplate | undefined {
  return PROJECT_TEMPLATES.find(t => t.id === id);
}

export function getTemplatesByCategory(category: string): ProjectTemplate[] {
  return PROJECT_TEMPLATES.filter(t => t.category === category);
}

export function getAllCategories(): string[] {
  return [...new Set(PROJECT_TEMPLATES.map(t => t.category))];
}

