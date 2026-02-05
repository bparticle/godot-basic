# Enemy AI System Documentation

This document explains how to use and extend the enemy AI system to create new monster types.

## Architecture Overview

```
Enemy.gd (CharacterBody2D)
├── Vision System (can_see_player, can_see_player_peripheral)
├── Awareness System (awareness_level, last_known_player_position)
├── Personality System (aggression, caution, persistence)
└── StateMachine
    ├── idle (patrol)
    ├── suspicious (investigating)
    ├── chase (pursuing player)
    ├── attack (telegraph → strike → recovery)
    ├── search (looking for lost player)
    └── hurt (stagger reaction)
```

## State Flow Diagram

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    ▼                                         │
┌─────────┐   peripheral   ┌────────────┐   found player   ┌──┴──┐
│  IDLE   │ ────────────▶  │ SUSPICIOUS │ ───────────────▶ │CHASE│
│(patrol) │                │  (looking) │                  │     │
└────┬────┘                └─────┬──────┘                  └──┬──┘
     │                           │                            │
     │ direct sight              │ timeout                    │ in attack range
     │                           ▼                            ▼
     │                     back to patrol              ┌──────────┐
     │                                                 │  ATTACK  │
     └────────────────────────────────────────────────▶│telegraph │
                                                       │ →strike  │
                    ┌──────────────────────────────────│→recovery │
                    │ lost sight                       └────┬─────┘
                    ▼                                       │
              ┌──────────┐                                  │
              │  SEARCH  │◀─────────────────────────────────┘
              │(last pos)│        lost line of sight
              └────┬─────┘
                   │ timeout
                   ▼
              back to IDLE

                         ┌──────┐
     Any State ─────────▶│ HURT │──────▶ CHASE (angry)
              took damage│stagger│
                         └──────┘
```

---

## Creating a New Enemy Type

### Method 1: Inspector Configuration (Recommended)

1. **Create a new scene** inheriting from `Enemy.tscn`
2. **Adjust exported parameters** in the Inspector:

#### Enemy Stats
| Parameter | Default | Description |
|-----------|---------|-------------|
| `speed` | 18.0 | Base movement speed |
| `detection_range` | 100.0 | Legacy range (vision_range is preferred) |
| `attack_range` | 20.0 | Distance to trigger attack |
| `attack_damage` | 1 | Damage per hit |
| `max_health` | 3 | Hit points |
| `enemy_color` | Green | Sprite tint |

#### Vision
| Parameter | Default | Description |
|-----------|---------|-------------|
| `vision_range` | 120.0 | How far the enemy can see directly |
| `vision_angle` | 60.0 | Half-angle of vision cone (degrees) |
| `peripheral_range` | 60.0 | Range for peripheral detection |
| `peripheral_angle` | 120.0 | Half-angle of peripheral vision |

#### Awareness
| Parameter | Default | Description |
|-----------|---------|-------------|
| `suspicion_buildup_rate` | 2.0 | How fast awareness increases |
| `suspicion_decay_rate` | 0.5 | How fast awareness decreases |
| `alert_threshold` | 1.0 | Awareness needed to become alert |
| `search_duration` | 4.0 | How long to search for lost player |

#### Personality (0.0 - 1.0)
| Parameter | Default | Effect |
|-----------|---------|--------|
| `aggression` | 0.5 | High: faster chase, shorter telegraph, larger attack range |
| `caution` | 0.5 | High: shorter vision range, more careful |
| `persistence` | 0.5 | High: searches longer, awareness decays slower |

### Method 2: Script Extension

```gdscript
# scripts/enemies/FastEnemy.gd
class_name FastEnemy
extends Enemy

func _ready():
    # Override stats for a fast, aggressive enemy
    speed = 30.0
    vision_range = 80.0  # Shorter vision (rushes in close)
    aggression = 0.9
    caution = 0.1
    persistence = 0.3
    
    # Call parent _ready
    super._ready()
```

---

## Enemy Presets

### Grunt (Basic)
```
speed: 18.0
aggression: 0.5
caution: 0.5
persistence: 0.5
```
Balanced enemy. Patrols, investigates, chases at moderate speed.

### Rusher (Fast)
```
speed: 30.0
vision_range: 80.0
aggression: 0.9
caution: 0.1
persistence: 0.3
```
Fast but reckless. Short vision, quick attacks, gives up easily.

### Stalker (Cautious)
```
speed: 14.0
vision_range: 160.0
aggression: 0.3
caution: 0.8
persistence: 0.7
```
Slow but observant. Sees far, long telegraph (easy to dodge), searches persistently.

### Brute (Heavy)
```
speed: 12.0
attack_damage: 2
max_health: 5
aggression: 0.7
caution: 0.2
persistence: 0.9
```
Slow, hits hard, doesn't give up.

---

## Vision System

### How It Works

1. **Direct Vision** (`can_see_player()`)
   - Checks if player is within `vision_range`
   - Checks if player is within `vision_angle` cone (based on `walk_direction`)
   - Raycasts to ensure no walls block line of sight
   - Returns `true` = enemy is fully aware of player

2. **Peripheral Vision** (`can_see_player_peripheral()`)
   - Checks wider angle (`peripheral_angle`) but shorter range (`peripheral_range`)
   - Only triggers if player is NOT in direct vision
   - Returns `true` = enemy notices something at edge of vision

### Raycast Details

The raycast starts from enemy's "eye level" (4px above center) and aims at player's center. Only terrain (collision layer 1) blocks vision.

```gdscript
# Customize what blocks vision by changing collision_mask
query.collision_mask = 1  # Only terrain blocks sight
```

---

## Awareness System

### Awareness Levels

| Level | State | Behavior |
|-------|-------|----------|
| 0.0 | Unaware | Normal patrol |
| 0.0 - 0.5 | Suspicious | Looking around |
| 0.5 - 1.0 | Alert | Actively investigating |
| 1.0+ | Combat | Chasing/attacking |
| 2.0 | Hyper-alert | After being hit |

### Buildup & Decay

```
Direct sight:     +2.0 * suspicion_buildup_rate * delta
Peripheral sight: +1.0 * suspicion_buildup_rate * delta
No sight:         -1.0 * suspicion_decay_rate * (1 - persistence * 0.5) * delta
```

### Last Known Position

When the enemy loses sight of the player, they remember `last_known_player_position` and will:
1. Move toward that position in Search state
2. Look around when they arrive
3. Return to patrol after `search_duration` seconds

---

## Attack Telegraph System

### Phases

1. **TELEGRAPH** (default 0.3s)
   - Enemy stops moving
   - Visual warning (pulsing yellow/red if no animation)
   - Duration reduced by `aggression` (up to 40% faster)

2. **STRIKE** (default 0.2s)
   - Enemy lunges toward player (1.5x attack speed)
   - Damage dealt at 30% through this phase
   - Only hits once per attack cycle

3. **RECOVERY** (default 0.4s)
   - Enemy slows down
   - Slightly dimmed sprite (vulnerability indicator)
   - Cannot start new attack until complete

### Adding Attack Animations

Add these animations to the enemy's SpriteFrames resource:
- `attack_telegraph` - Wind-up frames (optional, uses tint if missing)
- `attack` - Strike frames (required)

---

## Adding Custom States

### 1. Create the State Script

```gdscript
# scripts/enemies/EnemyPatrolState.gd
class_name EnemyCustomState
extends State

var parent: Enemy
var animated_sprite: AnimatedSprite2D

func enter():
    parent = get_parent().get_parent()
    animated_sprite = parent.get_node("AnimatedSprite2D")
    # Setup code here

func exit():
    # Cleanup code here
    pass

func update(delta: float):
    # Called every frame (visual updates)
    pass

func physics_update(delta: float):
    # Called every physics frame (movement)
    if parent.is_dead:
        return
    
    # Your logic here
    
    check_transitions()

func check_transitions():
    # Define when to leave this state
    if some_condition:
        transition_to("chase")
        return
```

### 2. Add to Scene

1. Open `scenes/enemies/Enemy.tscn`
2. Add ext_resource for your script
3. Add a new Node under StateMachine with your script

### 3. Reference from Other States

```gdscript
# In another state's check_transitions()
if should_enter_custom_state:
    transition_to("custom")  # Must match node name
```

---

## Debug Visualization

Enable in the Inspector:
- `debug_draw_ai` - Shows line to target (green=visible, red=blocked)
- `debug_draw_detection` - Shows vision cones, attack range, awareness bar

### What the Debug Drawing Shows

- **Green cone**: Direct vision range and angle
- **Yellow cone**: Peripheral vision
- **Red circle**: Attack range
- **Vertical bar**: Current awareness level (taller = more aware)
- **Orange dot**: Last known player position (when not visible)
- **Line to player**: Green if visible, red if blocked

---

## Common Customizations

### Make Enemy Ignore Walls (Ghost)

```gdscript
func _raycast_to_player() -> bool:
    return true  # Always "sees" through walls
```

### Add Hearing (Detect Player Behind)

```gdscript
func can_hear_player() -> bool:
    if not target:
        return false
    var distance = global_position.distance_to(target.global_position)
    var hearing_range = 40.0
    # Hear player if they're running (high velocity)
    return distance < hearing_range and target.velocity.length() > 50.0
```

Then add to idle state's `check_transitions()`:
```gdscript
if parent.can_hear_player():
    transition_to("suspicious")
```

### Add Patrol Points

```gdscript
@export var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0

func _get_next_patrol_point() -> Vector2:
    if patrol_points.is_empty():
        return global_position
    current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
    return patrol_points[current_patrol_index]
```

### Add Jump Attack

Create `EnemyJumpAttackState.gd` that:
1. Calculates arc to player position
2. Applies upward velocity during telegraph
3. Deals damage on landing near player

---

## File Reference

| File | Purpose |
|------|---------|
| `Enemy.gd` | Main enemy class with vision, awareness, personality |
| `EnemyIdleState.gd` | Patrol behavior, peripheral detection |
| `EnemySuspiciousState.gd` | Looking around after glimpsing player |
| `EnemyChaseState.gd` | Active pursuit with smart direction |
| `EnemyAttackState.gd` | Telegraph → Strike → Recovery phases |
| `EnemySearchState.gd` | Investigating last known position |
| `EnemyHurtState.gd` | Damage stagger reaction |
| `EnemyMovementComponent.gd` | Movement interface (for future expansion) |
