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
    ├── attack (uses pluggable attack state)
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
     │                                                 │telegraph │
     └────────────────────────────────────────────────▶│ →strike  │
                                                       │→recovery │
                    ┌──────────────────────────────────└────┬─────┘
                    │ lost sight                            │
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

### Step 1: Create a New Scene

1. **Duplicate** `scenes/enemies/Enemy2.tscn` as a starting point
2. **Rename** the root node to your enemy name (e.g., "Slime", "Goblin")
3. **Create new SpriteFrames** resource with your enemy's animations

### Step 2: Configure Parameters

Select the root node and adjust exported parameters in the Inspector:

#### Enemy Stats
| Parameter | Default | Description |
|-----------|---------|-------------|
| `speed` | 18.0 | Base movement speed |
| `detection_range` | 100.0 | How close player must be to trigger awareness |
| `attack_range` | 90.0 | Distance to deal damage |
| `attack_trigger_range_multiplier` | 1.5 | Multiplier for when to start attacking (higher = attacks from further) |
| `attack_damage` | 1 | Damage per hit |
| `max_health` | 3 | Hit points |

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

### Step 3: Choose an Attack State

The attack state determines how the enemy attacks. Available options:

#### LungeAttackState (Recommended)
- Enemy **jumps toward** the player
- Best for aggressive, melee enemies
- Configurable: `lunge_speed_x`, `lunge_jump_force`

#### EnemyAttackState (Simple)
- Enemy **moves forward** while attacking
- No jumping, just forward motion
- Good for basic patrol enemies

To change attack state, update the `attack` node under `StateMachine` to use the desired script.

---

## Attack State Configuration

### LungeAttackState Parameters

Select the `attack` node under `StateMachine` in your enemy scene:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `lunge_speed_x` | 60.0 | Horizontal speed during lunge (pixels/sec) |
| `lunge_jump_force` | -80.0 | Vertical jump force (negative = up, smaller = shorter hop) |

### Attack Trigger Distance

The enemy starts attacking when:
```
distance_to_player <= attack_range * attack_trigger_range_multiplier
```

For aggressive lunging enemies, set `attack_trigger_range_multiplier` high (e.g., 6.0) so they lunge from far away.

---

## Enemy Presets

### Hopper (Current Default)
```
speed: 18.0
attack_trigger_range_multiplier: 6.0
aggression: 0.7
Attack: LungeAttackState
```
Aggressive leaping enemy. Spots player and immediately lunges.

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

---

## Required Animations

Each enemy's SpriteFrames resource must include:

| Animation | Required | Description |
|-----------|----------|-------------|
| `idle` | Yes | Standing/patrolling |
| `walk` | Yes | Moving/chasing |
| `attack` | Yes | Attack animation |
| `dead` | Yes | Death animation (plays once) |
| `hurt` | No | Damage reaction (uses idle if missing) |

---

## Adding Custom States

### 1. Create the State Script

```gdscript
# scripts/enemies/MyCustomState.gd
class_name MyCustomState
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

### 2. Add to Enemy Scene

1. Open your enemy scene
2. Add ext_resource for your script
3. Add a new Node under StateMachine named after the state
4. Attach your script to it

---

## Debug Visualization

Enable in the Inspector:
- `debug_draw_ai` - Shows line to target (green=visible, red=blocked)
- `debug_draw_detection` - Shows vision cones, attack range, awareness bar

---

## File Reference

| File | Purpose |
|------|---------|
| `Enemy.gd` | Main enemy class with vision, awareness, personality |
| `EnemyIdleState.gd` | Patrol behavior, peripheral detection |
| `EnemySuspiciousState.gd` | Looking around after glimpsing player |
| `EnemyChaseState.gd` | Active pursuit with smart direction |
| `LungeAttackState.gd` | Lunge/jump attack (telegraph → lunge → recovery) |
| `EnemyAttackState.gd` | Simple forward attack (telegraph → strike → recovery) |
| `EnemySearchState.gd` | Investigating last known position |
| `EnemyHurtState.gd` | Damage stagger reaction |
| `EnemyMovementComponent.gd` | Movement interface (for future expansion) |

## Scene Reference

| Scene | Description |
|-------|-------------|
| `scenes/enemies/Enemy2.tscn` | Hopper enemy - uses lunge attack, aggressive |

## Resource Reference

| Resource | Description |
|----------|-------------|
| `resources/characters/enemy2_sprite_frames.tres` | Sprite frames for Enemy2 |
