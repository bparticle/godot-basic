#!/usr/bin/env python3
"""
Create sample 8x8 pixel art assets for VIC-20 style game
This script creates PNG files with the exact VIC-20 colors
"""

from PIL import Image
import os

# VIC-20 Color Palette (RGB values)
VIC20_COLORS = {
    0: (0, 0, 0),           # black
    1: (255, 255, 255),     # white
    2: (136, 0, 0),         # red
    3: (170, 255, 238),     # cyan
    4: (136, 68, 68),       # purple
    5: (0, 204, 85),        # green
    6: (0, 0, 136),         # blue
    7: (238, 238, 119),     # yellow
    8: (221, 136, 85),      # orange
    9: (102, 68, 0),        # brown
    10: (255, 119, 119),    # light red
    11: (51, 51, 51),       # dark gray
    12: (119, 119, 119),    # medium gray
    13: (170, 255, 102),    # light green
    14: (0, 136, 255),      # light blue
    15: (187, 85, 85)       # light purple
}

def create_8x8_sprite(width, height, pixels, filename):
    """Create an 8x8 PNG sprite"""
    img = Image.new('RGB', (width, height))
    
    for y in range(height):
        for x in range(width):
            color_index = pixels[y][x]
            if color_index in VIC20_COLORS:
                img.putpixel((x, y), VIC20_COLORS[color_index])
            else:
                img.putpixel((x, y), VIC20_COLORS[0])  # Default to black
    
    # Create assets directory if it doesn't exist
    os.makedirs('assets/characters', exist_ok=True)
    os.makedirs('assets/tiles', exist_ok=True)
    
    img.save(filename)
    print(f"Created: {filename}")

# Create sample player sprite (8x8)
player_pixels = [
    [0, 0, 0, 0, 0, 0, 0, 0],  # Row 0
    [0, 0, 8, 8, 8, 8, 0, 0],  # Row 1 - Orange head
    [0, 0, 8, 8, 8, 8, 0, 0],  # Row 2 - Orange head
    [0, 0, 6, 6, 6, 6, 0, 0],  # Row 3 - Blue body
    [0, 0, 6, 6, 6, 6, 0, 0],  # Row 4 - Blue body
    [0, 0, 6, 6, 6, 6, 0, 0],  # Row 5 - Blue body
    [0, 0, 9, 9, 9, 9, 0, 0],  # Row 6 - Brown legs
    [0, 0, 9, 9, 9, 9, 0, 0]   # Row 7 - Brown legs
]

create_8x8_sprite(8, 8, player_pixels, 'assets/characters/player_8x8.png')

# Create sample tiles
# Grass tile
grass_pixels = [
    [5, 5, 5, 5, 5, 5, 5, 5],  # Green base
    [13, 5, 13, 5, 13, 5, 13, 5],  # Light green pattern
    [5, 5, 5, 5, 5, 5, 5, 5],
    [13, 5, 13, 5, 13, 5, 13, 5],
    [5, 5, 5, 5, 5, 5, 5, 5],
    [13, 5, 13, 5, 13, 5, 13, 5],
    [5, 5, 5, 5, 5, 5, 5, 5],
    [13, 5, 13, 5, 13, 5, 13, 5]
]

create_8x8_sprite(8, 8, grass_pixels, 'assets/tiles/tile_grass_8x8.png')

# Dirt tile
dirt_pixels = [
    [9, 9, 9, 9, 9, 9, 9, 9],  # Brown base
    [9, 11, 9, 11, 9, 11, 9, 11],  # Dark gray pattern
    [9, 9, 9, 9, 9, 9, 9, 9],
    [9, 11, 9, 11, 9, 11, 9, 11],
    [9, 9, 9, 9, 9, 9, 9, 9],
    [9, 11, 9, 11, 9, 11, 9, 11],
    [9, 9, 9, 9, 9, 9, 9, 9],
    [9, 11, 9, 11, 9, 11, 9, 11]
]

create_8x8_sprite(8, 8, dirt_pixels, 'assets/tiles/tile_dirt_8x8.png')

# Stone tile
stone_pixels = [
    [12, 12, 12, 12, 12, 12, 12, 12],  # Medium gray base
    [12, 11, 12, 11, 12, 11, 12, 11],  # Dark gray pattern
    [12, 12, 12, 12, 12, 12, 12, 12],
    [12, 11, 12, 11, 12, 11, 12, 11],
    [12, 12, 12, 12, 12, 12, 12, 12],
    [12, 11, 12, 11, 12, 11, 12, 11],
    [12, 12, 12, 12, 12, 12, 12, 12],
    [12, 11, 12, 11, 12, 11, 12, 11]
]

create_8x8_sprite(8, 8, stone_pixels, 'assets/tiles/tile_stone_8x8.png')

# Wall tile
wall_pixels = [
    [11, 11, 11, 11, 11, 11, 11, 11],  # Dark gray base
    [11, 12, 11, 12, 11, 12, 11, 12],  # Medium gray pattern
    [11, 11, 11, 11, 11, 11, 11, 11],
    [11, 12, 11, 12, 11, 12, 11, 12],
    [11, 11, 11, 11, 11, 11, 11, 11],
    [11, 12, 11, 12, 11, 12, 11, 12],
    [11, 11, 11, 11, 11, 11, 11, 11],
    [11, 12, 11, 12, 11, 12, 11, 12]
]

create_8x8_sprite(8, 8, wall_pixels, 'assets/tiles/tile_wall_8x8.png')

print("\n✅ Sample 8x8 pixel art assets created!")
print("📁 Check the assets/ folder for your new sprites")
print("🎨 You can now replace these with your own pixel art")


