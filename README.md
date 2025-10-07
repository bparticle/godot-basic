# Pimpa Raka

A minimal 8x8 pixel art platformer game using Godot 4.3.

## Project Structure

```
pimpa-raka/
├── Game.tscn              # Main game scene with TileMapLayer
├── Player.tscn            # Player character scene
├── Player.gd              # Player movement script
├── VIC20Tileset.tres      # 8x8 tile set resource
├── project.godot          # Project configuration
└── assets/
    ├── characters/
    │   └── player_8x8.png # 8x8 player sprite
    └── tiles/             # 8x8 tile sprites
        ├── grass_8x8.png
        ├── dirt_8x8.png
        ├── stone_8x8.png
        └── wall_8x8.png
```

## Display Settings

- **Viewport Size**: 256x240 (retro PICO-8 style)
- **Window Size**: 1024x960 (4x scale)
- **Tile Size**: 8x8 pixels
- **Pixel Perfect**: Yes (nearest neighbor filtering)

## Controls

- **Arrow Keys**: Move left/right
- **Space**: Jump

## Getting Started

1. Open the project in Godot 4.3
2. Let Godot reimport all assets (this happens automatically)
3. Open `Game.tscn` 
4. Paint tiles on the TileMapLayer using the tileset
5. Press F5 to run the game

## Tile Painting

1. Select the `TileMapLayer` node in `Game.tscn`
2. Use the TileMap editor at the bottom
3. Select tiles from the tileset (grass, dirt, stone, wall)
4. Paint your level!

Tiles with physics (grass, dirt, stone, wall) will automatically have collision.



