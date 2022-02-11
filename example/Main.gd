extends Node2D

# godot icon
onready var tile1 = preload("res://example/Tile1.tscn")
# godot icon flipped and modulated pink
onready var tile2 = preload("res://example/Tile2.tscn")
# godot icon modulated brown
onready var tile3 = preload("res://example/Tile3.tscn")


func _ready():
	var tiles = {'one': tile1.instance(), 'two': tile2, 'three': tile3}
	grid = Grid.new(10, 10, tiles)
	add_child(grid)


	# var location = {row = 5, col = 2}
	# var grid_index = grid.location_to_grid_index(location)
	# grid.x.x(grid_index).modulate = Color.red

	grid.rotate(PI/8)

	var rect = grid.get_rect()
	var lower_right_corner = grid.to_global(rect.end)
	# put a tile at the lower right corner
	var t = tile1.instance()
	add_child(t)
	t.position = lower_right_corner



	# test(location)
	# grid.x.x(grid.location_to_grid_index(location)).modulate = Color.green
	# var loc2 = {row=0, col=9}
	# for i in grid.get_area_between(location, loc2):
	# 	grid.x.x(i).modulate = Color.green
	#
	# 
	# print(grid.get_distance_between(location, loc2))
	# print()

	# grid.x.x(grid.location_to_grid_index(location)).modulate = Color.green

	# var diag = grid._get_diagonals(location)

	# for i in grid.falling_diag_lut[grid.g[grid.location_to_grid_index(location)].falling_diag]:
	# 	grid.x.x(i).modulate = Color.green
	# for i in grid.rising_diag_lut[grid.g[grid.location_to_grid_index(location)].rising_diag]:
	# 	grid.x.x(i).modulate = Color.green

# func _input(event):
# 	var temp = location.duplicate()
# 	var yep = false
# 	if event.is_action_pressed('ui_right'):
# 		location.col += 1
# 		yep = true
# 	if event.is_action_pressed('ui_left'):
# 		location.col -= 1
# 		yep = true
# 	if event.is_action_pressed('ui_up'):
# 		location.row -= 1
# 		yep = true
# 	if event.is_action_pressed('ui_down'):
# 		location.row += 1
# 		yep = true
# 	if (location.col >= grid.col_max or location.row >= grid.row_max
# 	or location.col < 0 or location.row < 0):
# 		location = temp
# 	if yep:
# 		test(location)
# 		grid.x.x(grid.location_to_grid_index(location)).modulate = Color.green
#
# func test(location):
# 	var color = Color.white
# 	for i in grid.g.size():
# 		grid.x.x(i).modulate = color
# 	var area = grid.get_all_neighbors(location, -1, true)
# 	for i in area:
# 		color += Color(0.02, 0.02, 0.02)
# 		for j in i:
# 			grid.x.x(j).modulate = color
# grid.x.x(grid.rising_diag_lut[grid.g[grid.location_to_grid_index(location)].rising_diag][grid.g[grid.location_to_grid_index(location)].falling_diag]).modulate = Color.red



	# get Neighbors in 4 cardinal directions
	# for i in grid.get4DirectionNeighbors(location, 20):
	# 	grid.x.x(i).modulate = Color.green
	# for i in diag.rising_diag:
	# 	grid.x.x(i).modulate = Color.green
	# for i in diag.falling_diag:
	# 	grid.x.x(i).modulate = Color.green
	#
	# # operate on the whole grid at once
	# grid.modulate = Color.gray
	# grid.rotate(PI/8)
	#
	# # access individual tiles by their index
	# grid.x.x(5).modulate = Color.red
	#
	# # use the static row/column index to access tiles by row/column
	# var row = 2
	# var column = 7
	#
	# grid.x.x(grid.row_lut[row+1][column]).modulate = Color.blue
	# grid.x.x(grid.col_lut[column][row]).modulate = Color.blue
	#
	# # or whole rows/column
	# column = 8
	#
	# for i in grid.col_lut[column]:
	# 	grid.x.x(i).modulate = Color.yellow
	#
	# # get a tiles row/column
	# # this works because our Tile1 and Tile2 scenes are of class 'Tile', see Tile.gd
	# var index := 25
	# # print(grid.g[index].row) # -> 1
	# # print(grid.g[index].col) # -> 5
	#
	# # and do something with it, like hide all of that row
	# grid.x.remove_scenes(grid.row_lut[grid.g[index].row], {method_remove=grid.x.HIDDEN})
	#
	# # switch tile (scene) in place
	# index = grid.col_lut[column][row]
	# grid.change_tile({grid_index = index}, {state = 1, tile_key = 'two'})
	# grid.change_tile({grid_index = index-1}, {grid_index = index+1, leave_behind='three'})
	# # grid.switch_tile({grid_index=index}, 'two')
	# grid.x.x(index).modulate = Color.green
	# # tile in column 8 (yellow column) gets switched to the other scene
	# # note that its not yellow any longer, because the previous scene got freed,
	# # a new scene is created at its position and the modulation was not carried over
	#
	# # use grid.get_rect() to get a grid local Rect2
	# # this could be used to intersect with the whole grid
	# var rect = grid.get_rect()
	# var lower_right_corner = grid.to_global(rect.end)
	# # put a tile at the lower right corner
	# var t = load("res://example/Sprite.tscn").instance()
	# add_child(t)
	# t.position = lower_right_corner
	#
	#
	#
	# # define a pattern of tiles that is repeated through the whole grid
	# # the numbers are the indices in the tiles array
	# # the matrix does not have to be square
	# var pattern = [
	# 	['one', 'two', 'one'],
	# 	['two', 'three', 'two'],
	# 	['one', 'two', 'one'],
	# ]
	#
	# # make a new grid using that pattern
	# var grid2 = Grid.new(5, 20, tiles, pattern)
	# add_child(grid2)
	# grid2.rotate(-PI/2+PI/8)
	# var upper_right_corner = grid.to_global(Vector2(rect.end.x,rect.position.y))
	# grid2.translate(upper_right_corner)
	#
	# # define a relative propability distribution for the tiles
	# # here Tile1 1/2 part : Tile2 5 parts : Tile3 2 parts
	# # the tiles are then randomly distributed with the specified relative probability
	# # the numbers are the indices in the tiles array
	# var distribution = {'one': 0.5, 'two':5, 'three':2}
	# var grid3 = Grid.new(10, 10, tiles, [], distribution)
	# add_child(grid3)
	# grid3.rotate(-PI/2+PI/8)
	# var half_height = grid.to_global(Vector2(rect.position.x,rect.end.y/2 + grid.tile_y))
	# grid3.translate(upper_right_corner + half_height)
	#
	# # you can access the tile_key of an individual tile
	# # print(grid2.g[0].tile_key) -> one
	# # remember grid2 is the grid with the cross pattern
	#
	# # but this can be usefull when adding tiles to groups
	# for i in grid.col_lut[5]:
	# 	grid.x.x(i).add_to_group('column_five')
	# # for tile in get_tree().get_nodes_in_group('column_five'):
	# # 	print(tile.index) # -> prints all indices of column 5
	#
	# print(grid2.get_tiles_by_tile_key('three'))
	#
