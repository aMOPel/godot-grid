extends Node2D

# godot icon
onready var tile1 = preload("res://example/Tile1.tscn")
# godot icon flipped and modulated pink
onready var tile2 = preload("res://example/Tile2.tscn")
# godot icon modulated brown
onready var tile3 = preload("res://example/Tile3.tscn")


func _ready():
	var col_max = 20
	var row_max = 20
	# this can also be an array if you dont care about the keys being describtive
	var tiles = {'one': tile1, 'two': tile2, 'three': tile3}
	var grid = Grid.new(col_max, row_max, tiles)
	add_child(grid)

	# operate on the whole grid at once
	grid.modulate = Color.gray
	grid.rotate(PI/8)

	# access individual tiles by their index (using XScene)
	grid.x.x(5).modulate = Color.red

	# use the static row/column index to access tiles by row/column
	var row = 2
	var column = 7

	grid.x.x(grid.row_lut[row+1][column]).modulate = Color.blue
	grid.x.x(grid.col_lut[column][row]).modulate = Color.blue

	# or whole rows/column
	column = 8

	for i in grid.col_lut[column]:
		grid.x.x(i).modulate = Color.yellow

	# get a tiles row/column
	# this works because our Tile1 and Tile2 scenes are of class 'Tile', see Tile.gd
	var index = 25
	# print(grid.x.x(index).row) # -> 1
	# print(grid.x.x(index).column) # -> 5

	# and do something with it, like hide all of that row
	grid.x.remove_scenes(grid.row_lut[grid.x.x(index).row], grid.x.HIDDEN)

	# switch tile (scene) in place
	grid.switch_tile_to(grid.col_lut[column][row], 'two')
	grid.x.x(grid.col_lut[column][row]).modulate = Color.green
	# tile in column 8 (yellow column) gets switched to the other scene 
	# note that its not yellow any longer, because the previous scene got freed,
	# a new scene is created at its position and the modulation was not carried over

	# use grid.get_rect() to get a grid local Rect2
	# this could be used to intersect with the whole grid
	var rect = grid.get_rect()
	var lower_right_corner = grid.to_global(rect.end)
	# put a tile at the lower right corner
	var t = load("res://example/Sprite.tscn").instance()
	add_child(t)
	t.position = lower_right_corner

	

	# define a pattern of tiles that is repeated through the whole grid
	# the numbers are the indices in the tiles array
	# the matrix does not have to be square
	var pattern = [
		['one', 'two', 'one'],
		['two', 'three', 'two'],
		['one', 'two', 'one'],
	]

	# make a new grid using that pattern
	var grid2 = Grid.new(5, 20, tiles, pattern)
	add_child(grid2)
	grid2.rotate(-PI/2+PI/8)
	var upper_right_corner = grid.to_global(Vector2(rect.end.x,rect.position.y))
	grid2.translate(upper_right_corner)

	# define a relative propability distribution for the tiles 
	# here Tile1 1/2 part : Tile2 5 parts : Tile3 2 parts
	# the tiles are then randomly distributed with the specified relative probability
	# the numbers are the indices in the tiles array
	var distribution = {'one': 0.5, 'two':5, 'three':2}
	var grid3 = Grid.new(10, 10, tiles, [], distribution)
	add_child(grid3)
	grid3.rotate(-PI/2+PI/8)
	var half_height = grid.to_global(Vector2(rect.position.x,rect.end.y/2 + grid.tile_y))
	grid3.translate(upper_right_corner + half_height)

	# its possible to access the grid index of an individual tile
	# if you where to access it in another way
	print(grid.get_child(5).grid_index) # -> 4
	# however mind in this example, that 
	# 1. the XScene node is at index 0, so all children are pushed back by 1
	print(grid.get_child(0) is XScene) # -> True
	# 2. when a tile is switched it may be removed from the tree and added anew,
	# so it will be the last child of grid in the tree
	grid.switch_tile_to(4, 'two')
	print(grid.get_child(5).grid_index) # -> 5
	print(grid.get_child(grid.get_child_count()-1).grid_index) # -> 4
	# as you can see this is a little confusing,
	# thats why it's not the recommended method of accessing tiles

	# also you can access the tile_key of an individual tile
	print(grid2.x.x(0).tile_key) 
	# remember grid2 is the grid with the cross pattern

	# but this can be usefull when adding tiles to groups
	for i in grid.col_lut[5]:
		grid.x.x(i).add_to_group('column_five')
	# for tile in get_tree().get_nodes_in_group('column_five'):
	# 	print(tile.index) # -> prints all indices of column 5

	# you can get all tiles with the same tile_key like this
	print(grid2.get_tiles_by_tile_key('three'))

