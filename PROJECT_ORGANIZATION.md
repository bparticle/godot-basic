# Pimpa-Raka Project Organization Guide

This document defines the organizational structure and best practices for the Pimpa-Raka Godot 4 project. **This document MUST be maintained and referenced for all future Cursor jobs.**

## 📁 Folder Structure

### Root Level
```
pimpa-raka/
├── assets/                    # Original assets (keep as-is)
├── export/                   # Build outputs (auto-generated)
├── resources/                # Godot resources and data files
├── scenes/                   # All scene files (.tscn)
├── scripts/                  # All script files (.gd)
├── project.godot            # Project configuration
└── PROJECT_ORGANIZATION.md  # This file
```

### Scripts Organization (`scripts/`)
```
scripts/
├── player/           # Player-related scripts
│   ├── Player.gd
│   ├── PlayerStateMachine.gd
│   ├── PlayerClimbState.gd
│   ├── PlayerCrouchState.gd
│   ├── PlayerIdleState.gd
│   ├── PlayerJumpState.gd
│   ├── PlayerWalkState.gd
│   └── PlayerMovementComponent.gd
├── enemies/          # Enemy-related scripts
│   ├── Enemy.gd
│   ├── EnemyAttackState.gd
│   ├── EnemyChaseState.gd
│   ├── EnemyIdleState.gd
│   └── EnemyMovementComponent.gd
├── managers/         # Game management scripts
│   ├── GameStateManager.gd
│   ├── HealthManager.gd
│   └── RoomManager.gd
├── states/           # State machine scripts
│   ├── State.gd
│   ├── StateMachine.gd
│   ├── DoorStateMachine.gd
│   ├── DoorClosedState.gd
│   ├── DoorClosingState.gd
│   ├── DoorOpeningState.gd
│   └── DoorOpenState.gd
├── components/       # Reusable components
│   └── MovementComponent.gd
├── ui/              # User interface scripts
│   └── HeartsUI.gd
├── rooms/           # Room-specific scripts (if any)
├── doors/           # Door-related scripts
│   └── Door.gd
├── collectibles/   # Collectible item scripts
│   ├── Collectible.gd
│   ├── GemLarge.gd
│   └── GemSmall.gd
├── zones/          # Zone/area scripts
│   └── DeathZone.gd
├── Game.gd          # Main game script
├── GameOver.gd      # Game over script
└── SmartCamera.gd   # Camera script
```

### Scenes Organization (`scenes/`)
```
scenes/
├── player/          # Player scenes
│   ├── Player.tscn
│   └── PlayerRefactored.tscn
├── enemies/         # Enemy scenes
│   └── Enemy.tscn
├── rooms/           # Room scenes
│   ├── Room1.tscn
│   ├── Room2.tscn
│   ├── Room3.tscn
│   ├── Room4.tscn
│   └── RoomExample.tscn
├── ui/              # UI scenes
│   ├── HeartsUI.tscn
│   └── GameOver.tscn
├── doors/           # Door scenes
│   └── DoorStateMachine.tscn
├── collectibles/    # Collectible item scenes
│   ├── GemLarge.tscn
│   └── GemSmall.tscn
├── zones/           # Zone scenes (if any)
└── Game.tscn        # Main game scene
```

### Resources Organization (`resources/`)
```
resources/
├── tilesets/        # TileSet resources
│   └── arc_tileset.tres
├── materials/      # Materials and shaders
└── audio/          # Audio files and resources
```

## 🎯 Naming Conventions

### Scripts
- **PascalCase** for class names: `Player.gd`, `Enemy.gd`
- **Descriptive names**: `PlayerMovementComponent.gd`, `DoorStateMachine.gd`
- **State scripts**: `[Entity][State].gd` (e.g., `PlayerIdleState.gd`)

### Scenes
- **PascalCase** for scene names: `Player.tscn`, `Room1.tscn`
- **Descriptive names**: `HeartsUI.tscn`, `DoorStateMachine.tscn`

### Folders
- **lowercase** with underscores: `scripts/player/`, `scenes/enemies/`
- **Descriptive names**: `managers/`, `components/`, `zones/`

## 🔧 @export Variables Best Practices

### Player Script (`scripts/player/Player.gd`)
```gdscript
@export_group("Movement Settings")
@export var speed: float = 60.0
@export var crouch_speed: float = 30.0
@export var climb_speed: float = 40.0
@export var jump_velocity: float = -240.0
@export var acceleration: float = 400.0
@export var friction: float = 400.0

@export_group("Visual Settings")
@export var player_color: Color = Color.WHITE
@export var debug_draw_collision: bool = false
@export var debug_draw_movement: bool = false
```

### Enemy Script (`scripts/enemies/Enemy.gd`)
```gdscript
@export_group("Enemy Stats")
@export var speed: float = 30.0
@export var detection_range: float = 100.0
@export var attack_range: float = 20.0
@export var attack_damage: int = 1
@export var max_health: int = 3
@export var enemy_color: Color = Color.RED

@export_group("AI Behavior")
@export var chase_speed_multiplier: float = 1.5
@export var idle_wait_time: float = 2.0
@export var attack_cooldown: float = 1.0

@export_group("Visual Settings")
@export var debug_draw_ai: bool = false
@export var debug_draw_detection: bool = false
```

### Game Script (`scripts/Game.gd`)
```gdscript
@export_group("Game Settings")
@export var initial_room: String = "room_1"
@export var respawn_delay: float = 1.0
@export var game_over_delay: float = 1.0

@export_group("Visual Settings")
@export var debug_show_room_info: bool = false
@export var debug_show_player_info: bool = false
```

## 📋 File Placement Rules

### Scripts Go In:
- `scripts/player/` - Player-related scripts
- `scripts/enemies/` - Enemy-related scripts  
- `scripts/managers/` - Game management (HealthManager, RoomManager, etc.)
- `scripts/states/` - State machine scripts
- `scripts/components/` - Reusable components
- `scripts/ui/` - UI-related scripts
- `scripts/doors/` - Door-related scripts
- `scripts/zones/` - Zone/area scripts
- `scripts/` - Main game scripts (Game.gd, GameOver.gd, SmartCamera.gd)

### Scenes Go In:
- `scenes/player/` - Player scenes
- `scenes/enemies/` - Enemy scenes
- `scenes/rooms/` - Room scenes
- `scenes/ui/` - UI scenes
- `scenes/doors/` - Door scenes
- `scenes/collectibles/` - Collectible item scenes
- `scenes/zones/` - Zone scenes
- `scenes/` - Main game scene

### Resources Go In:
- `resources/tilesets/` - TileSet resources
- `resources/materials/` - Materials and shaders
- `resources/audio/` - Audio files

## 🔄 Path Updates Required

When moving files, update these references:

### project.godot
```ini
run/main_scene="res://scenes/Game.tscn"
RoomManager="*res://scripts/managers/RoomManager.gd"
HealthManager="*res://scripts/managers/HealthManager.gd"
GameStateManager="*res://scripts/managers/GameStateManager.gd"
```

### Script References
- Update any `res://` paths in scripts to reflect new locations
- Update scene references in scripts
- Update autoload references

## 🎨 Debug Features Added

### Player Debug
- `debug_draw_collision` - Shows collision shapes
- `debug_draw_movement` - Shows velocity vectors and movement direction
- `player_color` - Configurable player color

### Enemy Debug
- `debug_draw_ai` - Shows AI behavior (line to target)
- `debug_draw_detection` - Shows detection and attack ranges
- `enemy_color` - Configurable enemy color

### Game Debug
- `debug_show_room_info` - Shows current room information
- `debug_show_player_info` - Shows player health information

## 📝 Maintenance Rules

1. **Always reference this document** when organizing files
2. **Update paths** when moving files
3. **Maintain folder structure** as defined above
4. **Use descriptive names** for new files
5. **Group related files** in appropriate folders
6. **Add @export variables** for configurable values
7. **Include debug options** for new features

## 🚀 Future Additions

When adding new features:

1. **Determine the category** (player, enemy, manager, etc.)
2. **Place in appropriate folder** following the structure above
3. **Add @export variables** for configuration
4. **Include debug options** for testing
5. **Update this document** if new categories are needed

## ⚠️ Important Notes

- **DO NOT** put scripts in the root directory
- **DO NOT** put scenes in the root directory (except main game scene)
- **ALWAYS** update project.godot when moving autoload scripts
- **ALWAYS** update scene references when moving scenes
- **MAINTAIN** this document for all future changes

---

**This document is the single source of truth for project organization. All future Cursor jobs must follow these guidelines.**
