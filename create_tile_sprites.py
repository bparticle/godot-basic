#!/usr/bin/env python3
"""
Create 8x8 tile sprites for VIC-20 style game
This creates the basic tiles you need for level design
"""

from PIL import Image
import os

# VIC-20 Color Palette (exact Aseprite colors)
VIC20_COLORS = {
    0: (0, 0, 0),           # 000000 - black
    1: (255, 255, 255),     # ffffff - white
    2: (168, 115, 74),      # a8734a - brown
    3: (233, 178, 135),     # e9b287 - light brown
    4: (119, 45, 38),       # 772d26 - dark red
    5: (182, 104, 98),      # b66862 - light red
    6: (133, 212, 220),     # 85d4dc - cyan
    7: (197, 255, 255),     # c5ffff - light cyan
    8: (168, 95, 180),      # a85fb4 - purple
    9: (233, 157, 245),     # e99df5 - light purple
    10: (85, 158, 74),      # 559e4a - green
    11: (146, 223, 135),    # 92df87 - light green
    12: (66, 52, 139),      # 42348b - blue
    13: (126, 112, 202),    # 7e70ca - light blue
    14: (189, 204, 113),    # bdcc71 - yellow
    15: (255, 255, 176)     # ffffb0 - light yellow
}

def create_8x8_tile(width, height, pixels, filename):
    """Create an 8x8 PNG tile"""
    img = Image.new('RGB', (width, height))
    
    for y in range(height):
        for x in range(width):
            color_index = pixels[y][x]
            if color_index in VIC20_COLORS:
                img.putpixel((x, y), VIC20_COLORS[color_index])
            else:
                img.putpixel((x, y), VIC20_COLORS[0])  # Default to black
    
    # Create assets directory if it doesn't exist
    os.makedirs('assets/tiles', exist_ok=True)
    
    img.save(filename)
    print(f"Created: {filename}")

# Create basic tiles for level design

# Grass tile (solid green)
grass_pixels = [
    [10, 10, 10, 10, 10, 10, 10, 10],
    [10, 10, 10, 10, 10, 10, 10, 10],
    [10, 10, 10, 10, 10, 10, 10, 10],
    [10, 10, 10, 10, 10, 10, 10, 10],
    [10, 10, 10, 10, 10, 10, 10, 10],
    [10, 10, 10, 10, 10, 10, 10, 10],
    [10, 10, 10, 10, 10, 10, 10, 10],
    [10, 10, 10, 10, 10, 10, 10, 10]
]
create_8x8_tile(8, 8, grass_pixels, 'assets/tiles/grass_8x8.png')

# Dirt tile (solid brown)
dirt_pixels = [
    [2, 2, 2, 2, 2, 2, 2, 2],
    [2, 2, 2, 2, 2, 2, 2, 2],
    [2, 2, 2, 2, 2, 2, 2, 2],
    [2, 2, 2, 2, 2, 2, 2, 2],
    [2, 2, 2, 2, 2, 2, 2, 2],
    [2, 2, 2, 2, 2, 2, 2, 2],
    [2, 2, 2, 2, 2, 2, 2, 2],
    [2, 2, 2, 2, 2, 2, 2, 2]
]
create_8x8_tile(8, 8, dirt_pixels, 'assets/tiles/dirt_8x8.png')

# Stone tile (solid cyan)
stone_pixels = [
    [6, 6, 6, 6, 6, 6, 6, 6],
    [6, 6, 6, 6, 6, 6, 6, 6],
    [6, 6, 6, 6, 6, 6, 6, 6],
    [6, 6, 6, 6, 6, 6, 6, 6],
    [6, 6, 6, 6, 6, 6, 6, 6],
    [6, 6, 6, 6, 6, 6, 6, 6],
    [6, 6, 6, 6, 6, 6, 6, 6],
    [6, 6, 6, 6, 6, 6, 6, 6]
]
create_8x8_tile(8, 8, stone_pixels, 'assets/tiles/stone_8x8.png')

# Wall tile (solid blue)
wall_pixels = [
    [12, 12, 12, 12, 12, 12, 12, 12],
    [12, 12, 12, 12, 12, 12, 12, 12],
    [12, 12, 12, 12, 12, 12, 12, 12],
    [12, 12, 12, 12, 12, 12, 12, 12],
    [12, 12, 12, 12, 12, 12, 12, 12],
    [12, 12, 12, 12, 12, 12, 12, 12],
    [12, 12, 12, 12, 12, 12, 12, 12],
    [12, 12, 12, 12, 12, 12, 12, 12]
]
create_8x8_tile(8, 8, wall_pixels, 'assets/tiles/wall_8x8.png')

# Water tile (solid light cyan)
water_pixels = [
    [7, 7, 7, 7, 7, 7, 7, 7],
    [7, 7, 7, 7, 7, 7, 7, 7],
    [7, 7, 7, 7, 7, 7, 7, 7],
    [7, 7, 7, 7, 7, 7, 7, 7],
    [7, 7, 7, 7, 7, 7, 7, 7],
    [7, 7, 7, 7, 7, 7, 7, 7],
    [7, 7, 7, 7, 7, 7, 7, 7],
    [7, 7, 7, 7, 7, 7, 7, 7]
]
create_8x8_tile(8, 8, water_pixels, 'assets/tiles/water_8x8.png')

# Air tile (transparent/black)
air_pixels = [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0]
]
create_8x8_tile(8, 8, air_pixels, 'assets/tiles/air_8x8.png')

print("\n✅ Basic 8x8 tiles created!")
print("📁 Check assets/tiles/ for your tile sprites")
print("🎨 You can now use these in Godot's TileMap system")


