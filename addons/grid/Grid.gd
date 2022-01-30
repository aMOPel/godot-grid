extends Node2D

class_name Grid, "res://addons/grid/grid16.png"

var row_max: int
var col_max: int

var pattern: Array
var distribution 

var size: int
var tile_x: float
var tile_y: float

# to group indices of rows and of columns together since they are constant
var row_lut: Array
var col_lut: Array

var flat_coordinates: Array

var map: Array
var tiles:= {}
var method_add: int
var method_remove: int

onready var x := XScene.new(self, false)


func _ready():
	if tile_x < 0 or tile_y < 0:
		var t = tiles.values()[0].instance()
		var cell_rect = t.get_rect()
		t.free()
		tile_x = abs(cell_rect.position.x) + abs(cell_rect.end.x)
		tile_y = abs(cell_rect.position.y) + abs(cell_rect.end.y)
		# just to check the other tile sizes
		for key in tiles:
			t = tiles[key].instance()
			cell_rect = t.get_rect()
			t.free()
			var _tile_x = abs(cell_rect.position.x) + abs(cell_rect.end.x)
			var _tile_y = abs(cell_rect.position.y) + abs(cell_rect.end.y)
			assert(
				tile_x == _tile_x and tile_y == _tile_y,
				'all tiles must be of the same dimensions'
			)

	col_lut = []
	row_lut = []
	flat_coordinates = []
	for i in row_max:
		row_lut.append([])
	for i in col_max:
		col_lut.append([])

	var y_coord = 0
	for i in row_max:
		var x_coord = 0
		for j in col_max:
			row_lut[i].append(flat_coordinates.size())
			col_lut[j].append(flat_coordinates.size())
			flat_coordinates.append(Vector2(x_coord, y_coord))
			x_coord += tile_x
		y_coord += tile_y

	x.defaults.method_add = method_add

	map = []
	if pattern:
		map = make_map_for_pattern(pattern)
	elif distribution:
		map = make_map_for_distribution(distribution)
	else:
		for i in size:
			map.append(tiles.keys()[0])

	for i in size:
		x.add_scene(tiles[map[i]])
		x.x(i).tile_key = map[i]
		x.x(i).position += flat_coordinates[i]
		x.x(i).grid_index = i




# instance a grid with `_col_max` columns and `_row_max` rows. By default all tiles are visible and are set to `_tiles`[0]
# Specify `_pattern` of tiles that is repeated through the whole grid. The numbers are the indices in the `_tiles` array
# var pattern = [
# 	[0, 1, 0, 1],
# 	[1, 2, 1, 2],
# 	[0, 1, 0, 1],
# ]
# Specify relative probability `_distribution` of tiles by which they get randomly distributed through the grid.
# var distribution = [0.5, 5, 2]
# You can only specify either `_pattern` or `_distribution`
# if `_tile_x` and `_tile_y` remain -1
#		The size of the icon is inferred, also it gets checked if all tiles (sprite textures) have the same dimensions
# else
#		`_tile_x` and `_tile_y` are assumed to be correct
func _init(
	_col_max: int,
	_row_max: int,
	_tiles,
	_pattern := [],
	_distribution = {},
	_tile_x := -1,
	_tile_y := -1,
	_method_add := 0,
	_method_remove := 3
):
	col_max = _col_max
	row_max = _row_max

	size = _col_max * _row_max

	tiles = Dictionary(_tiles)

	assert(
		not (_pattern and _distribution),
		'you can only define either pattern or distribution'
	)
	pattern = _pattern
	distribution = _distribution

	tile_x = _tile_x
	tile_y = _tile_y
	method_add = _method_add
	method_remove = _method_remove


# Switch the tile at grid_index to the tile of tile_key. The old tile is freed, no properties are kept, except the position.
func switch_tile_to(
	grid_index: int, tile_key, _method_to := -1, _method_from := -1
) -> void:
	x.x_add_scene(
		tiles[tile_key],
		grid_index,
		grid_index,
		method_add if _method_to < 0 else _method_to,
		method_remove if _method_from < 0 else _method_from
	)
	x.x(grid_index).position = flat_coordinates[grid_index]
	x.x(grid_index).grid_index = grid_index
	x.x(grid_index).tile_key = tile_key


# Makes an array of size grid.size, that maps tile indices from grid.tiles to grid indices according to grid.pattern
func make_map_for_pattern(_pattern: Array) -> Array:
	var map := []
	for i in size:
		map.append(0)

	for i in _pattern.size():
		var row = _pattern[i]
		for j in row.size():
			assert(
				_pattern[i][j] in tiles,
				(
					'the int: "'
					+ String(_pattern[i][j])
					+ '" in the _pattern does not correspond to a tile in tiles'
				)
			)
			var cols = []
			var rows = []
			for c in col_max:
				if c % row.size() == j:
					cols.append(c)
			for r in row_max:
				if r % _pattern.size() == i:
					rows.append(r)
			for c in cols:
				for r in rows:
					map[col_lut[c][r]] = _pattern[i][j]
	return map


# Makes an array of size grid.size, that maps tile indices from grid.tiles to grid indices, randomly distributed according to grid.distribution
func make_map_for_distribution(_distribution) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var MAX_INT := 4294967295

	var map := []
	for i in size:
		map.append(0)

	var d = Dictionary(_distribution)

	var fractions := {}
	var sum := 0.0
	for i in d.values():
		sum += i
	for i in d:
		fractions[i] = d[i] / sum

	for i in size:
		var rf := rng.randi()
		var not_count := 0
		for j in fractions:
			if rf <= floor(MAX_INT * fractions[j]):
				map[i] = j
				break
			else:
				not_count += 1
		if not_count == fractions.size():
			map[i] = d.keys()[-1]

	return map


func get_tiles_by_tile_key(_tile_key) -> Array:
	var ts = []
	for i in size:
		if _tile_key == x.x(i).tile_key:
			ts.append(i)
	return ts


# Create a Rect2 encompassing the whole grid. It uses coordinates local to the grid.
func get_rect() -> Rect2:
	var last_tile = x.x(size - 1)
	return Rect2(
		position,
		(
			last_tile.get_relative_transform_to_parent(self).origin
			+ last_tile.get_rect().end
		)
	)
