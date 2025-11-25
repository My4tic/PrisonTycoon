# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Prison Tycoon is a mobile management simulation game built with Godot 4 where players build and manage a prison. Inspired by Prison Architect, featuring prisoner AI, staff management, economy systems, and crisis events.

**Tech Stack:**
- Engine: Godot 4.x (2D, mobile export)
- Language: GDScript
- Target: Mobile (Android/iOS) with touch controls

## Project Structure

```
assets/
  sprites/
    buildings/    # Building sprites
    characters/   # Prisoner and staff sprites
    objects/      # Furniture and equipment
    ui/           # UI elements
  tilesets/       # TileMap resources
  audio/
    music/        # Background music (OGG)
    sfx/          # Sound effects (OGG)
  ui/             # UI graphics
scenes/
  buildings/      # Building scene files (.tscn)
  entities/       # Prisoner and staff scenes
  ui/             # UI panel scenes
  levels/         # Campaign/scenario levels
  main.tscn       # Main game scene
scripts/
  autoload/       # Singleton managers
    constants.gd      # Global constants
    enums.gd          # All enumerations
    signals.gd        # Global signal bus
    game_manager.gd   # Game state, time, speed
    economy_manager.gd # Capital, revenue, expenses
    building_manager.gd # Building placement
    schedule_manager.gd # Prisoner schedules
    event_manager.gd    # Crises and alerts
    save_manager.gd     # Save/load system
  entities/       # Prisoner and staff scripts
  buildings/      # Building-specific scripts
  systems/        # Game systems
  ui/             # UI scripts
  main.gd         # Main scene controller
data/
  buildings.json  # Building definitions (data-driven)
```

## Core Architecture

### Singleton Managers (Autoload)
- **GameManager**: Game state, time system (day/hour), speed controls, save/load
- **EconomyManager**: Capital tracking, revenue/expenses, daily balance
- **BuildingManager**: Building catalog, placement validation, construction
- **ScheduleManager**: Prisoner schedules by security category, lockdown mode
- **EventManager**: Crisis detection, alert system, event queue

### Key Systems
- **Grid-based building**: TileMap with 64px tiles, world ↔ grid coordinate conversion via `GameManager.world_to_grid()` / `grid_to_world()`
- **Prisoner AI**: State machine (Idle, Walking, Working, Eating, Sleeping, Fighting, Escaping)
- **Needs system**: 6 needs (hunger, sleep, hygiene, freedom, safety, entertainment) degrading over time
- **Navigation**: NavigationRegion2D with A* pathfinding, dynamic updates on construction
- **Time system**: 1 real second = 1 game minute at x1 speed; speeds: pause/x1/x2/x4

### Collision Layers (2D Physics)
1. terrain, 2. walls, 3. buildings, 4. objects, 5. prisoners, 6. staff, 7. doors, 8. detection_zones

### Render Layers
1. terrain, 2. walls, 3. buildings, 4. objects, 5. characters, 6. effects, 7. ui_world

### Security Categories
- Low (blue): $500/day subsidy, 10% risk
- Medium (orange): $800/day, 30% risk
- High (red): $1000/day, 60% risk
- Maximum (black): $1200/day, 90% risk

## Development Commands

```bash
# Run the project (from Godot editor or command line)
godot --path . --editor    # Open in editor
godot --path .             # Run game

# Export (configure export presets first)
godot --headless --export-release "Android" build/prison-tycoon.apk
godot --headless --export-release "iOS" build/prison-tycoon.ipa
```

## Design Conventions

- All positions use grid coordinates (convert with helper functions)
- Building data loaded from JSON for easy content addition
- Signals for inter-system communication (fight_started, schedule_changed, etc.)
- Mobile-first: minimum 44x44dp touch targets, gesture support (drag/pinch/tap)

## Key Design Documents

- **README.md**: Complete Game Design Document with all mechanics
- **TODO.md**: Phased implementation plan with MVP definition
