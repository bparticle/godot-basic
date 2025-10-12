# State Machine Implementation

This document describes the state machine implementation in the Pimpa-Raka game, following the patterns from the Godot state machine tutorial.

## Overview

The state machine system provides a clean, maintainable way to manage complex entity behaviors. It follows the tutorial's best practices including:

- **Base State Class**: All states inherit from a common `State` class
- **State Machine Manager**: Handles state transitions and lifecycle
- **Movement Components**: Flexible input handling using duck typing
- **Hierarchical States**: Reusable state logic through inheritance
- **Concurrent State Machines**: Multiple independent state systems

## Architecture

### Core Components

1. **State.gd** - Base state class with enter, exit, update, and physics_update methods
2. **StateMachine.gd** - Manages state transitions and calls state methods
3. **MovementComponent.gd** - Interface for movement input handling
4. **GameStateManager.gd** - Game-wide state management (playing, paused, game over)

### Player State Machine

The player uses a state machine to manage movement states:

- **IdleState** - Standing still, blinking, waiting for input
- **WalkState** - Horizontal movement
- **JumpState** - Jumping with phase tracking (up, peak, down, land)
- **CrouchState** - Crouching movement
- **ClimbState** - Ladder climbing with centering

#### Player State Transitions

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

### Enemy AI State Machine

Simple enemy AI with three states:

- **IdleState** - Patrols or waits
- **ChaseState** - Follows the player
- **AttackState** - Attacks when in range

#### Enemy State Transitions

```
Idle → Chase (player in detection range)
Chase → Idle (player out of detection range)
Chase → Attack (player in attack range)
Attack → Chase (attack complete, player out of attack range)
Attack → Idle (player out of detection range)
```

### Door State Machine

Interactive doors with four states:

- **ClosedState** - Door is closed, can be opened
- **OpeningState** - Door is opening (animated)
- **OpenState** - Door is open, can be closed
- **ClosingState** - Door is closing (animated)

## Implementation Details

### State Class Pattern

Each state implements the base State interface:

```gdscript
class_name PlayerIdleState
extends State

var parent: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

func enter():
    # Called when entering this state
    pass

func exit():
    # Called when exiting this state
    pass

func update(delta: float):
    # Called every frame
    pass

func physics_update(delta: float):
    # Called every physics frame
    pass
```

### Movement Component System

The movement component system provides flexible input handling:

```gdscript
class_name PlayerMovementComponent
extends MovementComponent

func get_movement_direction() -> float:
    return Input.get_axis("ui_left", "ui_right")

func wants_to_jump() -> bool:
    return Input.is_action_just_pressed("ui_up")

func wants_to_crouch() -> bool:
    return Input.is_action_pressed("ui_down")

func wants_to_climb() -> bool:
    return Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")
```

### State Transitions

States request transitions using signals:

```gdscript
func check_transitions():
    if movement_component.wants_to_jump():
        transition_to("jump")
```

### Scene Structure

State machines are organized as node hierarchies:

```
Player
├── StateMachine
│   ├── Idle
│   ├── Walk
│   ├── Jump
│   ├── Crouch
│   └── Climb
└── MovementComponent
```

## Benefits

### Code Organization
- **Separation of Concerns**: Each state handles specific behavior
- **Maintainability**: Easy to modify individual states
- **Readability**: Clear state logic and transitions

### Flexibility
- **Reusable Components**: Movement components can be swapped
- **Easy Testing**: States can be tested independently
- **Extensibility**: New states can be added easily

### Performance
- **Efficient Updates**: Only active state processes
- **Clean Transitions**: Proper enter/exit lifecycle
- **Memory Management**: States are managed by the scene tree

## Usage Examples

### Creating a New State

1. Create a new script extending `State`
2. Implement the required methods
3. Add the state as a child of the StateMachine node
4. Set up transitions in the state's logic

### Adding Movement Components

1. Create a script extending `MovementComponent`
2. Implement the required interface methods
3. Add as a child of the entity
4. Reference in state logic

### State Machine Setup

1. Add StateMachine node to entity
2. Add state nodes as children
3. Set initial_state in the StateMachine
4. Connect state transition signals

## Best Practices

1. **Keep States Focused**: Each state should handle one specific behavior
2. **Use Components**: Abstract input handling into components
3. **Clean Transitions**: Always check conditions before transitioning
4. **Proper Lifecycle**: Use enter/exit for setup and cleanup
5. **Documentation**: Comment state logic and transitions clearly

## Future Enhancements

- **Concurrent State Machines**: Multiple independent state systems
- **State Data Sharing**: Shared data between states
- **Animation Integration**: Automatic animation based on states
- **Debug Tools**: State machine visualization and debugging
- **Performance Optimization**: State pooling and optimization

This implementation provides a solid foundation for complex entity behaviors while maintaining clean, maintainable code structure.
