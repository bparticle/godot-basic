# Pimpa-Raka Game Audit Checklist

> **Project:** pimpa-raka (Godot 4.5)  
> **Audit Date:** February 2026  
> **Rendering:** ~~Pixel-perfect (Nearest filter, 300x300 viewport, 2x scale)~~  
> **Current Mode:** HYBRID (900x900 viewport, 3x art scale - testing smooth effects)

## Hybrid Mode Test Setup (Active)

The game is currently configured in **hybrid mode** for testing smooth effects:
- Viewport: 900x900 (3x the original 300x300)
- Camera zoom: 4x (shows 225x225 game units - tighter focus)
- UI CanvasLayer scale: 4x (HUD matches the scaled view)
- Each art pixel now spans 3x3 screen pixels
- Sprites still use Nearest filter (chunky look preserved)
- Effects (squash/stretch, particles) can be smooth
- Screen shake: **DISABLED** (too distracting for this game style)

**To revert to pixel-perfect mode**, change:

1. `project.godot`:
```ini
window/size/viewport_width=300
window/size/viewport_height=300
window/stretch/scale=2.0
```

2. `SmartCamera.gd`: Set `HYBRID_ZOOM = 1.0` (or adjust to taste - higher = more zoomed in)

3. `Game.tscn`: Remove `transform` from UI CanvasLayer (or set to match zoom level)

---

---

## Current State Summary

### Strengths
- [x] Solid Godot 4.5 foundation
- [x] State machine architecture for enemies and doors
- [x] Modern platformer basics (coyote time, jump buffering, variable jump)
- [x] Smart camera with room boundaries
- [x] Signal-driven communication
- [x] Touch controls for web/mobile
- [x] Good manager separation (Health, Room, GameState)

### Known Issues
- [ ] Player state machine classes exist but aren't integrated
- [ ] 1,360-line Player.gd needs refactoring
- [x] ~~No visual feedback/juice~~ (squash/stretch and hit stop added)
- [ ] Missing menus (main, pause, settings)
- [x] ~~Enemy AI is predictable~~ (vision system, awareness states, attack telegraph, hurt reactions added)
- [ ] No level progression system
- [ ] Limited audio feedback

---

## Tier 1: Low-Hanging Fruit (Quick Wins)

### 1.1 Squash & Stretch ✅ COMPLETE (Hybrid Mode)
> **Impact:** High | **Effort:** Low  
> **Note:** Using hybrid mode (higher pixel density), runtime scaling now works smoothly

- [x] Jump squash/stretch (vertical stretch on takeoff)
- [x] Landing squash (horizontal squash on landing)
- [x] Fall stretch (dynamic stretch based on fall velocity)
- [x] Smooth lerp recovery back to normal scale
- [x] Configurable via exported variables in Player inspector

**Implemented in:** `scripts/player/Player.gd`

```gdscript
# Player.gd - Squash & Stretch settings
@export var squash_stretch_enabled: bool = true
@export var jump_squash: Vector2 = Vector2(0.8, 1.25)
@export var land_squash: Vector2 = Vector2(1.3, 0.7)
@export var fall_stretch: Vector2 = Vector2(0.85, 1.15)
@export var squash_recovery_speed: float = 12.0
```

### 1.2 Screen Shake
> **Impact:** High | **Effort:** Low  
> **Status:** ⚠️ IMPLEMENTED BUT DISABLED - Found too distracting for this game's style

- [x] Add shake function to `SmartCamera.gd` (implemented, then disabled)
- [x] Shake on: player damage taken (disabled)
- [x] Shake on: landing from high fall (disabled)
- [ ] ~~Shake on: enemy death (subtle)~~ (skipped)
- [ ] ~~Shake on: collecting large gem (very subtle)~~ (skipped)
- [x] Add `shake_intensity` and `shake_decay` parameters (in EffectsManager)
- [ ] ~~Ensure shake snaps to pixel grid~~ (not needed - disabled)

**Note:** Screen shake was implemented but removed at user request. The infrastructure exists in `EffectsManager.gd` if needed later.

### 1.3 Hit Stop / Freeze Frames ✅ COMPLETE
> **Impact:** High | **Effort:** Low

- [x] Create hit stop function (pause game briefly on impact)
- [x] Apply on: player taking damage (~60ms)
- [x] Apply on: stomping enemy (~40ms)
- [x] Apply on: player death (~100ms)

**Implemented in:** `scripts/managers/EffectsManager.gd` (autoload)

```gdscript
# EffectsManager.gd - DONE
func hit_stop(duration: float = 0.05) -> void:
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0

func impact(hit_stop_duration: float = 0.04, _shake_intensity: float = 3.0) -> void:
    hit_stop(hit_stop_duration)
```

### 1.4 Improve Jump Feel
> **Impact:** Medium | **Effort:** Low

- [ ] Increase `fall_gravity_scale` from 2.0 to 2.5 (snappier descent)
- [ ] Increase `low_jump_gravity_scale` from 1.8 to 3.0 (more control)
- [ ] Test and tune to feel right
- [ ] Consider adding "hang time" at apex (brief reduced gravity)

### 1.5 Pixel Art Dust Particles
> **Impact:** Medium | **Effort:** Low-Medium  
> **Note:** Use pixel-snapped positions and tiny sprites

- [ ] Create 1x1 or 2x2 pixel particle sprites
- [ ] Create dust particle scene (`GPUParticles2D` or `CPUParticles2D`)
- [ ] Snap particle positions to pixel grid
- [ ] Add dust on: jump takeoff
- [ ] Add dust on: landing
- [ ] Add dust on: running (periodic footsteps)
- [ ] Add dust on: changing direction while running
- [ ] Set particle lifetime short (0.2-0.4s)

```gdscript
# Pixel-snapped particle emission
func emit_dust(pos: Vector2) -> void:
    var dust = dust_scene.instantiate()
    dust.global_position = Vector2(round(pos.x), round(pos.y))
    dust.emitting = true
    get_tree().current_scene.add_child(dust)
```

### 1.6 Color Flash Effects (Pixel-Safe)
> **Impact:** Medium | **Effort:** Low  
> **Note:** You already have `white_flash.gdshader` - expand usage

- [ ] Flash white on damage (already implemented)
- [ ] Flash on enemy stomp
- [ ] Add brief flash on collectible pickup
- [ ] Consider palette swap shader for power-up states

### 1.7 Sound Design Polish
> **Impact:** High | **Effort:** Low

- [ ] Add pitch variation to sound effects (±10%)
- [ ] Add landing sound intensity based on fall height
- [ ] Add enemy death sound
- [ ] Add UI interaction sounds
- [ ] Add room transition sound

---

## Tier 2: Medium Effort Improvements

### 2.1 Refactor Player to Use State Machine
> **Impact:** High | **Effort:** Medium  
> **Priority:** High - reduces technical debt

- [ ] Review existing state classes in `scripts/states/player/`
- [ ] Create `PlayerStateMachine` node in Player scene
- [ ] Integrate `PlayerIdleState.gd`
- [ ] Integrate `PlayerWalkState.gd`
- [ ] Integrate `PlayerJumpState.gd`
- [ ] Integrate `PlayerCrouchState.gd`
- [ ] Integrate `PlayerClimbState.gd`
- [ ] Add `PlayerFallState.gd` (separate from jump)
- [ ] Add `PlayerLandState.gd` (for landing animation)
- [ ] Remove duplicate logic from `Player.gd`
- [ ] Test all transitions thoroughly

### 2.2 Main Menu System
> **Impact:** High | **Effort:** Medium

- [ ] Create `MainMenu.tscn` scene
- [ ] Add "Start Game" button
- [ ] Add "Settings" button
- [ ] Add "Quit" button
- [ ] Create pixel art menu background or use game scene
- [ ] Add menu navigation sounds
- [ ] Set as initial scene (or add title card before Game.tscn)

### 2.3 Pause Menu System
> **Impact:** High | **Effort:** Medium

- [ ] Create `PauseMenu.tscn` scene
- [ ] Add "Resume" button
- [ ] Add "Settings" button
- [ ] Add "Quit to Menu" button
- [ ] Add visual pause overlay (dim/blur effect)
- [ ] Connect to existing `GameStateManager` pause logic
- [ ] Add pause sound effect

### 2.4 Settings Menu
> **Impact:** Medium | **Effort:** Medium

- [ ] Create `SettingsMenu.tscn` scene
- [ ] Add SFX volume slider
- [ ] Add Music volume slider (when music added)
- [ ] Add fullscreen toggle
- [ ] Add controls display/remapping
- [ ] Save settings to file
- [ ] Load settings on game start

### 2.5 Enemy Variety
> **Impact:** High | **Effort:** Medium

- [ ] **Patrol Enemy** (current behavior - done)
- [ ] **Jumper Enemy** - hops toward player periodically
- [ ] **Shooter Enemy** - fires projectiles from distance
- [ ] **Flyer Enemy** - sine wave or patrol pattern in air
- [ ] Create base enemy class improvements for extensibility
- [ ] Add unique sprites for each enemy type
- [ ] Balance difficulty across rooms

### 2.6 Room Transition Effects
> **Impact:** Medium | **Effort:** Medium

- [ ] Create transition overlay (black `ColorRect`)
- [ ] Add fade out before room switch
- [ ] Add fade in after room switch
- [ ] Consider wipe/slide transitions for variety
- [ ] Add transition sound

```gdscript
# In RoomManager.gd or new TransitionManager.gd
func transition_to_room(room_idx: int) -> void:
    var tween = create_tween()
    tween.tween_property(transition_rect, "modulate:a", 1.0, 0.15)
    await tween.finished
    _load_room(room_idx)
    tween = create_tween()
    tween.tween_property(transition_rect, "modulate:a", 0.0, 0.15)
```

### 2.7 Improved Death & Respawn
> **Impact:** Medium | **Effort:** Low-Medium

- [ ] Add death particles (pixel explosion)
- [ ] Add brief death animation hold
- [ ] Add respawn animation (fade in or materialize)
- [ ] Screen shake on death
- [ ] Consider brief slowmo before death

---

## Tier 3: Significant Development

### 3.1 Wall Slide & Wall Jump
> **Impact:** High | **Effort:** Medium-High

- [ ] Add wall detection raycasts (left and right)
- [ ] Implement wall slide state (slower fall on wall)
- [ ] Add wall slide animation frames
- [ ] Implement wall jump (push away from wall + up)
- [ ] Add wall slide particles (pixel dust)
- [ ] Add wall slide/jump sounds
- [ ] Add coyote time for wall jumps
- [ ] Balance wall jump velocity

```gdscript
# Key parameters to tune
var wall_slide_speed: float = 30.0
var wall_jump_velocity: Vector2 = Vector2(120, -200)
var wall_jump_control_delay: float = 0.15
```

### 3.2 Dash Mechanic
> **Impact:** High | **Effort:** Medium

- [ ] Add dash input action
- [ ] Implement dash state
- [ ] Add dash cooldown (visual indicator?)
- [ ] Add dash trail effect (ghost sprites or line)
- [ ] Add i-frames during dash (optional)
- [ ] Add dash particles
- [ ] Add dash sound
- [ ] Dash refreshes on landing (Celeste-style) or cooldown-based

```gdscript
# Key parameters
var dash_speed: float = 250.0
var dash_duration: float = 0.12
var dash_cooldown: float = 0.4
```

### 3.3 Parallax Backgrounds
> **Impact:** Medium | **Effort:** Medium

- [ ] Create background tile layers
- [ ] Set up `ParallaxBackground` node
- [ ] Add distant layer (0.2 scroll factor)
- [ ] Add mid layer (0.5 scroll factor)
- [ ] Add near layer (0.8 scroll factor)
- [ ] Ensure layers use pixel art style
- [ ] Test with room boundaries

### 3.4 Audio Manager & Music
> **Impact:** High | **Effort:** Medium

- [ ] Create `AudioManager.gd` autoload
- [ ] Implement music playback with crossfade
- [ ] Implement SFX pooling (for overlapping sounds)
- [ ] Add background music track(s)
- [ ] Add music intensity layers (optional)
- [ ] Set up audio buses (Master, Music, SFX)
- [ ] Connect to settings for volume control

### 3.5 Save System
> **Impact:** High | **Effort:** Medium

- [ ] Create `SaveManager.gd` autoload
- [ ] Define save data structure
- [ ] Implement save function
- [ ] Implement load function
- [ ] Save on: room completion, checkpoint, quit
- [ ] Load on: game start, continue
- [ ] Add save slot support (optional)

```gdscript
var save_data = {
    "current_room": 0,
    "checkpoint_position": Vector2.ZERO,
    "lives": 3,
    "collectibles": {
        "small_gems": 0,
        "large_gems": 0,
        "keys_collected": []
    },
    "settings": {
        "sfx_volume": 1.0,
        "music_volume": 1.0,
        "fullscreen": false
    }
}
```

### 3.6 Checkpoints System
> **Impact:** Medium | **Effort:** Medium

- [ ] Create checkpoint scene/object
- [ ] Add checkpoint activation animation
- [ ] Save checkpoint position on activation
- [ ] Visual indicator for active checkpoint
- [ ] Sound on checkpoint activation

---

## Tier 4: Advanced Polish

### 4.1 Enhanced Input Buffering
> **Impact:** Medium | **Effort:** Medium

- [ ] Create `InputBuffer` class
- [ ] Buffer jump (already done)
- [ ] Buffer dash
- [ ] Buffer attack (if added)
- [ ] Configurable buffer times per action

### 4.2 Ghost Trail Effect
> **Impact:** Medium | **Effort:** Medium

- [ ] Create ghost sprite spawner
- [ ] Spawn ghosts during dash
- [ ] Fade out ghosts over time
- [ ] Match ghost to current animation frame
- [ ] Tint ghosts (blue/white)

### 4.3 Death Particles & Effects
> **Impact:** Medium | **Effort:** Low-Medium

- [ ] Create pixel explosion particles
- [ ] Screen flash on death
- [ ] Brief slowmo before death
- [ ] Respawn particles (materialize effect)

### 4.4 Accessibility Options
> **Impact:** High | **Effort:** Medium-High

- [ ] Add colorblind mode options
- [ ] Add high contrast mode
- [ ] Add screen reader support for menus
- [ ] Add control remapping
- [ ] Add difficulty options:
  - [ ] More lives
  - [ ] Slower enemies
  - [ ] Longer coyote time
  - [ ] Invincibility mode

### 4.5 Speedrun Features (Optional)
> **Impact:** Low | **Effort:** Low-Medium

- [ ] Add in-game timer
- [ ] Add room split times
- [ ] Add ghost replay (advanced)

---

## Code Quality Tasks

### Architecture Improvements

- [ ] Integrate player state machine (see 2.1)
- [ ] Create `HitboxComponent` for reusable damage dealing
- [ ] Create `HurtboxComponent` for reusable damage receiving
- [ ] Extract physics constants to resource file
- [ ] Implement object pooling for particles/projectiles

### Code Cleanup

- [ ] Split `Player.gd` (1,360 lines) into manageable pieces
- [ ] Replace magic numbers with named constants
- [ ] Add type hints to all functions
- [ ] Document public methods with comments
- [ ] Consistent state handling (remove boolean/enum mix)

### Testing

- [ ] Test all player state transitions
- [ ] Test enemy AI edge cases
- [ ] Test room transitions
- [ ] Test save/load (when implemented)
- [ ] Test touch controls
- [ ] Test web export

---

## Comparison Checklist: Modern Platformer Standards

| Feature | Status | Target |
|---------|--------|--------|
| Coyote Time | ✅ 0.1s | 0.08-0.15s |
| Jump Buffer | ✅ 0.1s | 0.1-0.15s |
| Variable Jump | ✅ Yes | Yes |
| Wall Jump | ⬜ No | Optional |
| Dash | ⬜ No | Optional |
| Squash/Stretch | ✅ Yes | Yes |
| Screen Shake | ⚠️ Disabled | Optional |
| Particles | ⬜ No | Yes |
| Hit Stop | ✅ Yes | Yes |
| Parallax BG | ⬜ No | Yes |
| Save System | ⬜ No | Yes |
| Main Menu | ⬜ No | Yes |
| Pause Menu | ⬜ No | Yes |
| Settings | ⬜ No | Yes |
| Music | ⬜ No | Yes |
| Accessibility | ⬜ No | Recommended |

---

## Implementation Priority

### Phase 1: Game Feel (Start Here)
1. [x] ~~Frame-based anticipation sprites~~ → Runtime squash/stretch (hybrid mode)
2. [x] ~~Screen shake~~ → Implemented but disabled (too distracting)
3. [x] Hit stop ✅
4. [ ] Sound polish
5. [ ] Pixel dust particles

### Phase 2: Movement & Code Quality
1. [ ] Player state machine refactor
2. [ ] Jump feel improvements
3. [ ] Wall slide/jump (optional)
4. [ ] Dash (optional)

### Phase 3: Game Flow & UI
1. [ ] Main menu
2. [ ] Pause menu
3. [ ] Settings
4. [ ] Room transitions
5. [ ] Save system

### Phase 4: Content & Polish
1. [ ] Enemy variety
2. [ ] Parallax backgrounds
3. [ ] Music & audio manager
4. [ ] Checkpoints
5. [ ] Accessibility

---

## Notes

### Hybrid Mode (Current Setup)
- **Runtime scaling works** - squash/stretch via sprite scale is smooth
- **Higher effect fidelity** - 4x pixel density for smooth animations
- **Sprites still chunky** - Nearest filter preserved, art looks pixel-y
- **Sub-pixel movement** - smoother motion than true pixel-perfect
- **UI scaled separately** - 225x225 base, scaled 4x via Control node

### Pixel-Perfect Considerations (If Reverting)
- **No runtime scaling** - use sprite frames for squash/stretch
- **Snap positions to grid** - `round()` or `snapped(Vector2.ONE)`
- **Integer camera positions** - avoid sub-pixel rendering
- **Small particle sprites** - 1x1 or 2x2 pixels work best
- **Avoid alpha gradients** - use dithering or hard edges

### Resources
- [Celeste Movement Breakdown](https://maddythorson.medium.com/celeste-and-towerfall-physics-d24bd2ae0f19)
- [Game Feel by Steve Swink](http://www.game-feel.com/)
- [Juice it or Lose it (GDC Talk)](https://www.youtube.com/watch?v=Fy0aCDmgnxg)

---

## Recent Changes Log

### February 4, 2026 - Hybrid Mode & Game Feel
- ✅ Set up hybrid rendering mode (900x900 viewport, 4x camera zoom)
- ✅ Added `EffectsManager.gd` autoload for global effects
- ✅ Implemented hit stop (freeze frames) on damage, stomp, death
- ✅ Implemented squash/stretch system (jump, land, fall)
- ✅ Fixed UI scaling for hybrid mode (225x225 base, 4x scale)
- ⚠️ Screen shake implemented but disabled (user preference)

---

*Last Updated: February 4, 2026*
