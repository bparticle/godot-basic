extends Node2D

# Debug script to help troubleshoot TileMapLayer painting

func _ready():
	print("=== TileMapLayer Debug Info ===")
	
	# Get the TileMapLayer node
	var tilemap = get_node("TileMapLayer")
	if tilemap:
		print("✅ TileMapLayer found")
		print("TileSet: ", tilemap.tile_set)
		print("TileMapLayer type: ", tilemap.get_class())
		
		# Check if tileset has sources
		if tilemap.tile_set:
			print("TileSet sources: ", tilemap.tile_set.get_source_count())
			for i in range(tilemap.tile_set.get_source_count()):
				var source = tilemap.tile_set.get_source(i)
				print("Source ", i, ": ", source)
				if source:
					print("  Source type: ", source.get_class())
		else:
			print("❌ No TileSet assigned!")
	else:
		print("❌ TileMapLayer not found!")
	
	print("=== Debug Complete ===")
	print("Try these steps:")
	print("1. Make sure TileMapLayer is selected")
	print("2. Check that TileSet is assigned")
	print("3. Try the TileMap tool in the toolbar")
	print("4. Make sure you're in 2D view")
	print("5. Check if tiles are visible in the tileset editor")
