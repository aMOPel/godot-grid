# A gdscript library to make working with rectangular grids easier.

extends Node2D

class_name Grid, 'res://addons/grid/grid16.png'

# dimensions of the grid \
# number of cols/rows in the grid
var dimensions: Vector2

# pattern of `tile_key`s that is applied to the grid \
# setting this variable is expensive as it resets the whole grid
var pattern: Array setget _set_pattern

# distribution of `tile_key`s that is applied to the grid \
# can be Array if `tile_key`s are int or dictionary if `tile_key`s are String \
# setting this variable is expensive as it resets the whole grid
var distribution setget _set_distribution

# maps `grid_index` to `tile_key` \
# setting this variable is expensive as it resets the whole grid
var map: Array setget _set_map

# number of tiles in grid
var size: int

# dimensions of an individual tile \
# using normal coordinates, not grid coordinates
var tile_dimensions: Vector2

# groups indices of rows together for easy access, since they are constant \
# Array of Arrays containing `grid_indices`
var row_lut: Array

# groups indices of columns together for easy access, since they are constant \
# Array of Arrays containing `grid_indices`
var col_lut: Array

# groups indices of falling diagonals together for easy access, since they are constant \
# Array of Arrays containing `grid_indices`
var falling_diag_lut: Array

# groups indices of rising diagonals together for easy access, since they are constant \
# Array of Arrays containing `grid_indices`
var rising_diag_lut: Array

# holds information for all tiles in the grid \
# `g` at `grid_index` is `{position: Vector2, tile_key: int/string, grid_position: Vector2, rising_diag: int, falling_diag:int}`
var g: Array setget _dont_set

# keys are `tile_key`, values are Node/PackedScene
var tiles := {}

# defaults for `XScene.defaults`, only set once in `_ready()`
var args: Dictionary setget _dont_set

# instance of `XScene`, managing all tiles of the grid
var x: XScene


func _dont_set(a) -> void:
	assert(false, 'Grid: do not set g property manually')


func _set_pattern(new: Array) -> void:
	pattern = new
	self.map = make_map_for_pattern(pattern)


func _set_distribution(new) -> void:
	distribution = new
	self.map = make_map_for_distribution(distribution)


func _set_map(new: Array) -> void:
	map = new
	for i in size:
		switch_tile({grid_index = i}, map[i])


func _ready():
	x = XScene.new(self, false, args)
	# if tile_dimensions.x and tile_dimensions.y are not given on init, they are inferred from Sprite.get_rect() in tiles[0]
	if tile_dimensions == Vector2.ZERO:
		var t = x.to_node(tiles.values()[0])
		var sprite = _find_sprite(t)
		assert(
			sprite != null,
			'The Grid tile size is unknown. tile_dimensions.x and tile_dimensions.y were not given on init and tiles[0] doesn\'t contain a Sprite'
		)
		var cell_rect = sprite.get_rect()
		t.free()
		tile_dimensions.x = abs(cell_rect.position.x) + abs(cell_rect.end.x)
		tile_dimensions.y = abs(cell_rect.position.y) + abs(cell_rect.end.y)

	# row/col lut
	col_lut = []
	row_lut = []
	g = []
	for i in dimensions.y:
		row_lut.push_back([])
	for i in dimensions.x:
		col_lut.push_back([])

	var y_coord = 0
	for i in dimensions.y:
		var x_coord = 0
		for j in dimensions.x:
			row_lut[i].push_back(g.size())
			col_lut[j].push_back(g.size())
			g.push_back(
				{
					position = Vector2(x_coord, y_coord),
					grid_position = Vector2(j, i)
				}
			)
			x_coord += tile_dimensions.x
		y_coord += tile_dimensions.y

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


# instance a grid with `_dimensions.x` columns and `_dimensions.y` rows. By default all tiles are visible and are set to the first tile in `_tiles` \
# Specify `_pattern` of tiles. A matrix of `tile_key`s that is repeated through the whole grid. \
# Specify relative probability `_distribution` of tiles by which they get randomly distributed through the grid. Can be Array or Dictionary. \
# You can only specify either `_pattern` or `_distribution` \
# `if _tile_dimensions == Vector2.ZERO`: The size of the icon is inferred from first tile in `_tiles` \
# `else`: It's up to you to assure that `_tile_dimensions.x` and `_tile_dimensions.y` are correct \
# `args` are send through to `XScene.new()` at `Grid._ready()`, see XScene for documentation
func _init(_dimensions: Vector2, _tiles, _pattern := [], _distribution = {}, _tile_dimensions := Vector2.ZERO, _args := {}):
	dimensions = _dimensions

	size = _dimensions.x * _dimensions.y

	tiles = Dictionary(_tiles)

	assert(
		not (_pattern and _distribution),
		'you can only define either pattern or distribution'
	)
	pattern = _pattern
	distribution = _distribution

	tile_dimensions = _tile_dimensions

	args = _args
	args.count_start = 0


# `partial_location` can be `grid_index: int` or `grid_position: Vector2` or `{grid_index: int}` or `{grid_position: Vector2}` or `{grid_index: int, grid_position: Vector2}` \
# `grid_index` takes precedence over `grid_position` \
# it returns the corresponding `location` `{grid_index: int, grid_position: Vector2}`
func to_location(partial_location) -> Dictionary:
	var location = {grid_index = 0, grid_position = Vector2.ZERO}
	if partial_location is int:
		assert(partial_location < size)
		location.grid_index = partial_location
		location.grid_position = g[partial_location].grid_position
	elif partial_location is Vector2:
		assert(
			(
				partial_location.x < dimensions.x
				and partial_location.y < dimensions.y
			)
		)
		location.grid_index = col_lut[partial_location.x][partial_location.y]
		location.grid_position = partial_location
	elif partial_location is Dictionary:
		if 'grid_index' in partial_location:
			assert(partial_location.grid_index is int)
			assert(partial_location.grid_index < size)
			location.grid_index = partial_location.grid_index
			location.grid_position = g[partial_location.grid_index].grid_position
		elif 'grid_position' in partial_location:
			assert(partial_location.grid_position is Vector2)
			assert(
				(
					partial_location.grid_position.x < dimensions.x
					and partial_location.grid_position.y < dimensions.y
				)
			)
			location.grid_index = col_lut[partial_location.grid_position.x][partial_location.grid_position.y]
			location.grid_position = g[partial_location.grid_index].grid_position
		else:
			assert(
				false,
				'Grid: partial_location Dictionary needs to have key "grid_index" or "grid_position"'
			)
	else:
		assert(
			false,
			'Grid: location needs to be grid_index: int or grid_position: Vector2 or partial_location: {grid_index:int} or {grid_position:Vector2}'
		)
	return location


# change the tile at `partial_location` \
# `changes` can contain these keys: `{tile_key: int, state: int, partial_location: see to_location(), leave_behind: int}` \
# `if changes.tile_key`: `switch_tile()` is used to switch to `changes.tile_key` \
# `if changes.state`: `x.change_scene()` is used to change to `changes.state` \
# `if changes.partial_location`: `move_tile()` is used to move to `changes.partial_location`, also `changes.leave_behind` is passed to `move_tile()` \
# `args` are send through to XScene, see XScene for documentation
func change_tile(partial_location, changes: Dictionary, args := {}) -> void:
	var location = to_location(partial_location)
	var d = {
		tile_key = false,
		state = false,
		partial_location = false,
		leave_behind = false,
	}
	for k in changes:
		# this structure avoids repeated 'x in dict' calls
		match k:
			'tile_key':
				d.tile_key = true
			'state':
				d.state = true
			'partial_location':
				d.partial_location = true
			'leave_behind':
				d.leave_behind = true
		g[location.grid_index][k] = changes[k]
	if d.tile_key:
		switch_tile(partial_location, changes.tile_key)
	if d.state:
		args.method_change = changes.state
		x.change_scene(location.grid_index, args)
	if d.partial_location:
		move_tile(
			changes.partial_location,
			partial_location,
			changes.leave_behind if d.leave_behind else null,
			args
		)


# Switch the tile at `partial_location` to the tile of `tile_key`. \
# The old tile is freed, no properties are kept, except the position. \
# `args` are send through to XScene, see XScene for documentation
func switch_tile(partial_location, tile_key, args := {}) -> void:
	var location = to_location(partial_location)
	args.method_remove = x.FREE
	x.x_add_scene(
		tiles[tile_key], location.grid_index, location.grid_index, args
	)
	x.x(location.grid_index).position = g[location.grid_index].position
	g[location.grid_index].tile_key = tile_key


# Move the tile at `partial_location_from` to `partial_location_to`. \
# `if leave_behind == null`: it performs a swap with the tile at `partial_location_to` \
# `else`: it uses `leave_behind` as a `tile_key` for `switch_tile()` at `partial_location_from` \
# `args` are send through to XScene, see XScene for documentation
func move_tile(partial_location_to, partial_location_from, leave_behind = null, args := {}) -> void:
	var location_to := to_location(partial_location_to)
	var location_from := to_location(partial_location_from)

	var temp = x.x(location_to.grid_index).position
	x.x(location_to.grid_index).position = x.x(
		location_from.grid_index
	).position
	x.x(location_from.grid_index).position = temp

	x.swap_scene(location_to.grid_index, location_from.grid_index)
	if leave_behind != null:
		assert(
			leave_behind in tiles,
			'Grid.move_tile: leave_behind must be null or key in Grid.tiles'
		)
		switch_tile(partial_location_from, leave_behind, args)


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
			for c in dimensions.x:
				if c % row.size() == j:
					cols.push_back(c)
			for r in dimensions.y:
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


# get row indices and col indices around `partial_location` depending on `distance` \
# `if distance == -1`: get all rows/cols \
# returns `{rows = {above: Array, below: Array}, cols = {left: Array, right: Array}}` \
# the Arrays are ordered "closest to `location`" first
func get_cols_rows_around(partial_location, distance := -1) -> Dictionary:
	var location := to_location(partial_location)
	var rows := []
	for i in dimensions.y:
		rows.append(i)
	var cols := []
	for i in dimensions.x:
		cols.append(i)

	var around := {rows = {}, cols = {}}
	var start
	var end

	start = 0 if distance == -1 else location.grid_position.y - distance
	end = location.grid_position.y
	around.rows.above = _slice(rows, start, end)

	start = location.grid_position.y + 1
	end = (
		dimensions.y
		if distance == -1
		else location.grid_position.y + 1 + distance
	)
	around.rows.below = _slice(rows, start, end)

	start = 0 if distance == -1 else location.grid_position.x - distance
	end = location.grid_position.x
	around.cols.left = _slice(cols, start, end)

	start = location.grid_position.x + 1
	end = (
		dimensions.x
		if distance == -1
		else location.grid_position.x + 1 + distance
	)
	around.cols.right = _slice(cols, start, end)

	around.rows.above.invert()
	around.cols.left.invert()
	return around


# returns an Array of Arrays containing the `grid_indices` of the tiles in the next 'ring' around `partial_location` \
# `distance` determines how many rings are returned \
# `if distance == -1`: it returns all rings
func get_rings_around(partial_location, distance := 1) -> Array:
	var location := to_location(partial_location)
	var around := get_cols_rows_around(partial_location, distance)
	var rings := []
	var temp: Array
	var array
	var start: int
	var end: int

	assert(
		distance >= 0 or distance == -1,
		(
			'Grid.get_rings_around: distance must be >= 0 or == -1'
			+ distance as String
		)
	)

	var max_distance = max(dimensions.x, dimensions.y)
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
			start = location.grid_position.x
		if around.cols.right:
			end = around.cols.right[min(i, around.cols.right.size() - 1)]
		else:
			end = location.grid_position.x

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
			start = location.grid_position.y
		if around.rows.below:
			end = around.rows.below[min(i, around.rows.below.size() - 1)]
		else:
			end = location.grid_position.y

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


# returns an Array containing the `grid_indices` of the tiles in the same row and column as `partial_location` \
# `if rings`: see `get_rings_around()`, but only with tiles in same row and column \
# `distance` determines how many rings are returned \
# `if distance == -1`: it returns all rings
func get_orthogonal_neighbors(partial_location, distance := 1, rings := false) -> Array:
	var location := to_location(partial_location)
	var four_neighbors := []
	var offset: int

	var max_distance = max(dimensions.x, dimensions.y)
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
			if not location.grid_position.x - offset < 0:
				ring.push_back(
					row_lut[location.grid_position.y][(
						location.grid_position.x
						- offset
					)]
				)
			if not location.grid_position.x + offset > dimensions.x - 1:
				ring.push_back(
					row_lut[location.grid_position.y][(
						location.grid_position.x
						+ offset
					)]
				)
			if not location.grid_position.y - offset < 0:
				ring.push_back(
					col_lut[location.grid_position.x][(
						location.grid_position.y
						- offset
					)]
				)
			if not location.grid_position.y + offset > dimensions.y - 1:
				ring.push_back(
					col_lut[location.grid_position.x][(
						location.grid_position.y
						+ offset
					)]
				)
			if ring:
				four_neighbors.push_back(ring)
	else:
		for i in d:
			offset = i + 1
			if not location.grid_position.x - offset < 0:
				four_neighbors.push_back(
					row_lut[location.grid_position.y][(
						location.grid_position.x
						- offset
					)]
				)
			if not location.grid_position.x + offset > dimensions.x - 1:
				four_neighbors.push_back(
					row_lut[location.grid_position.y][(
						location.grid_position.x
						+ offset
					)]
				)
			if not location.grid_position.y - offset < 0:
				four_neighbors.push_back(
					col_lut[location.grid_position.x][(
						location.grid_position.y
						- offset
					)]
				)
			if not location.grid_position.y + offset > dimensions.y - 1:
				four_neighbors.push_back(
					col_lut[location.grid_position.x][(
						location.grid_position.y
						+ offset
					)]
				)

	return four_neighbors


# returns an Array containing the `grid_indices` of the tiles on the same diagonals as `partial_location` \
# `if rings`: see `get_rings_around()`, but only with tiles on same diagonals \
# `distance` determines how many rings are returned \
# `if distance == -1`: it returns all rings
func get_diagonal_neighbors(partial_location, distance := 1, rings := false) -> Array:
	var location := to_location(partial_location)
	var four_neighbors := []
	var offset: int
	var index: int
	var diag: Array

	var max_distance = max(dimensions.x, dimensions.y)
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
			diag = rising_diag_lut[g[location.grid_index].rising_diag]
			index = diag.bsearch(location.grid_index)
			if not index - offset < 0:
				ring.push_back(diag[index - offset])
			if not index + offset > diag.size() - 1:
				ring.push_back(diag[index + offset])

			diag = falling_diag_lut[g[location.grid_index].falling_diag]
			index = diag.bsearch(location.grid_index)
			if not index - offset < 0:
				ring.push_back(diag[index - offset])
			if not index + offset > diag.size() - 1:
				ring.push_back(diag[index + offset])
			if ring:
				four_neighbors.push_back(ring)
	else:
		for i in d:
			offset = i + 1
			diag = rising_diag_lut[g[location.grid_index].rising_diag]
			index = diag.bsearch(location.grid_index)
			if not index - offset < 0:
				four_neighbors.push_back(diag[index - offset])
			if not index + offset > diag.size() - 1:
				four_neighbors.push_back(diag[index + offset])

			diag = falling_diag_lut[g[location.grid_index].falling_diag]
			index = diag.bsearch(location.grid_index)
			if not index - offset < 0:
				four_neighbors.push_back(diag[index - offset])
			if not index + offset > diag.size() - 1:
				four_neighbors.push_back(diag[index + offset])

	return four_neighbors


# combines `get_orthogonal_neighbors()` and `get_diagonal_neighbors()`
func get_all_neighbors(partial_location, distance := 1, rings := false) -> Array:
	var eight_neighbors := []
	if rings:
		var dia = get_diagonal_neighbors(partial_location, distance, rings)
		var ortho = get_orthogonal_neighbors(partial_location, distance, rings)
		for i in ortho.size():
			if i < dia.size():
				eight_neighbors.append(dia[i] + ortho[i])
			else:
				eight_neighbors.append(ortho[i])
	else:
		eight_neighbors.append_array(
			get_diagonal_neighbors(partial_location, distance)
		)
		eight_neighbors.append_array(
			get_orthogonal_neighbors(partial_location, distance)
		)
	return eight_neighbors


# returns a location Dictionary, see `to_location()`, \
# containing the differences between `partial_location_to` and `partial_location_from` \
func get_distance_between(partial_location_to, partial_location_from) -> Dictionary:
	var location_from := to_location(partial_location_from)
	var location_to := to_location(partial_location_to)
	var distance := {grid_index = 0, grid_position = Vector2.ZERO}
	distance.grid_index = abs(location_to.grid_index - location_from.grid_index)
	distance.grid_position.x = abs(
		location_to.grid_position.x - location_from.grid_position.x
	)
	distance.grid_position.y = abs(
		location_to.grid_position.y - location_from.grid_position.y
	)
	return distance


# returns an Array containing the `grid_indices` of all tiles in the rectangle between and including `partial_location_to` and `partial_location_from` \
# the order of the inputs does not matter
func get_rect_between(partial_location_to, partial_location_from) -> Array:
	var location_from := to_location(partial_location_from)
	var location_to := to_location(partial_location_to)

	var start_col = min(
		location_from.grid_position.x, location_to.grid_position.x
	)
	var end_col = max(
		location_from.grid_position.x, location_to.grid_position.x
	)
	var start_row = min(
		location_from.grid_position.y, location_to.grid_position.y
	)
	var end_row = max(
		location_from.grid_position.y, location_to.grid_position.y
	)

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


# create a `Rect2` encompassing the whole grid \
# it uses coordinates local to the grid
func get_rect() -> Rect2:
	var last_tile = x.x(size - 1)
	var start = transform.origin
	var end = (
		last_tile.get_relative_transform_to_parent(self).origin
		+ Vector2(tile_dimensions.x, tile_dimensions.y)
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
func _get_diagonals(partial_location, enable_diag := {}) -> Dictionary:
	var location := to_location(partial_location)
	var d := {}
	var around := {
		cols = {
			left = location.grid_position.x,
			right = dimensions.x - location.grid_position.x - 1
		},
		rows = {
			above = location.grid_position.y,
			below = dimensions.y - location.grid_position.y - 1
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
				row_lut[location.grid_position.y - offset][(
					location.grid_position.x
					+ offset
				)]
			)
		for i in min(around.rows.below, around.cols.left):
			offset = i + 1
			d.rising_diag.push_back(
				row_lut[location.grid_position.y + offset][(
					location.grid_position.x
					- offset
				)]
			)

	if enable_diag.falling_diag:
		d.falling_diag = []
		for i in min(around.rows.above, around.cols.left):
			offset = i + 1
			d.falling_diag.push_back(
				row_lut[location.grid_position.y - offset][(
					location.grid_position.x
					- offset
				)]
			)
		for i in min(around.rows.below, around.cols.right):
			offset = i + 1
			d.falling_diag.push_back(
				row_lut[location.grid_position.y + offset][(
					location.grid_position.x
					+ offset
				)]
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
