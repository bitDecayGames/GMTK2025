# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

**Development:**
- `make dev` - Standard build (`lime run html5`) - USER RUNS THIS, NOT CLAUDE
- `make dev-test` - Build with direct-to-play mode (`lime test html5 -D play -D drawTerrain`) - USER RUNS THIS, NOT CLAUDE  
- `make debug` - Debug build with direct-to-play (`lime test html5 -D play -debug`) - USER RUNS THIS, NOT CLAUDE

**Project Setup:**
- `make setup` - Initialize dependencies and git hooks (`./bin/init_deps.sh` + `./bin/setup_hooks.sh`)
- `make format` - Format code using haxe-formatter (`./bin/format.sh`)
- `make clean` - Clean build artifacts

**Direct Commands:**
- `./bin/init_deps.sh` - Install/update all dependencies from `haxelib.deps`
- `./bin/format.sh` - Format all Haxe code (runs on pre-commit)
- `./bin/view_metrics.sh` - Launch local Grafana dashboard at localhost:3000

## Architecture Overview

### Core Game Architecture
This is a **HaxeFlixel pinball game** with systems:

**Physics Systems:**
- **Nape Physics**: Primary physics engine for ball, flippers, and collision detection
- **Echo Physics**: Listed in dependencies but currently unused (arcade physics alternative)
- High-precision simulation (100 velocity/position iterations)

**Entity Hierarchy:**
- `Player.hx` = The pinball ball (confusing naming - not player-controlled)
- `Flipper.hx` = Player-controlled flippers with complex joint system (PivotJoint + AngleJoint + 2 DistanceJoints)
- `entities/interact/` = Pinball table elements (slingshots, poppers, targets, tunnels)
- All entities inherit from `SelfAssigningFlxNapeSprite` for automatic physics body association

### Level System Architecture
- **LDTK Integration**: Professional level editor workflow via `levels/ldtk/Level.hx`
- **Multi-layer Rendering**: backgrounds → midground → terrain → player → flippers → foreground
- **Dynamic Camera**: Camera bounds and transitions defined per level zone
- **Entity Placement**: Levels define spawn points, flipper configurations, and interactive elements

### Audio Architecture
- **FMOD Integration**: Professional game audio via `audio/FmodPlugin.hx`
- **Auto-generated Enums**: `FmodEventEnum.hx` provides compile-time constants
- **Per-level Music**: Automatic music loading from level data
- Conditional compilation with `#if !nosound` for silent builds

### Analytics & Events
- **Event-Driven System**: `events/EventBus.hx` with type-safe event subscription
- **Analytics Pipeline**: `helpers/Analytics.hx` → Bitlytics → Grafana dashboards
- **Achievement System**: `achievements/Achievements.hx` with persistent storage
- **Event Derivers**: Transform raw input into meaningful game events

## Key Development Patterns

### Pinball Element Implementation
All interactive table elements follow this pattern:
1. Extend `Interactable` base class
2. Create Nape physics body with appropriate materials/filters
3. Override `handleInteraction()` for collision response
4. Use `AsepriteMacros` for animation loading
5. Add particle emitters for visual feedback

### Physics Collision Groups
- `CGroups.BALL` - The pinball
- `CGroups.CONTROL_SURFACE` - Flippers
- `CGroups.INTERACTABLE` - Bumpers, targets, slingshots
- `CGroups.TERRAIN` - Static level geometry
- `CGroups.SENSOR` - Trigger zones

### Conditional Compilation Flags
- `#if play` - Skip splash screen, go directly to PlayState
- `#if debug` - Enable debug features and visual aids
- `#if drawTerrain` - Show terrain collision shapes
- `#if logan` - Developer-specific level loading

## Asset Pipeline

**Aseprite Integration:**
- Source files in `art/` directory
- Exported atlases in `assets/aseprite/`
- Pre-commit hook auto-exports .ase/.aseprite files
- Use `AsepriteMacros.tagNames()` and `AsepriteMacros.layerNames()` for animation loading

**FMOD Audio:**
- FMOD project files in `fmod/` directory
- Exports to `assets/fmod/` for game consumption
- Auto-generates `FmodEventEnum.hx` with available audio events

## Dependencies Management

The project uses local dependency management via `haxelib.deps`:
- Standard haxelib format: `<libName> <version>`
- Git dependencies: `<libName> git <repo> <commit-ish>`
- Custom BitDecay libraries use specific branches (often `gmtk2025`)
- Must run `./bin/init_deps.sh` after dependency changes

## Game Controls
- **Z** - Left flipper
- **M** - Right flipper
- **P/ESC** - Pause/unpause (freezes physics via `FlxG.timeScale = 0`)
- **R** - Restart current level
- **Arrow Keys** - Direct ball movement (debug)
