extends Node2D

# godot icon
onready var tile1 = preload("res://tutorial/Tile1.tscn")
# godot icon flipped and modulated pink
onready var tile2 = preload("res://tutorial/Tile2.tscn")
# godot icon modulated brown
onready var tile3 = preload("res://tutorial/Tile3.tscn")

var grid: Grid
var location = Vector2(5, 5)

func _ready():
	var tiles = {'one': tile1.instance(), 'two': tile2, 'three': tile3}
	grid = Grid.new(Vector2(200, 200), tiles)
	add_child(grid)

	test()
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

func _input(event):
	var temp = location
	var yep = false
	if event.is_action_pressed('ui_right'):
		location.x += 1
		yep = true
	if event.is_action_pressed('ui_left'):
		location.x -= 1
		yep = true
	if event.is_action_pressed('ui_up'):
		location.y -= 1
		yep = true
	if event.is_action_pressed('ui_down'):
		location.y += 1
		yep = true
	if (location.x >= grid.dimensions.x or location.y >= grid.dimensions.y
	or location.x < 0 or location.y < 0):
		location = temp
	if yep:
		test()
		grid.x.x(grid.to_location(location).grid_index).modulate = Color.green

func test():
	var color = Color.white
	for i in grid.g.size():
		grid.x.x(i).modulate = color
	var area = grid.get_all_neighbors(location, -1, true)
	for i in area:
		color += Color(0.02, 0.02, 0.02)
		for j in i:
			grid.x.x(j).modulate = color
