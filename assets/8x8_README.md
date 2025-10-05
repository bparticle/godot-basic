# 8x8 Pixel Art Assets for VIC-20 Style Game

## Asset Requirements:
- **Size**: Exactly 8x8 pixels
- **Format**: PNG with transparency
- **Colors**: Use VIC-20 palette only (16 colors)
- **Style**: Pixel perfect, no anti-aliasing

## VIC-20 Color Palette (Exact Aseprite Colors):
```
0: Black        #000000
1: White        #FFFFFF
2: Brown        #A8734A
3: Light Brown  #E9B287
4: Dark Red     #772D26
5: Light Red    #B66862
6: Cyan         #85D4DC
7: Light Cyan   #C5FFFF
8: Purple       #A85FB4
9: Light Purple #E99DF5
10: Green       #559E4A
11: Light Green #92DF87
12: Blue        #42348B
13: Light Blue  #7E70CA
14: Yellow      #BDCC71
15: Light Yellow #FFFFB0
```

## File Structure:
```
assets/
├── characters/
│   ├── player_8x8.png          # Player sprite
│   ├── player_walk_8x8.png     # Walking animation
│   └── enemy_8x8.png           # Enemy sprites
├── tiles/
│   ├── tile_grass_8x8.png      # Grass tile
│   ├── tile_dirt_8x8.png       # Dirt tile
│   ├── tile_stone_8x8.png      # Stone tile
│   └── tile_wall_8x8.png       # Wall tile
└── sprites/
    ├── coin_8x8.png            # Collectibles
    └── powerup_8x8.png         # Power-ups
```

## Creating 8x8 Assets:

### Method 1: Use Pico-8 Palette Script
```gdscript
# Create a simple 8x8 sprite programmatically
var texture = Pico8Palette.create_8x8_sprite(Pico8Palette.BLUE)
```

### Method 2: Pattern-Based Sprites
```gdscript
# Create sprite from pattern
var pattern = [
    "........",
    ".111111.",
    ".1....1.",
    ".1....1.",
    ".1....1.",
    ".1....1.",
    ".111111.",
    "........"
]
var colors = ["0", "1"]  # Black and Dark Blue
var texture = Pico8Palette.create_8x8_pattern(pattern, colors)
```

### Method 3: External Tools
- **Aseprite**: Set canvas to 8x8, use Pico-8 palette
- **Piskel**: Free online tool, good for 8x8 sprites
- **GraphicsGale**: Free Windows tool

## Import Settings in Godot:
1. Select your 8x8 PNG file
2. In Import tab:
   - **Filter**: OFF (Nearest neighbor)
   - **Mipmaps**: OFF
   - **Compress**: Lossless
3. The script will automatically scale 8x8 to 32x32 (4x scale)

## Grid Alignment:
- All positions snap to 8-pixel grid
- Player starts at (16, 16) = grid position (2, 2)
- Tiles are placed at multiples of 8
- Camera follows 8-pixel boundaries
