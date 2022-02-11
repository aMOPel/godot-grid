# Tutorial

<!-- TODO: manipulate grid chapter -->

## Generate the Grid
### Plain
```gdscript

# godot icon
onready var tile1 = preload("res://example/Tile1.tscn")
# godot icon flipped and modulated pink
onready var tile2 = preload("res://example/Tile2.tscn")
# godot icon modulated brown
onready var tile3 = preload("res://example/Tile3.tscn")

var grid: Grid

func _ready():
  # can be Node/PackedScene
	var tiles = {'one': tile1.instance(), 'two': tile2, 'three': tile3}

  # implicitly only uses 'one'
	grid = Grid.new(10, 10, tiles)
	add_child(grid)
```
[](./pics/10x10_plain_grid.png)

### With Pattern
```gdscript
	var pattern = [
		['one', 'two', 'one'],
		['two', 'three', 'two'],
		['one', 'two', 'one'],
	]
  grid = Grid.new(10, 10, tiles, pattern)
```
[](./pics/10x10_pattern_grid.png)

### With Random Distribution
```gdscript
	var distribution = {'one': 0.5, 'two':5, 'three':2}
	var grid = Grid.new(10, 10, tiles, [], distribution)
```
[](./pics/10x10_distribution_grid.png)

## Access
### Individually
```gdscript
  # grid_index
	var first = 0
	var middle = 49
	var last = 99

  # grid.g holds all tiles and their information
	print(grid.g[first])
	print(grid.g[middle])
	print(grid.g[last])

  # prints
  {col:0, falling_diag:9, position:(0, 0), rising_diag:0, row:0, tile_key:one}
  {col:9, falling_diag:14, position:(576, 256), rising_diag:13, row:4, tile_key:one}
  {col:9, falling_diag:9, position:(576, 576), rising_diag:18, row:9, tile_key:one}

  # grid.x is an instance of XScene
  # grid.x.x(grid_index) returns the node of the tile
	grid.x.x(first).modulate = Color.green
	grid.x.x(middle).modulate = Color.green
	grid.x.x(last).modulate = Color.green
```
[](./pics/access_individual.png)

### By Col/Row
```gdscript
  # lut == look up table
  # luts are generated once at Grid._ready(), since all indices are constant
  # thus accessing them is very cheap
	var col = grid.g[middle].col
	for i in grid.col_lut[col]:
		grid.x.x(i).modulate = Color.green

	var row = grid.g[middle].row
	for i in grid.row_lut[row]:
		grid.x.x(i).modulate = Color.green
```
[](./pics/access_col_row.png)

### By Diagonals
```gdscript
	var middle = 47
	var rising = grid.g[middle].rising_diag
	for i in grid.rising_diag_lut[rising]:
		grid.x.x(i).modulate = Color.green

	var falling = grid.g[middle].falling_diag
	for i in grid.falling_diag_lut[falling]:
		grid.x.x(i).modulate = Color.green
```
[](./pics/access_diag.png)

### By `tile_key`
```gdscript
  # remember the pattern from earlier
	grid = Grid.new(10, 10, tiles, pattern)
	add_child(grid)

	var one_tiles = grid.get_tiles_by_tile_key('one')
	for i in one_tiles:
		grid.x.x(i).modulate = Color.green
```
[](./pics/access_by_tile_key.png)

## Access relative to one Tile
### Location
`location` can be `grid_index: int` or `{grid_index: int}` or `{row: int, col: int}` \
```gdscript
	var location = {row = 5, col = 2}
	var grid_index = grid.location_to_grid_index(location)
	grid.x.x(grid_index).modulate = Color.red
```
[](./pics/relative_location.png)

### Neighbors
```gdscript
	var distance = 4
	var ortho = grid.get_orthogonal_neighbors(location, distance)
	var diag = grid.get_diagonal_neighbors(location, distance)
	for i in ortho:
		grid.x.x(i).modulate = Color.green
	for i in diag:
		grid.x.x(i).modulate = Color.yellow
```
[](./pics/relative_ortho_diag.png)

```gdscript
	var all = grid.get_all_neighbors(location, distance)
	for i in all:
		grid.x.x(i).modulate = Color.green
```
[](./pics/relative_all.png)

### Cols/Rows
```gdscript
	var around = grid.get_cols_rows_around(location, distance)
	# returns `{rows = {above: Array, below: Array}, cols = {left: Array, right: Array}}` \

	for row_index in around.rows.above:
		for i in grid.row_lut[row_index]:
			grid.x.x(i).modulate += Color.blue
	for col_index in around.cols.right:
		for i in grid.col_lut[col_index]:
			grid.x.x(i).modulate += Color.yellow
```
[](./pics/relative_cols_rows.png)

### Rings
```gdscript
	var color = Color.white
	var rings = grid.get_rings_around(location, distance)
	for ring in rings:
		color += Color(0.1, 0.1, 0.1)
		for i in ring:
			grid.x.x(i).modulate = color
```
[](./pics/relative_rings.png)

```gdscript
  # the neighbor functions can also return in rings, instead of 1D array
	var enable_rings = true
	var rings = grid.get_all_neighbors(location, distance, enable_rings)
	for ring in rings:
		color += Color(0.1, 0.1, 0.1)
		for i in ring:
			grid.x.x(i).modulate = color
```
[](./pics/relative_neighbor_rings.png)

## Utilities
```gdscript
	var start_location = {row = 4, col = 3}
	var start_grid_index = grid.location_to_grid_index(start_location)
	grid.x.x(start_grid_index).modulate = Color.red

	var end_location = {row = 8, col = 5}
	var end_grid_index = grid.location_to_grid_index(end_location)
	grid.x.x(end_grid_index).modulate = Color.red

	var distance = grid.get_distance_between(start_location, end_location)
	print(distance)
	# prints
  {col:1, grid_index:49, row:5}

	print(
		grid.location_to_grid_index(start_location) + distance.grid_index
		==
		grid.location_to_grid_index(end_location)
	)
	# prints
  True
```
[](./pics/utility_distance.png)

```gdscript
	var rect = grid.get_rect_between(start_location, end_location)

	for i in rect:
		grid.x.x(i).modulate = Color.green
```
[](./pics/utility_rect.png)

```gdscript
	grid.rotate(PI/8)

	var rect = grid.get_rect()
	var lower_right_corner = grid.to_global(rect.end)
	# put a tile at the lower right corner
  var t = tile1.instance()
	add_child(t)
	t.position = lower_right_corner
```
[](./pics/utility_rect2.png)


