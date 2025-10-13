# Pimpa-Raka Game Framework Documentation

**CRITICAL: This document must be read before any development work on this project. It contains the complete framework architecture, patterns, and conventions used throughout the codebase.**

## 🎯 Project Overview

**Pimpa-Raka** is a 2D platformer game built in Godot 4.3 with a sophisticated state machine architecture, room-based level system, and comprehensive game management framework.

### Key Features
- **State Machine Architecture**: Clean, maintainable entity behaviors
- **Room-Based Level System**: Dynamic room loading and transitions
- **Player Movement System**: Advanced platformer mechanics with jump buffering and coyote time
- **Health/Life System**: Lives-based health with respawn mechanics
- **Smart Camera System**: Room-aware camera that follows player within boundaries
- **Collectible System**: Modular collectible items (gems, keys)
- **Color Palette System**: Centralized color management for pixel art

---

## 🏗️ Architecture Overview

### Core Systems Hierarchy
```
Game (Node2D)
├── RoomManager (Singleton)
├── HealthManager (Singleton) 
├── GameStateManager (Singleton)
├── RNG (Singleton)
├── SceneChanger (Singleton, CanvasLayer)
├── SmartCamera (Camera2D)
├── HeartsUI (Control)
└── Current Room Instance
    ├── Player (CharacterBody2D)
    │   ├── StateMachine
    │   │   ├── IdleState
    │   │   ├── WalkState
    │   │   ├── JumpState
    │   │   ├── CrouchState
    │   │   └── ClimbState
    │   └── MovementComponent
    ├── TileMapLayer
    ├── PlayerSpawn (Marker2D)
    ├── Doors (Area2D)
    ├── DeathZones (Area2D)
    └── Collectibles
```

---

## 🎮 State Machine System

### Base Architecture
The project uses a sophisticated state machine system following Godot tutorial best practices:

#### Core Components
- **`State.gd`**: Base class for all states with `enter()`, `exit()`, `update()`, `physics_update()`
- **`StateMachine.gd`**: Manages state transitions and lifecycle
- **`MovementComponent.gd`**: Interface for input handling using duck typing

#### State Pattern
```gdscript
class_name PlayerIdleState
extends State

var parent: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

func enter():
    # Setup when entering state
    pass

func exit():
    # Cleanup when exiting state
    pass

func update(delta: float):
    # Called every frame
    pass

func physics_update(delta: float):
    # Called every physics frame
    pass

func check_transitions():
    # Check for state transitions
    if movement_component.wants_to_jump():
        transition_to("jump")
```

### Player State Machine
**States**: Idle, Walk, Jump, Crouch, Climb

**State Transitions**:
```
Idle → Walk (movement input)
Idle → Jump (jump input) 
Idle → Crouch (crouch input)
Idle → Climb (climb input near ladder)

Walk → Idle (no movement)
Walk → Jump (jump input)
Walk → Crouch (crouch input)
Walk → Climb (climb input near ladder)

Jump → Idle (landing, no movement)
Jump → Walk (landing, movement)
Jump → Climb (climb input near ladder)

Crouch → Idle (stand up, no movement)
Crouch → Walk (stand up, movement)
Crouch → Climb (climb input near ladder)

Climb → Idle (no ladder, no movement)
Climb → Walk (no ladder, movement)
Climb → Jump (jump input)
```

### Enemy State Machine
**States**: Idle, Chase, Attack

### Door State Machine
**States**: Closed, Opening, Open, Closing

---

## 🏠 Room Management System

### RoomManager (Singleton)
**Location**: `scripts/managers/RoomManager.gd`

#### Key Features
- **Dynamic Room Loading**: Rooms loaded/unloaded as needed
- **Player Spawning**: Automatic player positioning at spawn points
- **Room Transitions**: Seamless movement between rooms
- **Camera Integration**: Provides camera bounds for SmartCamera
- **Health Integration**: Updates spawn points for respawn system

#### Room Data Structure
```gdscript
class RoomData:
    var id: String
    var scene_path: String
    var width: float
    var height: float
```

#### Registered Rooms
```gdscript
rooms["room_0"] = RoomData.new("room_0", "res://scenes/rooms/Room0.tscn", 600.0, 600.0)
rooms["room_1"] = RoomData.new("room_1", "res://scenes/rooms/Room1.tscn", 600.0, 600.0)
rooms["room_2"] = RoomData.new("room_2", "res://scenes/rooms/Room2.tscn", 600.0, 600.0)
rooms["room_3"] = RoomData.new("room_3", "res://scenes/rooms/Room3.tscn", 600.0, 600.0)
rooms["room_4"] = RoomData.new("room_4", "res://scenes/rooms/Room4.tscn", 600.0, 600.0)
```

#### Key Methods
- `change_room(room_id: String)`: Load new room and spawn player
- `respawn_player()`: Respawn at last spawn point
- `get_camera_position()`: Calculate camera bounds for current room
- `cleanup()`: Clean up references before scene changes

### Room Structure Requirements
Every room scene MUST have:
- **PlayerSpawn (Marker2D)**: Player spawn position
- **TileMapLayer**: Level geometry using arc_tileset.tres
- **Doors (Area2D)**: Room transition triggers with `target_room` export

### Door System
**Location**: `scripts/doors/Door.gd`

```gdscript
@export var target_room: String = ""
@export var activation_delay: float = 0.3
```

**Usage**: Set `target_room` in Inspector to connect rooms.

---

## 🎮 Player System

### Player (CharacterBody2D)
**Location**: `scripts/player/Player.gd`

#### Key Features
- **State Machine Integration**: Uses PlayerStateMachine for movement states
- **Advanced Platformer Mechanics**: Jump buffering, coyote time, input locking
- **Room Integration**: Responds to room changes and health events
- **Animation System**: Sprite flipping, state-based animations

#### Movement Properties
```gdscript
@export var SPEED: float = 200.0
@export var ACCELERATION: float = 1000.0
@export var FRICTION: float = 1000.0
@export var JUMP_VELOCITY: float = -400.0
@export var COYOTE_TIME: float = 0.1
@export var JUMP_BUFFER_TIME: float = 0.1
```

#### State Tracking
- `is_crouching`: Crouch state
- `is_climbing`: Ladder climbing state
- `is_dead`: Death state
- `input_locked_until_ms`: Input lock timing

### MovementComponent
**Location**: `scripts/components/MovementComponent.gd`

Interface for input handling:
```gdscript
func get_movement_direction() -> float
func wants_to_jump() -> bool
func wants_to_crouch() -> bool
func wants_to_climb() -> bool
```

---

## ❤️ Health & Life System

### HealthManager (Singleton)
**Location**: `scripts/managers/HealthManager.gd`

#### Key Features
- **Lives-Based System**: 3 lives maximum
- **Spawn Point Tracking**: Remembers last spawn position and room
- **Death Handling**: Triggers respawn or game over
- **Signal System**: Emits health changes for UI updates

#### Signals
```gdscript
signal health_changed(current_lives: int, max_lives: int)
signal player_died()
signal game_over()
```

#### Key Methods
- `take_damage(amount: int)`: Reduce lives and trigger respawn
- `take_damage_no_respawn(amount: int)`: Damage without respawn (spikes)
- `heal(amount: int)`: Restore lives
- `update_spawn_point(position: Vector2, room_id: String)`: Update spawn data

### HeartsUI
**Location**: `scripts/ui/HeartsUI.gd`

Visual display of player lives using pixelassets.png texture.

---

## 🎥 Camera System

### SmartCamera (Camera2D)
**Location**: `scripts/SmartCamera.gd`

#### Key Features
- **Room-Aware**: Follows player within room boundaries
- **Smooth Following**: Adaptive speed based on distance
- **Room Transitions**: Snaps to spawn position on room change
- **Boundary Clamping**: Uses RoomManager for accurate bounds

#### Integration
- Listens to `RoomManager.room_changed` signal
- Uses `RoomManager.get_camera_position()` for bounds calculation
- Automatically follows player from RoomManager

---

## 🎨 Color Palette System

### GameColors
**Location**: `scripts/GameColors.gd`

Centralized color management with 15 colors from retro-saffron palette:

#### Color Categories
```gdscript
# Dark Colors
const DARK_BROWN = Color("#181010")
const DARK_GRAY = Color("#3A393C")
const DARK_PURPLE = Color("#633566")
const MEDIUM_GRAY = Color("#4B4B4B")

# Purple Tones
const LIGHT_PURPLE = Color("#AE8AB8")
const PURPLE = Color("#84739C")
const DEEP_PURPLE = Color("#614C7E")

# Orange/Peach Tones
const ORANGE = Color("#F29155")
const PEACH = Color("#F7B58C")
const LIGHT_PEACH = Color("#FFD6BD")
const CREAM = Color("#FFF2D7")

# Light Colors
const OFF_WHITE = Color("#FFEFFF")
const LIGHT_GRAY = Color("#EFEFEF")
const WHITE = Color("#FFFFFF")
const GRAY = Color("#A9A9A9")
```

#### Usage
```gdscript
# Direct access
var color = GameColors.ORANGE

# By name
var color = GameColors.get_color_by_name("peach")

# By category
var warm_colors = GameColors.get_warm_tones()
```

---

## 🔁 Global Utilities

### RNG (Singleton)
**Location**: `scripts/managers/RNG.gd`

Centralized random number generation for deterministic builds and consistent seeding.

#### Usage
```gdscript
# Float in [0,1)
var x := RNG.randf()

# Float in range
var t := RNG.randf_range(2.0, 5.0)

# Int in [0, 2^32)
var n := RNG.randi()

# Int in range (inclusive)
var k := RNG.randi_range(1, 6)

# Optional: set fixed seed (e.g., from save data or debug)
RNG.set_seed(123456)
```

#### Policy
- Do NOT use `randf`, `randi`, or `randf_range` directly. Always use `RNG`.
- Use `RNG.set_seed(seed_value)` to make runs reproducible when needed.

---

### SceneChanger (Singleton)
**Location**: `scripts/managers/SceneChanger.gd`

Provides simple fade transitions for scene changes via a global `CanvasLayer`.

#### Usage
```gdscript
# Fade to a new scene
SceneChanger.change_scene_to_file("res://scenes/ui/GameOver.tscn")
```

#### Notes
- Automatically sizes to viewport and listens for resize changes.
- Fade color and duration are exported and can be tweaked in the Inspector.

#### Policy
- Replace direct calls to `get_tree().change_scene_to_file()` with `SceneChanger.change_scene_to_file()` for user-facing transitions.
- For internal/non-visual fast changes (rare), document why `SceneChanger` is intentionally skipped.

---

## 🎁 Collectible System

### Collectible (Base Class)
**Location**: `scripts/collectibles/Collectible.gd`

#### Base Properties
```gdscript
@export var value: int = 1
@export var collectible_type: String = "gem"
```

#### Collection Flow
1. Player enters Area2D
2. `_on_body_entered()` triggered
3. `collect()` method called
4. Item removed from scene

### Collectible Types
- **GemLarge**: Large gems (high value)
- **GemSmall**: Small gems (low value)  
- **Key**: Keys for door unlocking

---

## 🎮 Game State Management

### GameStateManager (Singleton)
**Location**: `scripts/managers/GameStateManager.gd`

#### Game States
```gdscript
enum GameState {
    PLAYING,
    PAUSED,
    GAME_OVER,
    MENU
}
```

#### Key Features
- **Pause System**: ESC key to pause/resume
- **State Tracking**: Current game state management
- **Signal System**: Emits state changes

### Game (Main Scene)
**Location**: `scripts/Game.gd`

#### Key Features
- **Room Initialization**: Sets up initial room
- **Health Integration**: Handles death and game over
- **Manager Coordination**: Connects all systems

#### Configuration
```gdscript
@export var initial_room: String = "room_1"
@export var respawn_delay: float = 1.0
@export var game_over_delay: float = 1.0
```

---

## 🚪 Door & Zone System

### Door System
**Location**: `scripts/doors/Door.gd`

#### Properties
```gdscript
@export var target_room: String = ""
@export var activation_delay: float = 0.3
```

#### Usage
1. Add Door node to room
2. Set `target_room` in Inspector
3. Player enters Area2D → room transition

### DeathZone System
**Location**: `scripts/zones/DeathZone.gd`

#### Properties
```gdscript
@export var damage_amount: int = 1
```

#### Usage
1. Add DeathZone node to room
2. Set collision shape
3. Player enters → damage taken

---

## 📁 Project Structure

### Directory Organization
```
scripts/
├── managers/           # Singleton managers
│   ├── RoomManager.gd
│   ├── HealthManager.gd
│   └── GameStateManager.gd
├── player/             # Player system
│   ├── Player.gd
│   ├── PlayerStateMachine.gd
│   └── Player*State.gd
├── states/             # State machine system
│   ├── State.gd
│   ├── StateMachine.gd
│   └── Door*State.gd
├── components/         # Reusable components
│   └── MovementComponent.gd
├── doors/              # Door system
│   └── Door.gd
├── zones/              # Hazard zones
│   └── DeathZone.gd
├── collectibles/       # Collectible system
│   └── Collectible.gd
├── ui/                 # UI components
│   └── HeartsUI.gd
└── GameColors.gd       # Color palette
```

### Scene Organization
```
scenes/
├── Game.tscn           # Main game scene
├── player/
│   └── Player.tscn
├── rooms/
│   ├── Room0.tscn      # Empty room template
│   ├── Room1.tscn      # Level 1
│   ├── Room2.tscn      # Level 2
│   ├── Room3.tscn      # Level 3
│   └── Room4.tscn      # Level 4
├── collectibles/
│   ├── GemLarge.tscn
│   ├── GemSmall.tscn
│   └── Key.tscn
├── doors/
│   └── DoorStateMachine.tscn
├── enemies/
│   └── Enemy.tscn
└── ui/
    ├── GameOver.tscn
    └── HeartsUI.tscn
```

---

## 🔧 Development Guidelines

### Creating New Rooms

1. **Copy Room0.tscn** as template
2. **Add required nodes**:
   - PlayerSpawn (Marker2D)
   - TileMapLayer with arc_tileset.tres
   - Doors with target_room set
3. **Register in RoomManager**:
   ```gdscript
   rooms["room_X"] = RoomData.new("room_X", "res://scenes/rooms/RoomX.tscn", 600.0, 600.0)
   ```
4. **Set up room transitions** in door nodes

### Creating New States

1. **Extend State class**:
   ```gdscript
   class_name NewState
   extends State
   ```
2. **Implement required methods**:
   - `enter()`, `exit()`, `update()`, `physics_update()`
3. **Add to StateMachine** as child node
4. **Set up transitions** in `check_transitions()`

### Creating New Collectibles

1. **Extend Collectible class**:
   ```gdscript
   class_name NewCollectible
   extends Collectible
   ```
2. **Override collect()** method for custom behavior
3. **Set up scene** with Area2D and collision shape

### Using Color Palette

1. **Access colors directly**:
   ```gdscript
   var color = GameColors.ORANGE
   ```
2. **Use in materials/shaders**:
   ```gdscript
   material.albedo_color = GameColors.PEACH
   ```
3. **Get color by name**:
   ```gdscript
   var color = GameColors.get_color_by_name("purple")
   ```

---

## 🚨 Critical Conventions

### Naming Conventions
- **States**: `EntityState` (e.g., `PlayerIdleState`)
- **Managers**: `EntityManager` (e.g., `RoomManager`)
- **Components**: `EntityComponent` (e.g., `MovementComponent`)
- **Rooms**: `RoomX.tscn` where X is room number
- **Scenes**: PascalCase (e.g., `Player.tscn`)

### File Organization
- **Scripts**: Organized by system/functionality
- **Scenes**: Organized by entity type
- **Resources**: Centralized in `resources/` folder

### Signal Usage
- **State transitions**: `transition_requested` signal
- **Health changes**: `health_changed` signal
- **Room changes**: `room_changed` signal
- **Game state**: `game_state_changed` signal

### Singleton Access
- **RoomManager**: `get_node("/root/RoomManager")`
- **HealthManager**: `get_node("/root/HealthManager")`
- **GameStateManager**: `get_node("/root/GameStateManager")`

---

## 🎯 Quick Reference

### Adding a New Room
1. Copy `Room0.tscn` → `RoomX.tscn`
2. Add to `RoomManager.setup_rooms()`
3. Set up doors with `target_room`

### Adding a New State
1. Create script extending `State`
2. Add as child of StateMachine
3. Set up transitions

### Adding a New Collectible
1. Extend `Collectible` class
2. Override `collect()` method
3. Set up scene with Area2D

### Using Colors
1. Access via `GameColors.COLOR_NAME`
2. Use `GameColors.get_color_by_name()`
3. Get categories via `GameColors.get_*_colors()`

---

**This documentation must be referenced for all development work on this project to maintain consistency with the established framework.**
