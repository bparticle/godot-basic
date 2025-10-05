extends Node2D

# Helper script to fix TileMapLayer grid and tile selection issues

func _ready():
	print("=== TileMapLayer Helper ===")
	
	# Get the TileMapLayer node
	var tilemap = get_node("TileMapLayer")
	if tilemap:
		print("✅ TileMapLayer found")
		
		# Fix grid settings for 8x8 tiles
		tilemap.tile_set.tile_size = Vector2i(8, 8)
		
		# Set up proper grid snapping
		tilemap.tile_set.tile_shape = TileSet.TILE_SHAPE_SQUARE
		tilemap.tile_set.tile_layout = TileSet.TILE_LAYOUT_STACKED
		tilemap.tile_set.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
		tilemap.tile_set.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
		
		print("Grid settings configured for 8x8 tiles")
		print("Tile size: ", tilemap.tile_set.tile_size)
		print("Tile shape: ", tilemap.tile_set.tile_shape)
		
		# Check tileset sources
		if tilemap.tile_set:
			print("TileSet sources: ", tilemap.tile_set.get_source_count())
			for i in range(tilemap.tile_set.get_source_count()):
				var source = tilemap.tile_set.get_source(i)
				if source:
					print("Source ", i, ": ", source.get_class())
					if source.get_class() == "TileSetAtlasSource":
						print("  Atlas source texture: ", source.texture)
						print("  Texture region size: ", source.texture_region_size)
	else:
		print("❌ TileMapLayer not found!")
	
	print("=== Helper Complete ===")
	print("Tips for tile selection:")
	print("1. In the tileset editor, click on different tiles to select them")
	print("2. Use the 'Select' tool in the tileset editor")
	print("3. Make sure you're in 2D view when painting")
	print("4. Try zooming in/out if tiles don't align properly")


