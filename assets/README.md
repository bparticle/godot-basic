# Pixel Art Asset Guidelines

## Asset Preparation for Godot

### Image Requirements:
- **Format**: PNG with transparency support
- **Size**: Power of 2 dimensions (16x16, 32x32, 64x64, etc.)
- **Color Depth**: 32-bit RGBA
- **Style**: Consistent pixel art style

### Folder Structure:
- `sprites/` - Individual game objects (player, enemies, items)
- `tiles/` - Tile-based assets for level building
- `characters/` - Character sprites and animations

### Import Settings:
All pixel art assets should be imported with:
- **Filter**: OFF (Nearest neighbor)
- **Mipmaps**: OFF
- **Compress**: Lossless

### Recommended Tools:
- **Aseprite** (paid, excellent for pixel art)
- **GIMP** (free, with pixel art plugins)
- **Piskel** (free, web-based)
- **GraphicsGale** (free, Windows)

### Asset Naming Convention:
- `player_idle.png`
- `player_walk_01.png`, `player_walk_02.png`
- `tile_grass.png`
- `tile_dirt.png`
- `enemy_slime.png`



