extends Node2D

# godot icon
onready var tile1 = preload("res://tutorial/Tile1.tscn")
# godot icon flipped and modulated pink
onready var tile2 = preload("res://tutorial/Tile2.tscn")
# godot icon modulated brown
onready var tile3 = preload("res://tutorial/Tile3.tscn")

var grid
var cgrid
var clustered_grid: ClusteredGrid
var location = Vector2(5, 5)
var grid_rect
var t

func _ready():
	var tiles = {'one': tile1, 'two': tile2, 'three': tile3}

	grid = Grid.new(Vector2(200, 200), tiles)
	add_child(grid)

	# clustered_grid = ClusteredGrid.new(Vector2(50, 50), tiles, {enable_cluster_area=true,cluster_dimensions=Vector2(5,5)})
	# add_child(clustered_grid)
	# grid = clustered_grid.grid
	# cgrid = clustered_grid.cluster_grid
	# clustered_grid.rotate(PI/8)
	# 
	t = tile2.instance()
	add_child(t)
	t.position = Vector2(250,500)
	t.scale = Vector2(10,10)
	t.rotate(-PI/8)
	
	# for i in cgrid.size:
	# 	for j in grid.cluster_lut[i]:
	# 		if i % 2 == 0:
	# 			grid.x.x(j).modulate = Color.green
	

	# cgrid.get_child(0).connect('area_shape_entered', self, '_on_cluster_shape_entered')
	# cgrid.get_child(0).connect('area_shape_exited', self, '_on_cluster_shape_exited')


# func _on_cluster_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
# 	if area == t.get_child(0):
# 		grid.x.remove_scenes(grid.cluster_lut[local_shape_index], {method_remove=XScene.STOPPED})
# 	
# func _on_cluster_shape_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
# 	if area == t.get_child(0):
# 		grid.x.show_scenes(grid.cluster_lut[local_shape_index])

# func _ready():
# 	var tiles = {'one': tile1.instance(), 'two': tile2, 'three': tile3}
# 	grid = Grid.new(Vector2(4, 4), tiles, {enable_area=true,cluster_dimensions=Vector2(2,2)})
# 	add_child(grid)
# 	# grid.rotate(PI/8)
#
# 	# t = tile2.instance()
# 	# add_child(t)
# 	# t.position = Vector2(150,100)
# 	# t.scale = Vector2(10,10)
# 	# t.rotate(PI/8)
#
# 	# for i in grid.cluster_lut.size():
# 	# 	for j in grid.cluster_lut[i]:
# 	# 		if i % 2 == 0:
# 	# 			grid.switch_tile(j, 'two')
# 	grid.show_behind_parent = true
#
#

func _process(delta):
	$Camera2D.position = t.position
	# for i in cgrid.size:
	# 	if cgrid.x.x(i).overlaps_area(t.get_child(0)):
	# 		var area = cgrid.x.x(i)
	# 		var global_area = PoolVector2Array([])
	# 		for j in area.shape_owner_get_shape(0,0).points:
	# 			global_area.push_back(cgrid.to_global(j))
	# 		areas.push_back(global_area)


# var areas: Array

func poly_to_global(node, poly):
	var global_poly = PoolVector2Array([])
	for i in poly:
		global_poly.append(node.to_global(i))
	return global_poly

func _draw():
	# var global_poly = []
	# for i in grid.area.shape_owner_get_shape(0,0).points:
	# 	global_poly.append(grid.to_global(i))
	var red = Color(1,0,0,0.5)
	var green = Color(0,1,0,0.5)
	var reds = [red,red,red,red,]
	var greens = [green,green,green,green,]

	# for i in cgrid.size:
	# 	var poly = poly_to_global(clustered_grid, cgrid.x.x(i).polygon)
	# 	if i % 2 == 0:
	# 		draw_polygon(poly, greens)
	# 	else:
	# 		draw_polygon(poly, reds)

	# for i in areas:
	# 	draw_polygon(i, reds)
	# 	print(i)

	# var global_area = PoolVector2Array([])
	# for j in t.get_child(0).shape_owner_get_shape(0,0).points:
	# 	global_area.push_back(t.to_global(j))
	# draw_polygon(global_area, greens)


	# draw_polygon(global_poly, colors)
#
# 	var cluster_poly
# 	for i in grid.cluster_lut.size():
# 		cluster_poly = grid._get_polygon_of_cluster(i)
# 		# print(cluster_poly)
# 		if i % 2 == 0:
# 			draw_polygon(cluster_poly, reds)
# 		else:
# 			draw_polygon(cluster_poly, greens)
#
# 		# if purple_rect.intersects(cluster_rect):
# 		# 	grid.x.remove_scenes(grid.cluster_lut[i], {method_remove=XScene.STOPPED})

	# test()
	# grid.x.x(grid.location_to_grid_index(location)).modulate = Color.green
	# var loc2 = {row=0, col=9}
	# for i in grid.get_area_between(location, loc2):
	# 	grid.x.x(i).modulate = Color.green
	
	 
	# print(grid.get_distance_between(location, loc2))
	# print()

	# grid.x.x(grid.location_to_grid_index(location)).modulate = Color.green

	# var diag = grid._get_diagonals(location)

	# for i in grid.falling_diag_lut[grid.g[grid.location_to_grid_index(location)].falling_diag]:
	# 	grid.x.x(i).modulate = Color.green
	# for i in grid.rising_diag_lut[grid.g[grid.location_to_grid_index(location)].rising_diag]:
	# 	grid.x.x(i).modulate = Color.green

func _input(event):
	var step = 20
	if event.is_action_pressed('ui_right', true):
		t.position.x += step
	if event.is_action_pressed('ui_left', true):
		t.position.x -= step
	if event.is_action_pressed('ui_up', true):
		t.position.y -= step
	if event.is_action_pressed('ui_down', true):
		t.position.y += step

# func test():
# 	var color = Color.white
# 	for i in grid.g.size():
# 		grid.x.x(i).modulate = color
# 	var area = grid.get_all_neighbors(location, -1, true)
# 	for i in area:
# 		color += Color(0.02, 0.02, 0.02)
# 		for j in i:
# 			grid.x.x(j).modulate = color
