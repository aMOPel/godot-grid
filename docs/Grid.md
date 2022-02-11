<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# Grid

**Extends:** [Node2D](../Node2D)

## Description

## Property Descriptions

### row\_max

```gdscript
var row_max: int
```

number of rows in the grid

### col\_max

```gdscript
var col_max: int
```

number of columns in the grid

### pattern

```gdscript
var pattern: Array
```

- **Setter**: `set_pattern`

pattern of `tile_key`s that is applied to the grid \
setting this variable is expensive as it resets the whole grid

### distribution

```gdscript
var distribution
```

- **Setter**: `set_distribution`

distribution of `tile_key`s that is applied to the grid \
can be Array if `tile_key`s are int or dictionary if `tile_key`s are String \
setting this variable is expensive as it resets the whole grid

### map

```gdscript
var map: Array
```

- **Setter**: `set_map`

maps `grid_index` to `tile_key` \
setting this variable is expensive as it resets the whole grid

### size

```gdscript
var size: int
```

number of tiles in grid

### tile\_x

```gdscript
var tile_x: float
```

side length of an individual tile

### tile\_y

```gdscript
var tile_y: float
```

### row\_lut

```gdscript
var row_lut: Array
```

groups indices of rows and of columns together for easy access, since they are constant

### col\_lut

```gdscript
var col_lut: Array
```

### falling\_diag\_lut

```gdscript
var falling_diag_lut: Array
```

groups indices of rising and falling diagonals together for easy access, since they are constant

### rising\_diag\_lut

```gdscript
var rising_diag_lut: Array
```

### g

```gdscript
var g: Array
```

holds information for all tiles in the grid \
`g` at `grid_index` is `{position: Vector2, tile_key: int/string, row: int, col: int}`

### tiles

```gdscript
var tiles: Dictionary
```

keys are `tile_key`, values are Node/PackedScene

### args

```gdscript
var args: Dictionary
```

defaults for `XScene.defaults`, only set once in `_ready()`

### x

```gdscript
var x: XScene
```

instance of `XScene`

## Method Descriptions

### set\_pattern

```gdscript
func set_pattern(new: Array) -> void
```

### set\_distribution

```gdscript
func set_distribution(new) -> void
```

### set\_map

```gdscript
func set_map(new: Array) -> void
```

### \_init

```gdscript
func _init(_col_max: int, _row_max: int, _tiles, _pattern: Array, _distribution, _tile_x: int = -1, _tile_y: int = -1, _args: Dictionary)
```

### location\_to\_grid\_index

```gdscript
func location_to_grid_index(location) -> int
```

`location` can be `grid_index: int` or `{grid_index: int}` or `{row: int, col: int}` \
`grid_index` takes precedence over row/col \
it returns the corresponding `grid_index` as int

### change\_tile

```gdscript
func change_tile(location, changes: Dictionary, args: Dictionary) -> void
```

change the tile at `location` \
`changes` can contain these keys: `{tile_key: int, state: int, location:{(grid_index: int) or (row: int, col: int)}, leave_behind: int}` \
`if changes.tile_key`: `switch_tile()` is used to switch to `changes.tile_key` \
`if changes.state`: `x.change_scene()` is used to change to `changes.state` \
`if changes.location`: `move_tile()` is used to move to `changes.location`, also `changes.leave_behind` is passed to `move_tile()`
`args` are send through to XScene, see XScene for documentation

### switch\_tile

```gdscript
func switch_tile(location, tile_key, args: Dictionary) -> void
```

Switch the tile at `location` to the tile of `tile_key`. \
The old tile is freed, no properties are kept, except the position. \
`args` are send through to XScene, see XScene for documentation

### move\_tile

```gdscript
func move_tile(location_to: Dictionary, location_from: Dictionary, leave_behind = null, args: Dictionary) -> void
```

### make\_map\_for\_pattern

```gdscript
func make_map_for_pattern(_pattern: Array) -> Array
```

Makes an array of size `grid.size`, that maps `tile_key` from `grid.tiles` to `grid_index`, according to `_pattern`

### make\_map\_for\_distribution

```gdscript
func make_map_for_distribution(_distribution) -> Array
```

Makes an array of size `grid.size`, that maps `tile_key` from `grid.tiles` to `grid_index`, randomly distributed according to `_distribution`

### get\_cols\_rows\_around

```gdscript
func get_cols_rows_around(location, distance: int = -1) -> Dictionary
```

get row indices and col indices around `location` depending on `distance` \
`if distance == -1`: get all rows/cols \
returns `{rows = {above: Array, below: Array}, cols = {left: Array, right: Array}}` \
the Arrays are ordered "closest to `location`" first

### get\_rings\_around

```gdscript
func get_rings_around(location, distance: int = 1) -> Array
```

returns an Array containing Arrays containing the `grid_indices` of the tiles in the next 'ring' around location \
`distance` determines how many rings are returned \
`if distance == -1`: it returns all rings

### get\_orthogonal\_neighbors

```gdscript
func get_orthogonal_neighbors(location, distance: int = 1, rings: bool = false) -> Array
```

returns an Array containing the `grid_indices` of the tiles in the same row and column as `location` \
`if rings`: see `get_rings_around()`, but only with tiles in same row and column \
distance determines how many rings are returned \
`if distance == -1`: it returns all rings

### get\_diagonal\_neighbors

```gdscript
func get_diagonal_neighbors(location, distance: int = 1, rings: bool = false) -> Array
```

returns an Array containing the `grid_indices` of the tiles on the same diagonals as location \
`if rings`: see `get_rings_around()`, but only with tiles on same diagonals \
`distance` determines how many rings are returned \
`if distance == -1`: it returns all rings

### get\_all\_neighbors

```gdscript
func get_all_neighbors(location, distance: int = 1, rings: bool = false) -> Array
```

combines `get_orthogonal_neighbors()` and `get_diagonal_neighbors()`

### get\_distance\_between

```gdscript
func get_distance_between(start_location, end_location) -> Dictionary
```

returns a location Dictionary, containing the differences between `start_location` and `end_location` \
`{grid_index:int, row:int, col:int}`

### get\_rect\_between

```gdscript
func get_rect_between(start_location, end_location) -> Array
```

returns a 1D Array containing the `grid_indices` of all tiles in the rectangle between `start_location` and `end_location` \
the order of the inputs does not matter

### get\_tiles\_by\_tile\_key

```gdscript
func get_tiles_by_tile_key(_tile_key) -> Array
```

get Array of tiles with the specified `tile_key`

### get\_rect

```gdscript
func get_rect() -> Rect2
```

create a Rect2 encompassing the whole grid \
it uses coordinates local to the grid