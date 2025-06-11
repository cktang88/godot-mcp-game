# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a multi-project repository containing Godot MCP (Model Context Protocol) implementations and game projects:

- **waefrebeorn-Godot-MCP/**: Enhanced fork with additional features (complete scene tree access, AI script generation, asset management)
- **asteroids-game/**: Complete asteroids-style game using MCP addon
- **tower-defense/**: Tower defense game using MCP addon
- **godot-docs/**: Official Godot Engine 4.4.1 documentation - **ALWAYS consult these for best practices, API reference, and proper implementation patterns**

### Godot Projects

- Open `project.godot` files directly in Godot Engine 4.4.1
- All projects have MCP plugin pre-enabled
- Use Godot's built-in run/debug system
- **Reference godot-docs/ for official documentation and best practices**

## Architecture Overview

### MCP Communication Flow

1. **Claude** ↔ **MCP Server** (via Model Context Protocol)
2. **MCP Server** ↔ **Godot Engine** (via WebSocket on port 8080)
3. **Godot** processes commands through addon system
4. **Responses** flow back through the same chain

## Code Style Guidelines

### File Organization in Godot projects

- in Godot projects, group files by FUNCTION, not file type. Related files should be in the same folder.
- use PascalCase for scenes and scripts names, and snake_case for other files and folders.

- Example hierarchy:

```
/
    entities/
        player/
            player.tscn
            player.gd
        enemies/
            generic_enemy.gd
            enemy.tscn #base scene to be overridden
            boss_enemy.gd
            boss.tscn #base scene to be overridden
        actor.tscn
        actor.tres
        actor.gd
    globals/ #used as autoloads
        notifications.tscn
        lobby.tscn
        serialization.tscn
    menus/ #for scenes that are used standalone 2d menus, or popups
        title/
            title.tscn
            font_title.tres
    ui/ #for any assets related to UI that are reused
        theme_default/
            assets/
                [...] #generally pngs for interface
            theme_default.tres
        font_uidefault.tres
        cool_font.ttf
    scenes/ #scenes where a player will probably be instantiated
         common/
             assets/
                 [...]
             prefabs/ #premade designs for inclusion in a level elsewhere
                 [...].tscn
             common_gridmap.tres
         main/
             assets/
                 [...]
             main.tscn
             [...]
         overworld/
             assets/
                 [...]
             overworld.tscn
             [...]
         dungeon/
             assets/
                 [...]
             dungeon.tscn
             [...]
```

### GDScript (Godot)

- **snake_case** for variables/methods/functions
- **PascalCase** for classes
- Type hints encouraged: `var player: Player`
- Signals preferred for node communication
- Follow Godot singleton conventions
- **Consult godot-docs/ for official GDScript best practices and API usage**

## Key Capabilities

### Node Operations

- Create, modify, delete scene nodes
- Update node properties (position, rotation, scale)
- Access complete scene tree hierarchy

### Script Management

- Read/write GDScript files by path
- Analyze and generate script templates
- Create scripts with proper boilerplate

### Scene Operations

- Load, save, manipulate scene structure
- Access current scene or any scene file
- Create new scenes with specified root nodes

### Enhanced Features (waefrebeorn-Godot-MCP)

- **Full Scene Tree**: `get_full_scene_tree` command
- **AI Script Generation**: Generate scripts from natural language
- **Asset Management**: Query assets by type (images, audio, models)
- **Debug Access**: Retrieve editor debug logs
- **Dynamic Script Access**: Read any script by path

## Game Project Specifications

### Asteroids Game

- **Resolution**: 1920x1080, canvas_items stretch
- **Input**: WASD movement, Space/Enter shooting
- **Physics**: 2D with gravity disabled
- **Architecture**: Player, Asteroid, Bullet classes with GameManager

### Tower Defense

- **Resolution**: 2560x1440
- **Input**: Mouse-based (left click place tower, right click cancel)
- **Architecture**: Tower, Enemy, Projectile classes with UIController

## Working with MCP Projects

### When editing Godot scripts:

1. Ensure Godot project is open for real-time updates
2. Use MCP addon commands through Claude for seamless integration
3. Follow scene tree hierarchy shown in project structure

### Testing Changes:

1. Build MCP server: `cd {project}/server && npm run build`
2. Open Godot project
3. Test MCP connection through Claude Desktop
4. Verify WebSocket communication in Godot console

## Common Development Patterns

### Creating Game Objects:

1. Create scene file (.tscn)
2. Add corresponding GDScript (.gd)
3. Use MCP commands for AI-assisted development
4. Follow existing naming conventions

## Important File Patterns

- **MCP Tools**: `server/src/tools/{category}_tools.ts`
- **MCP Resources**: `server/src/resources/{category}_resources.ts`
- **Godot Commands**: `addons/godot_mcp/commands/{category}_commands.gd`
- **Game Scripts**: `scripts/{ClassName}.gd`
- **Game Scenes**: `scenes/{ObjectName}.tscn`
