/// Project template folder structures
/// Each template defines the folders and files to create for different project types

class ProjectTemplateStructure {
  final String templateId;
  final List<String> folders;
  final Map<String, String> files; // filename -> content

  ProjectTemplateStructure({
    required this.templateId,
    required this.folders,
    required this.files,
  });

  static ProjectTemplateStructure getStructure(String templateId, String projectName, String? description) {
    switch (templateId) {
      case 'brainstorming-whiteboard':
        return _brainstormingStructure(projectName, description);
      case 'workflow-automation':
        return _workflowAutomationStructure(projectName, description);
      case 'game-engine-ai':
        return _gameEngineStructure(projectName, description);
      case 'story-building-software':
        return _storyBuildingStructure(projectName, description);
      case 'blank':
      default:
        return _blankStructure(projectName, description);
    }
  }

  static ProjectTemplateStructure _brainstormingStructure(String projectName, String? description) {
    return ProjectTemplateStructure(
      templateId: 'brainstorming-whiteboard',
      folders: [
        'ideas',
        'mind-maps',
        'notes',
        'assets',
        'references',
        'experiments',
        'archive',
        'prompts',
        'pitch-drafts',
      ],
      files: {
        'README.md': '''
# $projectName

${description ?? 'Creative brainstorming and ideation project'}

## 🧠 Brainstorming Structure

### Folders
- **ideas/** - Raw ideas and concepts
- **mind-maps/** - Visual mind maps and diagrams  
- **notes/** - Session notes and summaries
- **assets/** - Images, inspiration, and media
- **references/** - Research and reference materials

### Getting Started
1. Start with capturing raw ideas in the `ideas/` folder
2. Create mind maps to visualize connections
3. Take session notes as you brainstorm
4. Collect inspiration in `assets/`

Created: ${DateTime.now().toString()}
''',
        'idea-pipeline.md': '''
# Idea Pipeline

## 🌱 Seeds (Raw Ideas)
- 

## 🔬 Exploring (Being Tested)
- 

## 🎯 Validated (Ready to Build)
- 

## ❌ Archived (Not Pursuing)
- 
''',
        'inspiration-board.md': '''
# Inspiration Board

## Visual References
- 

## Concepts That Resonate
- 

## Quotes & Insights
- 
''',
        'ideas/initial-ideas.md': '''
# Initial Ideas

## Problem Space
- Define the problem you're solving

## Initial Concepts
- Idea 1
- Idea 2
- Idea 3

## Next Steps
- [ ] Explore each concept
- [ ] Create mind map
- [ ] Prioritize ideas
''',
        'notes/session-notes.md': '''
# Brainstorming Session Notes

## Session 1 - ${DateTime.now().toString().split(' ')[0]}

### Participants
- 

### Key Insights
- 

### Action Items
- [ ] 
''',
      },
    );
  }

  static ProjectTemplateStructure _workflowAutomationStructure(String projectName, String? description) {
    return ProjectTemplateStructure(
      templateId: 'workflow-automation',
      folders: [
        'src',
        'nodes',
        'workflows',
        'docs',
        'tests',
        'assets',
        'examples',
        'scripts',
        'extensions',
        'cli',
        'deployment',
      ],
      files: {
        'README.md': '''
# $projectName

${description ?? 'Workflow automation system like n8n'}

## ⚙️ Development Structure

### Folders
- **src/** - Source code
- **nodes/** - Custom workflow nodes
- **workflows/** - Example workflows
- **docs/** - Documentation
- **tests/** - Test files
- **assets/** - UI assets and icons

### Tech Stack
- Node system architecture
- Visual workflow editor
- Execution engine

### Getting Started
1. Design node system architecture
2. Build visual editor
3. Implement execution engine
4. Create sample workflows

Created: ${DateTime.now().toString()}
''',
        'docs/architecture.md': '''
# Architecture

## Node System
- Input nodes
- Processing nodes
- Output nodes

## Execution Engine
- Sequential execution
- Parallel execution
- Error handling

## Visual Editor
- Drag-and-drop interface
- Node connections
- Workflow visualization
''',
        'workflows/example.json': '''
{
  "name": "Example Workflow",
  "nodes": [],
  "connections": []
}
''',
        'pipeline-guide.md': '''
# Pipeline Philosophy

## Design Principles
- Composability over monoliths
- Clear data flow
- Error handling at every step
- Observable state

## Node Types
- **Input** - Data sources
- **Transform** - Data manipulation
- **Output** - Data destinations
- **Control** - Flow control (if/loop/switch)
''',
        'extension-spec.md': '''
# Extension Specification

## Extension Structure
```
extensions/
  my-extension/
    manifest.json
    nodes/
    assets/
    README.md
```

## Manifest Format
```json
{
  "name": "extension-name",
  "version": "1.0.0",
  "nodes": []
}
```
''',
        'CHANGELOG.md': '''
# Changelog

## [Unreleased]
### Added
- Initial project structure

### Changed

### Fixed

''',
      },
    );
  }

  static ProjectTemplateStructure _gameEngineStructure(String projectName, String? description) {
    return ProjectTemplateStructure(
      templateId: 'game-engine-ai',
      folders: [
        'source',
        'content',
        'plugins',
        'ai-modules',
        'blueprints',
        'docs',
        'builds',
        'cinematics',
        'tests',
        'tools',
        'ai-behaviors',
        'proofs',
        'performance',
      ],
      files: {
        'README.md': '''
# $projectName

${description ?? 'Unreal Engine fork with AI integration'}

## 🎮 Game Engine Structure

### Folders
- **source/** - Engine source code
- **content/** - Game content and assets
- **plugins/** - Engine plugins
- **ai-modules/** - AI integration modules
- **blueprints/** - Blueprint nodes and systems
- **docs/** - Technical documentation
- **builds/** - Engine builds

### Key Features
- AI-powered game development
- Custom AI nodes for Blueprints
- Integrated ML training
- Procedural content generation

### Getting Started
1. Fork Unreal Engine source
2. Set up AI integration layer
3. Create custom Blueprint nodes
4. Build and test

Created: ${DateTime.now().toString()}
''',
        'docs/ai-integration.md': '''
# AI Integration Guide

## AI Nodes
- Behavior prediction
- Dialogue generation
- Level generation
- Asset generation

## Blueprint Integration
- Custom AI Blueprint nodes
- ML model integration
- Training interface

## Examples
- See blueprints/ folder for examples
''',
        'docs/module-map.md': '''
# Module Map

## Core Systems
- Rendering
- Physics
- AI
- Networking

## Custom Modules
- 

## Third-Party
- 
''',
        'docs/build-instructions.md': '''
# Build Instructions

## Prerequisites
- Visual Studio 2022
- Windows SDK
- .NET Core Runtime

## Build Steps
1. Generate project files
2. Open solution
3. Build (Development Editor)

## First Build
Expect 1-2 hours for initial compilation.
''',
        'CHANGELOG.md': '''
# Changelog

## [Unreleased]
### Added
- Initial engine fork structure
- AI module foundation

### Changed

### Fixed

''',
        'proofs/README.md': '''
# Proof Chain Integration

This folder will contain MKPE/WKPE proof logs for engine builds and tests.

## Future Integration
- Build proofs
- Test execution proofs
- Performance benchmarks
''',
      },
    );
  }

  static ProjectTemplateStructure _storyBuildingStructure(String projectName, String? description) {
    return ProjectTemplateStructure(
      templateId: 'story-building-software',
      folders: [
        'characters',
        'plot',
        'scenes',
        'worldbuilding',
        'drafts',
        'notes',
        'research',
        'timeline',
        'codex',
        'revisions',
        'voice',
        'ui-mockups',
        'cinematic-blocking',
        'asset-board',
      ],
      files: {
        'README.md': '''
# $projectName

${description ?? 'Creative writing and story development tool'}

## 📖 Story Structure

### Folders
- **characters/** - Character profiles and development
- **plot/** - Plot outlines and story arcs
- **scenes/** - Individual scene drafts
- **worldbuilding/** - World details and lore
- **drafts/** - Full manuscript drafts
- **notes/** - Writing notes and ideas
- **research/** - Research materials

### Writing Process
1. Develop characters
2. Outline plot
3. Build world
4. Write scenes
5. Assemble draft

Created: ${DateTime.now().toString()}
''',
        'characters/character-template.md': '''
# Character Template

## Basic Info
- Name:
- Age:
- Role:

## Appearance
-

## Personality
-

## Background
-

## Goals & Motivations
-

## Character Arc
-
''',
        'plot/story-outline.md': '''
# Story Outline

## Act 1 - Setup
-

## Act 2 - Confrontation
-

## Act 3 - Resolution
-

## Key Plot Points
-
''',
        'worldbuilding/world-notes.md': '''
# World Building Notes

## Setting
-

## History
-

## Culture
-

## Magic/Technology System
-

## Important Locations
-
''',
        'timeline/story-timeline.md': '''
# Story Timeline

## Act 1
- 

## Act 2
- 

## Act 3
- 
''',
        'codex/lore-index.md': '''
# Lore Index

## Key Terms
- 

## Historical Events
- 

## Factions
- 
''',
        'voice/tone-guide.md': '''
# Tone & Voice Guide

## Narrative Voice
- 

## Dialogue Style
- 

## Pacing
- 
''',
        'CHANGELOG.md': '''
# Story Changelog

## [Unreleased]
### Added
- Initial story structure

### Changed

### Fixed

''',
      },
    );
  }

  static ProjectTemplateStructure _blankStructure(String projectName, String? description) {
    return ProjectTemplateStructure(
      templateId: 'blank',
      folders: [
        'docs',
        'assets',
        'files',
        'scripts',
        'notes',
        'future',
      ],
      files: {
        'README.md': '''
# $projectName

${description ?? 'Project description'}

## 📋 What is this?


## 🎯 Why does it exist?


## 🚀 How to use


## 📁 Folders
- **docs/** - Documentation
- **assets/** - Media files
- **files/** - Project files
- **scripts/** - Automation scripts
- **notes/** - Project notes
- **future/** - Long-term ideas

## ✨ First Steps
- [ ] Define project goals
- [ ] Set up initial structure
- [ ] Document key decisions

Created: ${DateTime.now().toString()}
''',
        'project-manifest.md': '''
# Project Manifest

## Metadata
- **Author**: 
- **Version**: 0.1.0
- **Project Type**: General
- **Status**: Planning

## Goals
- 

## Success Metrics
- 

## Roadmap
### Phase 1
- 

### Phase 2
- 

### Phase 3
- 
''',
        'CHANGELOG.md': '''
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
### Added
- Initial project setup

### Changed

### Fixed

''',
        'future/ideas.md': '''
# Future Ideas

Place long-term ideas here that don't fit the current scope.

## Someday/Maybe
- 
''',
      },
    );
  }
}
