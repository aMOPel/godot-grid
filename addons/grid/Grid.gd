extends Node2D

class_name Grid, 'res://addons/grid/grid16.png'

# TODO: think about making cols and rows to Vector2.x and .y

# number of rows in the grid
var row_max: int

# number of columns in the grid
var col_max: int

# pattern of `tile_key`s that is applied to the grid \
# setting this variable is expensive as it resets the whole grid
var pattern: Array setget set_pattern

# distribution of `tile_key`s that is applied to the grid \
# can be Array if `tile_key`s are int or dictionary if `tile_key`s are String \
# setting this variable is expensive as it resets the whole grid
var distribution setget set_distribution

# maps `grid_index` to `tile_key` \
# setting this variable is expensive as it resets the whole grid
var map: Array setget set_map

# number of tiles in grid
var size: int

# side length of an individual tile
var tile_x: float
# the length of the tile's y side
var tile_y: float

# groups indices of rows and of columns together for easy access, since they are constant \
# Array of Arrays containing `grid_indices`
var row_lut: Array
var col_lut: Array

# groups indices of rising and falling diagonals together for easy access, since they are constant
# Array of Arrays containing `grid_indices`
var falling_diag_lut: Array
var rising_diag_lut: Array

# holds information for all tiles in the grid \
# `g` at `grid_index` is `{position: Vector2, tile_key: int/string, row: int, col: int}`
var g: Array setget _dont_set

# keys are `tile_key`, values are Node/PackedScene
var tiles := {}

# defaults for `XScene.defaults`, only set once in `_ready()`
var args: Dictionary setget _dont_set

# instance of `XScene`
var x: XScene


func _dont_set(a) -> void:
	assert(false, 'Grid: do not set g property manually')


func set_pattern(new: Array) -> void:
	pattern = new
	self.map = make_map_for_pattern(pattern)


func set_distribution(new) -> void:
	distribution = new
	self.map = make_map_for_distribution(distribution)


func set_map(new: Array) -> void:
	map = new
	for i in size:
		switch_tile({grid_index = i}, map[i])


func _ready():
	x = XScene.new(self, false, args)
	# if tile_x and tile_y are not given on init, they are inferred from Sprite.get_rect() in tiles[0]
	if tile_x < 0 or tile_y < 0:
		var t = x.to_node(tiles.values()[0])
		var sprite = _find_sprite(t)
		assert(
			sprite != null,
			'The Grid tile size is unknown. tile_x and tile_y were not given on init and tiles[0] doesn\'t contain a Sprite'
		)
		var cell_rect = sprite.get_rect()
		t.free()
		tile_x = abs(cell_rect.position.x) + abs(cell_rect.end.x)
		tile_y = abs(cell_rect.position.y) + abs(cell_rect.end.y)

	# row/col lut
	col_lut = []
	row_lut = []
	g = []
	for i in row_max:
		row_lut.push_back([])
	for i in col_max:
		col_lut.push_back([])

	var y_coord = 0
	for i in row_max:
		var x_coord = 0
		for j in col_max:
			row_lut[i].push_back(g.size())
			col_lut[j].push_back(g.size())
			g.push_back(
				{position = Vector2(x_coord, y_coord), row = i, col = j}
			)
			x_coord += tile_x
		y_coord += tile_y

	# diag lut
	var inverted_col_0 = col_lut[0].duplicate()
	inverted_col_0.invert()
	inverted_col_0.pop_back()
	var row_0 = row_lut[0]
	var col_last = col_lut[-1].duplicate()
	col_last.pop_front()

	rising_diag_lut = []
	falling_diag_lut = []
	var temp: Array

	for i in inverted_col_0:
		temp = []
		temp.append(i)
		temp.append_array(
			_get_diagonals({grid_index = i}, {rising_diag = false}).falling_diag
		)
		for j in temp:
			g[j].falling_diag = falling_diag_lut.size()
		falling_diag_lut.push_back(temp)

	for i in row_0:
		temp = []
		temp.append(i)
		temp.append_array(
			_get_diagonals({grid_index = i}, {rising_diag = false}).falling_diag
		)
		for j in temp:
			g[j].falling_diag = falling_diag_lut.size()
		falling_diag_lut.push_back(temp)

		temp = []
		temp.append(i)
		temp.append_array(
			_get_diagonals({grid_index = i}, {falling_diag = false}).rising_diag
		)
		for j in temp:
			g[j].rising_diag = rising_diag_lut.size()
		rising_diag_lut.push_back(temp)

	for i in col_last:
		temp = []
		temp.append(i)
		temp.append_array(
			_get_diagonals({grid_index = i}, {falling_diag = false}).rising_diag
		)
		for j in temp:
			g[j].rising_diag = rising_diag_lut.size()
		rising_diag_lut.push_back(temp)

	# init
	map = []
	if pattern:
		map = make_map_for_pattern(pattern)
	elif distribution:
		map = make_map_for_distribution(distribution)
	else:
		for i in size:
			map.push_back(tiles.keys()[0])

	for i in size:
		x.add_scene(tiles[map[i]], i)
		x.x(i).position += g[i].position
		g[i].tile_key = map[i]


# instance a grid with `_col_max` columns and `_row_max` rows. By default all tiles are visible and are set to the first tile in `_tiles` \
# Specify `_pattern` of tiles. A matrix of `tile_key`s that is repeated through the whole grid. \
# Specify relative probability `_distribution` of tiles by which they get randomly distributed through the grid. Can be Array or Dictionary. \
# You can only specify either `_pattern` or `_distribution` \
# `if _tile_x and _tile_y == -1`: \
#		The size of the icon is inferred \
# `else`: \
#		It's up to you to assure that `_tile_x` and `_tile_y` are correct \
# `args` are send through to `XScene.new()`, see XScene for documentation
func _init(
	_col_max: int,
	_row_max: int,
	_tiles,
	_pattern := [],
	_distribution = {},
	_tile_x := -1,
	_tile_y := -1,
	_args := {}
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

	args = _args
	args.count_start = 0


# `location` can be `grid_index: int` or `{grid_index: int}` or `{row: int, col: int}` \
# `grid_index` takes precedence over row/col \
# it returns the corresponding `grid_index` as int
func location_to_grid_index(location) -> int:
	if location is int:
		assert(location < size)
		return location
	if location is Dictionary:
		if 'grid_index' in location:
			assert(location.grid_index < size)
			return location.grid_index
		elif 'row' in location and 'col' in location:
			assert(location.row < row_max)
			assert(location.col < col_max)
			return row_lut[location.row][location.col]
		else:
			assert(
				false,
				'Grid: location Dictionary needs to have key "grid_index" or "row"  and "col"'
			)
			return -1
	else:
		assert(
			false,
			'Grid: location needs to be Dictionary or int'
		)
		return -1


# change the tile at `location` \
# `changes` can contain these keys: `{tile_key: int, state: int, location:{(grid_index: int) or (row: int, col: int)}, leave_behind: int}` \
# `if changes.tile_key`: `switch_tile()` is used to switch to `changes.tile_key` \
# `if changes.state`: `x.change_scene()` is used to change to `changes.state` \
# `if changes.location`: `move_tile()` is used to move to `changes.location`, also `changes.leave_behind` is passed to `move_tile()`
# `args` are send through to XScene, see XScene for documentation
func change_tile(location, changes: Dictionary, args := {}) -> void:
	var grid_index = location_to_grid_index(location)
	var d = {
		tile_key = false,
		state = false,
		location = false,
		leave_behind = false,
	}
	for k in changes:
		# this structure avoids repeated 'x in dict' calls
		match k:
			'tile_key':
				d.tile_key = true
			'state':
				d.state = true
			'location':
				d.location = true
			'leave_behind':
				d.leave_behind = true
		g[grid_index][k] = changes[k]
	if d.tile_key:
		switch_tile(changes.location, changes.tile_key)
	if d.state:
		args.method_change = changes.state
		x.change_scene(grid_index, args)
	if d.location:
		move_tile(
			changes.location,
			location,
			changes.leave_behind if d.leave_behind else null,
			args
		)


# Switch the tile at `location` to the tile of `tile_key`. \
# The old tile is freed, no properties are kept, except the position. \
# `args` are send through to XScene, see XScene for documentation
func switch_tile(location, tile_key, args := {}) -> void:
	var grid_index = location_to_grid_index(location)
	args.method_remove = x.FREE
	x.x_add_scene(tiles[tile_key], grid_index, grid_index, args)
	x.x(grid_index).position = g[grid_index].position
	g[grid_index].tile_key = tile_key


# Move the tile at `location_from` to `location_to`. \
# `if leave_behind == null`: it performs a swap with the tile at `location_to` \
# `else`: it uses `leave_behind` as a tile key for `switch_tile()` at `location_from` \
# `args` are send through to XScene, see XScene for documentation
func move_tile(
	location_to: Dictionary,
	location_from: Dictionary,
	leave_behind = null,
	args := {}
) -> void:
	var grid_index_to := location_to_grid_index(location_to)
	var grid_index_from := location_to_grid_index(location_from)

	var temp = x.x(grid_index_to).position
	x.x(grid_index_to).position = x.x(grid_index_from).position
	x.x(grid_index_from).position = temp

	x.swap_scene(grid_index_to, grid_index_from)
	if leave_behind != null:
		assert(
			leave_behind in tiles,
			'Grid.move_tile: leave_behind must be null or key in Grid.tiles'
		)
		switch_tile({grid_index = grid_index_from}, leave_behind, args)


# Makes an array of size `grid.size`, that maps `tile_key` from `grid.tiles` to `grid_index`, according to `_pattern`
func make_map_for_pattern(_pattern: Array) -> Array:
	var map := []
	for i in size:
		map.push_back(0)

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
					cols.push_back(c)
			for r in row_max:
				if r % _pattern.size() == i:
					rows.push_back(r)
			for c in cols:
				for r in rows:
					map[col_lut[c][r]] = _pattern[i][j]
	return map


# Makes an array of size `grid.size`, that maps `tile_key` from `grid.tiles` to `grid_index`, randomly distributed according to `_distribution`
func make_map_for_distribution(_distribution) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var MAX_INT := 4294967295

	var map := []
	for i in size:
		map.push_back(0)

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


# get row indices and col indices around `location` depending on `distance` \
# `if distance == -1`: get all rows/cols \
# returns `{rows = {above: Array, below: Array}, cols = {left: Array, right: Array}}` \
# the Arrays are ordered "closest to `location`" first
func get_cols_rows_around(location, distance := -1) -> Dictionary:
	var grid_index := location_to_grid_index(location)
	var rows := []
	for i in row_max:
		rows.append(i)
	var cols := []
	for i in col_max:
		cols.append(i)

	var around := {rows = {}, cols = {}}
	var start
	var end

	start = 0 if distance == -1 else g[grid_index].row - distance
	end = g[grid_index].row
	around.rows.above = _slice(rows, start, end)

	start = g[grid_index].row + 1
	end = row_max if distance == -1 else g[grid_index].row + 1 + distance
	around.rows.below = _slice(rows, start, end)

	start = 0 if distance == -1 else g[grid_index].col - distance
	end = g[grid_index].col
	around.cols.left = _slice(cols, start, end)

	start = g[grid_index].col + 1
	end = col_max if distance == -1 else g[grid_index].col + 1 + distance
	around.cols.right = _slice(cols, start, end)

	around.rows.above.invert()
	around.cols.left.invert()
	return around


# returns an Array containing Arrays containing the `grid_indices` of the tiles in the next 'ring' around location \
# `distance` determines how many rings are returned \
# `if distance == -1`: it returns all rings
func get_rings_around(location, distance := 1) -> Array:
	var grid_index := location_to_grid_index(location)
	var around := get_cols_rows_around(location, distance)
	var rings := []
	var temp: Array
	var array
	var start: int
	var end: int

	assert(
		distance >= 0 or distance == -1,
		'Grid.get_rings_around: distance must be >= 0 or == -1' + distance as String
	)

	var max_distance = max(col_max, row_max)
	var d: int
	if distance > max_distance or distance == -1:
		d = max_distance
	else:
		d = distance

	var distance_in_range: bool
	for i in d:
		temp = []
		distance_in_range = false

		if around.cols.left:
			start = around.cols.left[min(i, around.cols.left.size() - 1)]
		else:
			start = g[grid_index].col
		if around.cols.right:
			end = around.cols.right[min(i, around.cols.right.size() - 1)]
		else:
			end = g[grid_index].col

		if around.rows.above:
			if i < around.rows.above.size():
				distance_in_range = true
				array = row_lut[around.rows.above[i]]
				temp.append_array(_slice(array, start, end + 1))

		if around.rows.below:
			if i < around.rows.below.size():
				distance_in_range = true
				array = row_lut[around.rows.below[i]]
				temp.append_array(_slice(array, start, end + 1))

		if around.rows.above:
			start = around.rows.above[min(i, around.rows.above.size() - 1)]
		else:
			start = g[grid_index].row
		if around.rows.below:
			end = around.rows.below[min(i, around.rows.below.size() - 1)]
		else:
			end = g[grid_index].row

		if around.cols.left:
			if i < around.cols.left.size():
				distance_in_range = true
				array = col_lut[around.cols.left[i]]
				temp.append_array(_slice(array, start, end + 1))

		if around.cols.right:
			if i < around.cols.right.size():
				distance_in_range = true
				array = col_lut[around.cols.right[i]]
				temp.append_array(_slice(array, start, end + 1))

		if distance_in_range:
			rings.push_back(temp)
	return rings


# returns an Array containing the `grid_indices` of the tiles in the same row and column as `location` \
# `if rings`: see `get_rings_around()`, but only with tiles in same row and column \
# distance determines how many rings are returned \
# `if distance == -1`: it returns all rings
func get_orthogonal_neighbors(location, distance := 1, rings:= false) -> Array:
	var grid_index := location_to_grid_index(location)
	var four_neighbors := []
	var offset: int

	var max_distance = max(col_max, row_max)
	var d: int
	if distance > max_distance or distance == -1:
		d = max_distance
	else:
		d = distance

	if rings:
		var ring: Array
		for i in d:
			ring = []
			offset = i + 1
			if not g[grid_index].col - offset < 0:
				ring.push_back(
					row_lut[g[grid_index].row][g[grid_index].col - offset]
				)
			if not g[grid_index].col + offset > col_max - 1:
				ring.push_back(
					row_lut[g[grid_index].row][g[grid_index].col + offset]
				)
			if not g[grid_index].row - offset < 0:
				ring.push_back(
					col_lut[g[grid_index].col][g[grid_index].row - offset]
				)
			if not g[grid_index].row + offset > row_max - 1:
				ring.push_back(
					col_lut[g[grid_index].col][g[grid_index].row + offset]
				)
			if ring:
				four_neighbors.push_back(ring)
	else:
		for i in d:
			offset = i + 1
			if not g[grid_index].col - offset < 0:
				four_neighbors.push_back(
					row_lut[g[grid_index].row][g[grid_index].col - offset]
				)
			if not g[grid_index].col + offset > col_max - 1:
				four_neighbors.push_back(
					row_lut[g[grid_index].row][g[grid_index].col + offset]
				)
			if not g[grid_index].row - offset < 0:
				four_neighbors.push_back(
					col_lut[g[grid_index].col][g[grid_index].row - offset]
				)
			if not g[grid_index].row + offset > row_max - 1:
				four_neighbors.push_back(
					col_lut[g[grid_index].col][g[grid_index].row + offset]
				)

	return four_neighbors


# returns an Array containing the `grid_indices` of the tiles on the same diagonals as location \
# `if rings`: see `get_rings_around()`, but only with tiles on same diagonals \
# `distance` determines how many rings are returned \
# `if distance == -1`: it returns all rings
func get_diagonal_neighbors(location, distance := 1, rings:= false) -> Array:
	var grid_index := location_to_grid_index(location)
	var four_neighbors := []
	var offset: int
	var index: int
	var diag: Array

	var max_distance = max(col_max, row_max)
	var d: int
	if distance > max_distance or distance == -1:
		d = max_distance
	else:
		d = distance

	if rings:
		var ring: Array
		for i in d:
			ring = []
			offset = i + 1
			diag = rising_diag_lut[g[grid_index].rising_diag]
			index = diag.bsearch(grid_index)
			if not index - offset < 0:
				ring.push_back(diag[index - offset])
			if not index + offset > diag.size() - 1:
				ring.push_back(diag[index + offset])

			diag = falling_diag_lut[g[grid_index].falling_diag]
			index = diag.bsearch(grid_index)
			if not index - offset < 0:
				ring.push_back(diag[index - offset])
			if not index + offset > diag.size() - 1:
				ring.push_back(diag[index + offset])
			if ring:
				four_neighbors.push_back(ring)
	else:
		for i in d:
			offset = i + 1
			diag = rising_diag_lut[g[grid_index].rising_diag]
			index = diag.bsearch(grid_index)
			if not index - offset < 0:
				four_neighbors.push_back(diag[index - offset])
			if not index + offset > diag.size() - 1:
				four_neighbors.push_back(diag[index + offset])

			diag = falling_diag_lut[g[grid_index].falling_diag]
			index = diag.bsearch(grid_index)
			if not index - offset < 0:
				four_neighbors.push_back(diag[index - offset])
			if not index + offset > diag.size() - 1:
				four_neighbors.push_back(diag[index + offset])

	return four_neighbors


# combines `get_orthogonal_neighbors()` and `get_diagonal_neighbors()`
func get_all_neighbors(location, distance := 1, rings:= false) -> Array:
	var eight_neighbors := []
	if rings:
		var dia = get_diagonal_neighbors(location, distance, rings)
		var ortho = get_orthogonal_neighbors(location, distance, rings)
		for i in ortho.size():
			if i < dia.size():
				eight_neighbors.append(dia[i] + ortho[i])
			else:
				eight_neighbors.append(ortho[i])
	else:
		eight_neighbors.append_array(get_diagonal_neighbors(location, distance))
		eight_neighbors.append_array(get_orthogonal_neighbors(location, distance))
	return eight_neighbors


# returns a location Dictionary, containing the differences between `start_location` and `end_location` \
# `{grid_index:int, row:int, col:int}`
func get_distance_between(start_location, end_location) -> Dictionary:
	var start_grid_index := location_to_grid_index(start_location)
	var end_grid_index := location_to_grid_index(end_location)
	var distance := {grid_index = 0, row = 0, col = 0}
	distance.grid_index = abs(end_grid_index - start_grid_index)
	distance.row = abs(g[end_grid_index].row - g[start_grid_index].row)
	distance.col = abs(g[end_grid_index].col - g[start_grid_index].col)
	return distance


# returns a 1D Array containing the `grid_indices` of all tiles in the rectangle between `start_location` and `end_location` \
# the order of the inputs does not matter
func get_rect_between(start_location, end_location) -> Array:
	var start_grid_index := location_to_grid_index(start_location)
	var end_grid_index := location_to_grid_index(end_location)
	var start_row = min(g[start_grid_index].row, g[end_grid_index].row)
	var end_row = max(g[start_grid_index].row, g[end_grid_index].row)
	var start_col = min(g[start_grid_index].col, g[end_grid_index].col)
	var end_col = max(g[start_grid_index].col, g[end_grid_index].col)
	var rect := []

	for row_index in range(start_row, end_row + 1):
		rect.append_array(_slice(row_lut[row_index], start_col, end_col + 1))

	return rect


# get Array of tiles with the specified `tile_key`
func get_tiles_by_tile_key(_tile_key) -> Array:
	var ts = []
	for i in size:
		if _tile_key == g[i].tile_key:
			ts.push_back(i)
	return ts


# create a Rect2 encompassing the whole grid \
# it uses coordinates local to the grid
func get_rect() -> Rect2:
	var last_tile = x.x(size - 1)
	var start = transform.origin
	var end = (
		last_tile.get_relative_transform_to_parent(self).origin
		+ Vector2(tile_x, tile_y)
	)
	return Rect2(start, end)


# returns the first Node below parent including parent that is a Sprite
func _find_sprite(parent: Node) -> Node:
	if parent is Sprite:
		return parent
	else:
		var sprite = null
		for c in parent.get_children():
			var temp = _find_sprite(c)
			if temp != null:
				sprite = temp
				break
		return sprite


# returns `{rising_diag: Array, falling_diag: Array}` \
# depending on `enable_diag.rising_diag: bool` and `enable_diag.rising_diag: bool` \
# Arrays contain `grid_index` of all tiles on the same rising/falling diagonal \
# `grid_index` of the given `location` is excluded
func _get_diagonals(location, enable_diag := {}) -> Dictionary:
	var grid_index := location_to_grid_index(location)
	var d := {}
	var around := {
		rows = {
			above = g[grid_index].row, below = row_max - g[grid_index].row - 1
		},
		cols = {
			left = g[grid_index].col, right = col_max - g[grid_index].col - 1
		},
	}

	if not 'rising_diag' in enable_diag:
		enable_diag.rising_diag = true
	if not 'falling_diag' in enable_diag:
		enable_diag.falling_diag = true

	var offset: int
	var temp: int

	if enable_diag.rising_diag:
		d.rising_diag = []
		for i in min(around.rows.above, around.cols.right):
			offset = i + 1
			d.rising_diag.push_back(
				row_lut[g[grid_index].row - offset][g[grid_index].col + offset]
			)
		for i in min(around.rows.below, around.cols.left):
			offset = i + 1
			d.rising_diag.push_back(
				row_lut[g[grid_index].row + offset][g[grid_index].col - offset]
			)

	if enable_diag.falling_diag:
		d.falling_diag = []
		for i in min(around.rows.above, around.cols.left):
			offset = i + 1
			d.falling_diag.push_back(
				row_lut[g[grid_index].row - offset][g[grid_index].col - offset]
			)
		for i in min(around.rows.below, around.cols.right):
			offset = i + 1
			d.falling_diag.push_back(
				row_lut[g[grid_index].row + offset][g[grid_index].col + offset]
			)
	return d


# this slices an array like Array.slize(), but with start incl, end excl. \
# no negative indices supported
func _slice(array: Array, start: int, end: int) -> Array:
	var temp := []
	if array.size() == 0:
		return temp
	start = max(0, start)
	if end < 0 or end > array.size():
		end = array.size()
	for i in range(start, end):
		temp.append(array[i])
	return temp
