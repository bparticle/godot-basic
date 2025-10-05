#!/usr/bin/env python3
"""
Create basic 8x8 tile sprites using a simple approach
"""

import os

# Create the tiles directory
os.makedirs('assets/tiles', exist_ok=True)

# Create simple tile files (we'll use Godot to create the actual sprites)
tile_files = [
    'grass_8x8.png',
    'dirt_8x8.png', 
    'stone_8x8.png',
    'wall_8x8.png',
    'water_8x8.png',
    'air_8x8.png'
]

print("Creating tile file placeholders...")
for tile_file in tile_files:
    file_path = f'assets/tiles/{tile_file}'
    # Create empty file as placeholder
    with open(file_path, 'w') as f:
        f.write('# Placeholder for 8x8 tile sprite')
    print(f"Created placeholder: {file_path}")

print("\n✅ Tile placeholders created!")
print("📁 Now create the actual 8x8 PNG sprites in Aseprite")
print("🎨 Use the VIC-20 palette colors from your hex file")


